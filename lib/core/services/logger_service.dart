import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';

// Provide the logger globally
final loggerServiceProvider = Provider((ref) => LoggerService());

class LoggerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database'
  );
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // =========================================================
  // 1. LOG DEBUG (Console Only)
  // =========================================================
  void logDebug(String message) {
    if (kDebugMode) {
      print("🔵 [DEBUG]: $message");
    }
  }

  // =========================================================
  // 2. LOG ERROR (Crashlytics)
  // =========================================================
  Future<void> logError(dynamic exception, StackTrace? stack, {String? reason}) async {
    if (kDebugMode) {
      print("🔴 [ERROR]: $exception");
      if (stack != null) print(stack);
      return;
    }
    await _crashlytics.recordError(exception, stack, reason: reason);
  }

  // =========================================================
  // 3. LOG AUDIT (Firestore using your Schema)
  // =========================================================
  Future<void> logAudit({
    required String entityType,
    required String entityId,
    required String action,
    required String description,
    String severity = 'info', // info | warning | critical
    String category = 'business', // business | security | system
    Map<String, dynamic>? beforeData,
    Map<String, dynamic>? afterData,
    List<String>? changedFields,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return; // Don't log unauthenticated ghosts

      // Get basic device info (IP is skipped to save external API calls)
      String deviceId = 'unknown';
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceId = "${androidInfo.brand} ${androidInfo.model}";
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.utsname.machine;
      }

      final logData = {
        "logId": "log_${DateTime.now().millisecondsSinceEpoch}",

        // Entity
        "entityType": entityType,
        "entityId": entityId,
        "action": action,

        // Actor
        "byUid": user.uid,
        "byRole": "user", // Can be passed dynamically if needed
        "byName": user.displayName ?? "Unknown",

        // Context
        "timestamp": FieldValue.serverTimestamp(),
        "ipAddress": "skipped", // Handled by server functions if strictly needed later
        "userAgent": "ArchConnect Flutter App",
        "deviceId": deviceId,

        // Change Details
        "beforeData": beforeData ?? {},
        "afterData": afterData ?? {},
        "changedFields": changedFields ?? [],

        // Metadata
        "severity": severity,
        "category": category,
        "description": description,
      };

      // Fire and forget (Asynchronous)
      _firestore.collection('logs').add(logData);

      // Also print it locally so we see it while coding
      logDebug("Audit Log Saved: $action on $entityType");

    } catch (e, s) {
      // If logging to Firestore fails, shoot it to Crashlytics
      logError(e, s, reason: "Audit Logging Failed");
    }
  }
}