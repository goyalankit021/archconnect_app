import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- PROVIDERS ---

// 1. Stream the Main Wallet (Balance, Total Earned)
final walletStreamProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.read(walletRepositoryProvider).getWalletStream(uid);
});

// 2. Stream the Ledgers (Shop-wise Performance)
final ledgersStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.read(walletRepositoryProvider).getArchitectLedgers(uid);
});

final shopHistoryProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, shopId) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.read(walletRepositoryProvider).getShopHistory(uid, shopId);
});

// --- NEW PROVIDER ---
final payoutHistoryProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.read(walletRepositoryProvider).getPayoutHistory(uid);
});

// 3. The Repo Provider
final walletRepositoryProvider = Provider((ref) => WalletRepository());

class WalletRepository {
  // Use the Named Database
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database'
  );

  // Stream Wallet Document
  Stream<Map<String, dynamic>> getWalletStream(String uid) {
    return _db.collection('wallets').doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        // Return default structure if wallet doesn't exist yet
        return {
          'balance': 0.00,
          'totalEarned': 0.00,
          'pendingBalance': 0.00,
        };
      }
      return doc.data()!;
    });
  }

  // Stream Ledgers (Where Architect is ME)
  Stream<List<Map<String, dynamic>>> getArchitectLedgers(String uid) {
    return _db
        .collection('ledgers')
        .where('architectUid', isEqualTo: uid)
        .orderBy('totalCommission', descending: true) // Show biggest earners first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getShopHistory(String archUid, String shopId) {
    return _db
        .collection('transactions')
        .where('architectId', isEqualTo: archUid) // ✅ Using your new field
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true) // Newest first
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // ... existing code ...

  // 💰 REQUEST PAYOUT (Atomic Transaction)
  Future<void> requestPayout({
    required String uid,
    required double amount,
    required String bankDetails, // Just a display string for the audit log
  }) async {
    final walletRef = _db.collection('wallets').doc(uid);
    final payoutRef = _db.collection('payouts').doc(); // Auto-ID

    return _db.runTransaction((transaction) async {
      // 1. READ (Must happen first in a transaction)
      final walletDoc = await transaction.get(walletRef);
      if (!walletDoc.exists) throw Exception("Wallet not found");

      final double currentBalance = (walletDoc.data()?['balance'] ?? 0).toDouble();
      final double currentFrozen = (walletDoc.data()?['frozenBalance'] ?? 0).toDouble();

      // 2. VALIDATE
      if (currentBalance < amount) {
        throw Exception("Insufficient funds. Available: ₹$currentBalance");
      }

      // 3. WRITE: Update Wallet (Move money to Frozen)
      transaction.update(walletRef, {
        'balance': currentBalance - amount,
        'frozenBalance': currentFrozen + amount,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      // 4. WRITE: Create Payout Request
      transaction.set(payoutRef, {
        'payoutId': payoutRef.id,
        'uid': uid,
        'amount': amount,
        'currency': 'INR',
        'status': 'requested', // Initial status
        'requestedAt': FieldValue.serverTimestamp(),
        'paymentMethod': {
          'type': 'bank_transfer',
          'details': bankDetails, // e.g., "HDFC - XXXX1234"
        },
        'notes': 'User requested withdrawal via App',
      });
    });
  }
  
  // Stream Payout History
  Stream<List<Map<String, dynamic>>> getPayoutHistory(String uid) {
    return _db
        .collection('payouts')
        .where('uid', isEqualTo: uid)
        .orderBy('requestedAt', descending: true) // Newest first
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}