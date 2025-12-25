import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

// ⚠️ CHANGE THIS TO YOUR ACTUAL ARCHITECT UID from Authentication
// You can find this in the Firebase Console -> Authentication -> User UID
const String TARGET_UID = "auGiIXMeywfOYR7PU4XfUnO1gLc2"; // Ensure this matches your login

Future<void> seedNotifications() async {
  // Ensure Firebase is initialized (if running from main app trigger)
  // If running standalone, we need setup, but easiest way is to trigger this from a temporary button.

  final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database'
  );

  final batch = db.batch();

  // --- Sample 1: Referral Confirmed (Unread) ---
  final id1 = "notif_seed_${DateTime.now().millisecondsSinceEpoch}_1";
  final ref1 = db.collection('notifications').doc(id1);
  batch.set(ref1, {
    "notificationId": id1,
    "toUid": TARGET_UID,
    "toRole": "architect",
    "type": "referral_confirmed",
    "title": "Referral Confirmed! 🎉",
    "body": "Your referral at Goyal Hardware has been confirmed for ₹1,20,000",
    "icon": "referral_success",
    "actionType": "navigate",
    "actionData": {"screen": "referral_detail", "referralId": "ref_mock_001"},
    "sent": true,
    "sentAt": FieldValue.serverTimestamp(),
    "read": false, // UNREAD
    "readAt": null,
    "clicked": false,
    "clickedAt": null,
    "priority": "high",
    "createdAt": FieldValue.serverTimestamp()
  });

  // --- Sample 2: Payout Received (Unread) ---
  final id2 = "notif_seed_${DateTime.now().millisecondsSinceEpoch}_2";
  final ref2 = db.collection('notifications').doc(id2);
  batch.set(ref2, {
    "notificationId": id2,
    "toUid": TARGET_UID,
    "toRole": "architect",
    "type": "payout_received",
    "title": "Payment Received 💰",
    "body": "You received ₹5,000 commission for the Sharma Villa project.",
    "icon": "money",
    "actionType": "navigate",
    "actionData": {"screen": "wallet", "referralId": null},
    "sent": true,
    "sentAt": FieldValue.serverTimestamp(),
    "read": false, // UNREAD
    "readAt": null,
    "clicked": false,
    "clickedAt": null,
    "priority": "normal",
    "createdAt": FieldValue.serverTimestamp()
  });

  // --- Sample 3: Old Alert (Read) ---
  final id3 = "notif_seed_${DateTime.now().millisecondsSinceEpoch}_3";
  final ref3 = db.collection('notifications').doc(id3);
  batch.set(ref3, {
    "notificationId": id3,
    "toUid": TARGET_UID,
    "toRole": "architect",
    "type": "system_alert",
    "title": "Welcome to ArchConnect",
    "body": "Your profile has been verified. Start referring today!",
    "icon": "info",
    "actionType": "none",
    "actionData": null,
    "sent": true,
    "sentAt": Timestamp.now(), // slightly older
    "read": true, // READ
    "readAt": Timestamp.now(),
    "clicked": true,
    "clickedAt": Timestamp.now(),
    "priority": "low",
    "createdAt": Timestamp.now()
  });

  await batch.commit();
  debugPrint("✅ 3 Sample Notifications Added for UID: $TARGET_UID");
}