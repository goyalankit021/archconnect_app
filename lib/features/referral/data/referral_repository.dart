import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notifications/data/notification_repository.dart';

final referralRepositoryProvider = Provider((ref) => ReferralRepository());

class ReferralRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database'
  );

  // Instance of our new centralized repo
  final _notificationRepo = NotificationRepository();

  // --- CREATE NEW REFERRAL ---
  // --- CREATE REFERRAL & NOTIFY SHOP ---
  Future<void> createReferral({
    required String architectUid,
    required String architectName, // <--- We need this for the notification body
    required String shopId,
    required Map<String, dynamic> clientInfo,
    required String projectName,
    required String projectType,
    required double commissionPercent,
    required String notes,
  }) async {
    final batch = _firestore.batch(); // <--- START BATCH

    // 1. GENERATE IDs
    final String referralId = "ref_${DateTime.now().millisecondsSinceEpoch}";
    final String notificationId = "notif_${DateTime.now().millisecondsSinceEpoch}";
    final expiryDate = DateTime.now().add(const Duration(days: 15));

    // 2. REFERRAL DATA
    final referralRef = _firestore.collection('referrals').doc(referralId);
    final referralData = {
      "referralId": referralId,
      "architectUid": architectUid,
      "shopId": shopId, // This will now be correct!
      "clientInfo": clientInfo,
      "projectName": projectName,
      "projectType": projectType,
      "status": "pending",
      "priority": "normal",
      "commissionPercent": commissionPercent,
      "expectedAmount": null,
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
      "internalNotes": "",
      "materialCategories": [],
      "estimatedCategories": null,
      "statusHistory": [
        {
          "status": "pending",
          "timestamp": Timestamp.now(),
          "byUid": architectUid
        }
      ]
    };
    batch.set(referralRef, referralData);

    // 2. NOTIFICATION LOGIC (✅ Now Centralized!)
    // We ask the NotificationRepo to give us the correctly formatted data
    final (notifRef, notifData) = _notificationRepo.prepareBatchNotification(
        toUid: shopId,
        toRole: 'shop',
        type: 'referral_initiated',
        title: "New Lead Received! 🎉",
        body: "Ar. $architectName has referred a new client.",
        actionData: {
          "screen": "referral_detail",
          "referralId": referralId
        }
    );
    batch.set(notifRef, notifData);

    // 4. COMMIT BATCH
    await batch.commit();
  }
}