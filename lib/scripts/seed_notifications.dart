import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

const String TARGET_UID = "auGiIXMeywfOYR7PU4XfUnO1gLc2";

Future<void> seedNotifications() async {
  final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database'
  );

  final batch = db.batch();

  // --- 1. SEED REFERRALS (Strict Schema) ---

  // Referral 1: Pending (Just sent, no bill yet)
  final refRef1 = db.collection('referrals').doc("ref_mock_003");
  batch.set(refRef1, {
    "referralId": "ref_mock_003",
    "architectUid": TARGET_UID,
    "shopId": "shop_goyal_001",
    // UI Helper (Optional but good for lists)
    "shopName": "Goyal Hardware",

    "clientInfo": {
      "name": "Mr. Rahul Verma",
      "phone": "+919876543210",
      "address": "Sector 14, Hisar"
    },
    "projectName": "Verma Kitchen Reno",
    "projectType": "renovation",

    "status": "pending",
    "priority": "normal",

    // Financials
    "commissionPercent": 5.0,
    "expectedAmount": 50000,
    "billAmount": null,
    "commissionAmount": null,

    // Meta
    "createdAt": Timestamp.now(),
    "expiryAt": Timestamp.fromDate(DateTime.now().add(const Duration(days: 15))),
    "materialCategories": ["hardware", "plywood"],
    "estimatedCategories": {
      "hardware": 30000,
      "plywood": 20000
    },
    "notes": "Client needs waterproof ply.",

    // Audit Trail
    "statusHistory": [
      {
        "status": "pending",
        "timestamp": Timestamp.now(),
        "byUid": TARGET_UID
      }
    ]
  });

  // Referral 2: Confirmed (Shop accepted)
  final refRef2 = db.collection('referrals').doc("ref_mock_002");
  batch.set(refRef2, {
    "referralId": "ref_mock_002",
    "architectUid": TARGET_UID,
    "shopId": "shop_goyal_001",
    "shopName": "Goyal Hardware",

    "clientInfo": {
      "name": "Mrs. Anjali Gupta",
      "phone": "+919876543211",
      "address": "Draupadi Ghat"
    },
    "projectName": "Gupta 3BHK",
    "projectType": "residential",

    "status": "confirmed",
    "priority": "urgent",

    "commissionPercent": 5.0,
    "expectedAmount": 120000,
    "billAmount": null,
    "commissionAmount": null,

    "createdAt": Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
    "confirmedAt": Timestamp.now(),
    "materialCategories": ["tiles"],

    "statusHistory": [
      {
        "status": "pending",
        "timestamp": Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        "byUid": TARGET_UID
      },
      {
        "status": "confirmed",
        "timestamp": Timestamp.now(),
        "byUid": "shop_goyal_001"
      }
    ]
  });

  // Referral 3: Completed (Money Made!)
  final refRef3 = db.collection('referrals').doc("ref_mock_001");
  batch.set(refRef3, {
    "referralId": "ref_mock_001",
    "architectUid": TARGET_UID,
    "shopId": "shop_sharma_002",
    "shopName": "Sharma Tiles",

    "clientInfo": {
      "name": "Mr. Vikram Singh",
      "phone": "+919876543212",
      "address": "Model Town"
    },
    "projectName": "Vikram Farmhouse",
    "projectType": "commercial",

    "status": "completed",
    "priority": "normal",

    "commissionPercent": 5.0,
    "expectedAmount": 150000,
    "billAmount": 150000,   // ✅ Actual Bill
    "commissionAmount": 7500, // ✅ Actual Commission

    "createdAt": Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 10))),
    "confirmedAt": Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 9))),
    "materialCategories": ["tiles", "sanitary"],

    "statusHistory": [
      { "status": "pending", "timestamp": Timestamp.now(), "byUid": TARGET_UID },
      { "status": "confirmed", "timestamp": Timestamp.now(), "byUid": "shop_sharma_002" },
      { "status": "completed", "timestamp": Timestamp.now(), "byUid": "shop_sharma_002" }
    ]
  });

  await batch.commit();
  debugPrint("✅ SEED COMPLETE: Referrals, Transactions, and Wallets updated.");
}