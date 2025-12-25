import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final notificationRepositoryProvider = Provider((ref) => NotificationRepository());

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database'
  );

  // --- 1. SEND STANDALONE NOTIFICATION (Directly writes to DB) ---
  Future<void> sendNotification({
    required String toUid,
    required String toRole, // 'architect' | 'shop'
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic>? actionData,
  }) async {
    final notifRef = _firestore.collection('notifications').doc();
    final data = _generateSchema(
      id: notifRef.id,
      toUid: toUid,
      toRole: toRole,
      type: type,
      title: title,
      body: body,
      actionData: actionData,
    );
    await notifRef.set(data);
  }

  // --- 2. PREPARE FOR BATCH (For Referrals/Transactions) ---
  // Returns the Reference and Data so the caller (ReferralRepo) can add it to their batch.
  (DocumentReference, Map<String, dynamic>) prepareBatchNotification({
    required String toUid,
    required String toRole,
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic>? actionData,
  }) {
    final notifRef = _firestore.collection('notifications').doc(); // Auto-ID
    final data = _generateSchema(
      id: notifRef.id,
      toUid: toUid,
      toRole: toRole,
      type: type,
      title: title,
      body: body,
      actionData: actionData,
    );
    return (notifRef, data);
  }

  // --- CENTRAL SCHEMA GENERATOR (Private) ---
  Map<String, dynamic> _generateSchema({
    required String id,
    required String toUid,
    required String toRole,
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic>? actionData,
  }) {
    return {
      "notificationId": id,
      "toUid": toUid,
      "toRole": toRole,

      // Content
      "type": type,
      "title": title,
      "body": body,
      "icon": _getIconForType(type), // Helper to pick icon name

      // Action
      "actionType": actionData != null ? "navigate" : "none",
      "actionData": actionData,

      // Delivery Status
      "sent": true,
      "sentAt": FieldValue.serverTimestamp(),
      "read": false,
      "readAt": null,
      "clicked": false,
      "clickedAt": null,

      // Metadata
      "priority": "high",
      "fcmMessageId": null,
      "createdAt": FieldValue.serverTimestamp()
    };
  }

  String _getIconForType(String type) {
    if (type.contains("referral")) return "referral_icon";
    if (type.contains("money") || type.contains("payout")) return "rupee_icon";
    return "bell_icon";
  }
}