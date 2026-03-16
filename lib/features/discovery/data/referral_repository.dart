import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/logger_service.dart'; // ✅ Logger

final referralRepositoryProvider = Provider((ref) {
  final logger = ref.read(loggerServiceProvider);
  return ReferralRepository(logger);
});

final referralsStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.read(referralRepositoryProvider).getReferrals(uid);
});

final recentActivityStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.read(referralRepositoryProvider).getRecentReferrals(uid);
});

class ReferralRepository {
  final LoggerService _logger;

  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database'
  );

  ReferralRepository(this._logger);

  Stream<List<Map<String, dynamic>>> getReferrals(String uid) {
    return _db
        .collection('referrals')
        .where('architectUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> getRecentReferrals(String uid) {
    return _db
        .collection('referrals')
        .where('architectUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(3)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // --- 🆕 CREATE NEW REFERRAL (DENORMALIZED FOR SPEED) ---
  Future<void> createReferral({
    required String architectUid,
    required String architectName, // ✅ Added
    required String shopId,
    required String shopName,      // ✅ Added
    required double commissionPercent,
    required Map<String, dynamic> clientInfo,
    required String projectName,
    required String projectType,
    required String notes,
  }) async {
    try {
      final referralRef = _db.collection('referrals').doc();
      final expiryDate = DateTime.now().add(const Duration(days: 15));

      final referralData = {
        "referralId": referralRef.id,
        "architectUid": architectUid,
        "architectName": architectName, // ✅ Stored for instant UI reads
        "shopId": shopId,
        "shopName": shopName,           // ✅ Stored for instant UI reads

        "clientInfo": clientInfo,
        "projectName": projectName,
        "projectType": projectType,

        "status": "pending",
        "priority": "normal",

        "commissionPercent": commissionPercent,
        "expectedAmount": 0.0,
        "billAmount": null,
        "commissionAmount": null,

        "billImageUrl": null,
        "additionalDocs": [],

        "createdAt": FieldValue.serverTimestamp(),
        "expiryAt": Timestamp.fromDate(expiryDate),
        "confirmedAt": null,
        "lastReminderAt": null,

        "confirmedByUid": null,
        "notes": notes,
        "internalNotes": null,

        "materialCategories": [],
        "estimatedCategories": {},

        "statusHistory": [
          {
            "status": "pending",
            "timestamp": Timestamp.now(), // Safe array timestamp
            "byUid": architectUid
          }
        ]
      };

      await referralRef.set(referralData);

      _logger.logAudit(
          entityType: 'referral',
          entityId: referralRef.id,
          action: 'create',
          description: 'Architect ($architectName) sent referral to shop ($shopName)',
          category: 'business',
          severity: 'critical'
      );

    } catch (e, s) {
      _logger.logError(e, s, reason: "Failed to create denormalized referral");
      throw Exception("Failed to send referral: $e");
    }
  }
}