import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database'
  );

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> confirmReferral({
    required String referralId,
    required String architectUid,
    required String architectName,
    required String shopName,
    required double billAmount,
    required double commissionAmount,
    required double commissionPercent,
    required String projectName,
    required String projectType,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final String shopUid = user.uid;
    final WriteBatch batch = _db.batch();
    final Timestamp now = Timestamp.now();

    // --- 1. REFERRAL (Update Only) ---
    // We only update fields that change. Existing keys remain.
    final DocumentReference refDoc = _db.collection('referrals').doc(referralId);
    batch.update(refDoc, {
      'status': 'confirmed',
      'billAmount': billAmount,
      'commissionAmount': commissionAmount,
      'confirmedAt': now,
      'confirmedByUid': shopUid,
      'statusHistory': FieldValue.arrayUnion([
        {'status': 'confirmed', 'timestamp': now, 'byUid': shopUid}
      ])
    });

    // --- 2. TRANSACTION (Create Full Schema) ---
    // FIX: Added all missing keys as null/defaults
    final DocumentReference txnDoc = _db.collection('transactions').doc();
    batch.set(txnDoc, {
      'transactionId': txnDoc.id,
      'referralId': referralId,
      'type': 'commission_credit',
      'status': 'due',

      // Financials
      'amount': commissionAmount,
      'currency': 'INR',
      'commissionPercent': commissionPercent,
      'billAmount': billAmount,

      // Parties
      'fromUid': shopUid,
      'toUid': architectUid,
      'shopId': shopUid,
      'architectId': architectUid,

      // Timestamps & Processing
      'createdAt': now,
      'processedAt': null, // Explicitly null
      'clearedAt': null,   // Explicitly null

      // References
      'payoutBatchId': null,
      'parentTransactionId': null,
      'disputeId': null,

      // Metadata
      'meta': {
        'description': "Commission for $projectName",
        'category': projectType,
        'processingFee': 0,
        'taxes': 0
      }
    });

    // --- 3. LEDGER (Merge) ---
    // Note: If this is the FIRST transaction, 'paidAmount' will not exist.
    // Your UI Model must handle this: (data['paidAmount'] ?? 0)
    final String ledgerId = "${shopUid}_$architectUid";
    final DocumentReference ledgerDoc = _db.collection('ledgers').doc(ledgerId);

    batch.set(ledgerDoc, {
      'shopId': shopUid,
      'architectUid': architectUid,
      'shopName': shopName,
      'architectName': architectName,
      'totalSales': FieldValue.increment(billAmount),
      'totalCommission': FieldValue.increment(commissionAmount),
      'dueAmount': FieldValue.increment(commissionAmount),
      'lastTransactionAt': now,
      'paidAmount': FieldValue.increment(0),
    }, SetOptions(merge: true));

    // --- 4. SHOP STATS (Merge) ---
    // Recommendation: Create this doc with all 0s during Sign Up.
    final DocumentReference statsDoc = _db.collection('shop_stats').doc(shopUid);
    batch.set(statsDoc, {
      'totalRevenue': FieldValue.increment(billAmount),
      'totalCommission': FieldValue.increment(commissionAmount),
      'totalDue': FieldValue.increment(commissionAmount),
      'activeReferrals': FieldValue.increment(-1),
      'totalPaid': FieldValue.increment(0),
      'updatedAt': now,
    }, SetOptions(merge: true));

    // --- 5. WALLET (Merge) ---
    // Wallets usually exist from Architect Sign Up.
    final DocumentReference walletDoc = _db.collection('wallets').doc(architectUid);
    batch.set(walletDoc, {
      'pendingBalance': FieldValue.increment(commissionAmount),
      'totalEarned': FieldValue.increment(commissionAmount),
      'lastUpdatedAt': now,
    }, SetOptions(merge: true));

    // --- 6. NOTIFICATION (Create Full Schema) ---
    // FIX: Added missing delivery fields
    final DocumentReference notifDoc = _db.collection('notifications').doc();
    batch.set(notifDoc, {
      'notificationId': notifDoc.id,
      'toUid': architectUid,
      'toRole': 'architect',

      'type': 'referral_confirmed',
      'title': "Referral Accepted! 🎉",
      'body': "$shopName accepted $projectName. Commission: ₹${commissionAmount.toStringAsFixed(0)}",
      'icon': 'referral_success',

      'actionType': 'navigate',
      'actionData': {'screen': 'referral_detail', 'referralId': referralId},

      // Delivery Status
      'sent': true,
      'sentAt': now,
      'read': false,
      'readAt': null,
      'clicked': false,
      'clickedAt': null,

      'priority': 'high',
      'createdAt': now
    });

    // --- 7. AUDIT LOG (Create Full Schema) ---
    // FIX: Added missing metadata
    final DocumentReference logDoc = _db.collection('audit_logs').doc();
    batch.set(logDoc, {
      'logId': logDoc.id,
      'entityType': 'referral',
      'entityId': referralId,
      'action': 'confirm',

      'byUid': shopUid,
      'byRole': 'shop',
      'byName': shopName,

      'timestamp': now,
      'ipAddress': null, // We can't easily get IP in Flutter client, usually done in Cloud Functions
      'userAgent': 'App Client',
      'deviceId': null, // Requires device_info_plus package, leaving null for now

      'beforeData': {'status': 'pending'}, // Simplified for client-side
      'afterData': {
        'status': 'confirmed',
        'billAmount': billAmount,
        'commissionAmount': commissionAmount
      },
      'changedFields': ['status', 'billAmount', 'commissionAmount'],

      'severity': 'info',
      'category': 'business',
      'description': "Shop confirmed referral and declared bill amount",
    });

    // --- EXECUTE ---
    await batch.commit();
  }
}