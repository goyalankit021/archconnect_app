import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/services/logger_service.dart'; // ✅ Added Logger

// --- PROVIDERS ---

final walletStreamProvider = StreamProvider.autoDispose<Map<String, dynamic>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.read(walletRepositoryProvider).getWalletStream(uid);
});

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

final payoutHistoryProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.read(walletRepositoryProvider).getPayoutHistory(uid);
});

// ✅ FIX: Inject Logger into Repository
final walletRepositoryProvider = Provider((ref) {
  final logger = ref.read(loggerServiceProvider);
  return WalletRepository(logger);
});

// Fetch ArchConnect's Platform Bank Details
final platformBankDetailsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final doc = await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'arch-connect-database')
      .collection('platform_settings')
      .doc('payment_config')
      .get();
  return doc.data() ?? {};
});

class WalletRepository {
  final LoggerService _logger; // ✅ Internal logger reference

  // Use the Named Database
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database'
  );

  WalletRepository(this._logger);

  // --- STREAMS ---
  Stream<Map<String, dynamic>> getWalletStream(String uid) {
    return _db.collection('wallets').doc(uid).snapshots().map((doc) {
      if (!doc.exists) {
        return {'balance': 0.00, 'totalEarned': 0.00, 'pendingBalance': 0.00};
      }
      return doc.data()!;
    });
  }

  Stream<List<Map<String, dynamic>>> getArchitectLedgers(String uid) {
    return _db
        .collection('ledgers')
        .where('architectUid', isEqualTo: uid)
        .orderBy('totalCommission', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getShopHistory(String archUid, String shopId) {
    return _db
        .collection('transactions')
        .where('architectId', isEqualTo: archUid)
        .where('shopId', isEqualTo: shopId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getPayoutHistory(String uid) {
    return _db
        .collection('payouts')
        .where('uid', isEqualTo: uid)
        .orderBy('requestedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // --- 💰 REQUEST PAYOUT (Atomic Transaction) ---
  Future<void> requestPayout({
    required String uid,
    required double amount,
    required String bankDetails,
  }) async {
    // ✅ SECURITY FIX: Prevent negative or zero amount withdrawals
    if (amount <= 0) {
      throw Exception("Withdrawal amount must be greater than zero.");
    }

    final walletRef = _db.collection('wallets').doc(uid);
    final payoutRef = _db.collection('payouts').doc();

    try {
      await _db.runTransaction((transaction) async {
        // 1. READ
        final walletDoc = await transaction.get(walletRef);
        if (!walletDoc.exists) throw Exception("Wallet not found");

        final double currentBalance = (walletDoc.data()?['balance'] ?? 0).toDouble();
        final double currentFrozen = (walletDoc.data()?['frozenBalance'] ?? 0).toDouble();

        // 2. VALIDATE
        if (currentBalance < amount) {
          throw Exception("Insufficient funds. Available: ₹$currentBalance");
        }

        // 3. WRITE: Update Wallet
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
          'status': 'requested',
          'requestedAt': FieldValue.serverTimestamp(),
          'paymentMethod': {
            'type': 'bank_transfer',
            'details': bankDetails,
          },
          'notes': 'User requested withdrawal via App',
        });
      });

      // ✅ LOG IT: High value financial transaction
      _logger.logAudit(
          entityType: 'payout',
          entityId: payoutRef.id,
          action: 'request_withdrawal',
          description: 'User requested ₹$amount withdrawal to $bankDetails',
          severity: 'critical',
          category: 'financial'
      );

    } catch (e, s) {
      _logger.logError(e, s, reason: "Payout Transaction Failed for UID: $uid");
      rethrow; // Pass error back to UI
    }
  }
}