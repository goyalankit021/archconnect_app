import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

const String TARGET_UID = "auGiIXMeywfOYR7PU4XfUnO1gLc2";
const String TARGET_SHOP_UID = "82y5zZlbbGhbfruzIiXrgSJURxn2";

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

Future<void> seedShopNotifications(BuildContext context) async {
  final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database'
  );

  final batch = db.batch();
  final timestamp = FieldValue.serverTimestamp();

  // --- 1. NEW LEAD (Actionable: Navigate to Leads) ---
  final notifRef1 = db.collection('notifications').doc();
  batch.set(notifRef1, {
    "notificationId": notifRef1.id,
    "toUid": TARGET_SHOP_UID,
    "toRole": "shop", // 🟢 Identifies this as Shop UI

    // Content
    "type": "referral_initiated",
    "title": "New Lead: Sharma House 🏠",
    "body": "Ar. Ankit has sent a new client for Tiles. Tap to view details.",
    "icon": "referral_initiated", // We will map this to an IconData later

    // Action (The Magic Part)
    "actionType": "navigate",
    "actionData": {
      "screen": "shop_leads", // We will listen for this string
      "tab": "new_requests"   // Optional: Open specific tab
    },

    // Delivery & Meta
    "sent": true,
    "sentAt": timestamp,
    "read": false,
    "readAt": null,
    "clicked": false,
    "clickedAt": null,
    "priority": "high",
    "createdAt": timestamp
  });

  // --- 2. SYSTEM WELCOME (Info Only) ---
  final notifRef2 = db.collection('notifications').doc();
  batch.set(notifRef2, {
    "notificationId": notifRef2.id,
    "toUid": TARGET_SHOP_UID,
    "toRole": "shop",

    "type": "system_alert",
    "title": "Welcome to ArchConnect! 🚀",
    "body": "Your shop is live. Complete your profile to get more leads.",
    "icon": "system_alert",

    "actionType": "none", // No navigation
    "actionData": null,

    "sent": true,
    "sentAt": timestamp,
    "read": true, // Already read
    "priority": "normal",
    "createdAt": timestamp
  });

  // --- 3. PAYOUT APPROVED (Actionable: Navigate to Wallet) ---
  final notifRef3 = db.collection('notifications').doc();
  batch.set(notifRef3, {
    "notificationId": notifRef3.id,
    "toUid": TARGET_SHOP_UID,
    "toRole": "shop",

    "type": "payout_approved",
    "title": "Payout Processed 💰",
    "body": "₹15,000 has been transferred to your HDFC account.",
    "icon": "payout_success",

    "actionType": "navigate",
    "actionData": {
      "screen": "shop_wallet"
    },

    "sent": true,
    "sentAt": timestamp,
    "read": false,
    "priority": "normal",
    "createdAt": timestamp
  });

  await batch.commit();

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Shop Notifications Seeded!"))
    );
  }
}

// Call this function from your Shop Dashboard AppBar
Future<void> seedReferralData(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Error: You must be logged in to seed data.")),
    );
    return;
  }

  // Database Reference
  final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database'
  );

  // The Dummy Data (Targeting YOU as the shop)
  final dummyData = {
    "referralId": "ref_${DateTime.now().millisecondsSinceEpoch}",
    "architectUid": "user_arch_demo_001",
    "shopId": uid, // <--- CRITICAL: Links this lead to YOUR dashboard
    "clientInfo": {
      "name": "Mr. Sharma",
      "phone": "+91 98765 43210",
      "address": "Sector 13, Hisar"
    },
    "projectName": "3BHK Luxury Renovation",
    "projectType": "residential",
    "status": "pending",
    "priority": "urgent",

    // Financials
    "commissionPercent": 5.0,
    "expectedAmount": 150000, // 1.5 Lakhs
    "billAmount": null,
    "commissionAmount": null,

    // Metadata
    "createdAt": FieldValue.serverTimestamp(),
    "expiryAt": DateTime.now().add(const Duration(days: 15)),
    "notes": "Client wants Italian marble options.",
    "materialCategories": ["flooring", "sanitary"],
  };

  try {
    await db.collection('referrals').add(dummyData);

    // Optional: Trigger a snackbar to confirm
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Dummy Lead Added! Check 'Incoming Leads'."),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error seeding: $e")),
      );
    }
  }
}

Future<void> seedPlatformBankDetails() async {
  final db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'arch-connect-database');

  try {
    await db.collection('platform_settings').doc('payment_config').set({
      'bankName': 'HDFC Bank',
      'accountNumber': '50200098765432',
      'ifscCode': 'HDFC0000240',
      'upiId': 'archconnect@hdfc',
      'beneficiaryName': 'ArchConnect Solutions',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    debugPrint("✅ Platform Bank Details Seeded!");
  } catch (e) {
    debugPrint("❌ Error Seeding Bank Details: $e");
  }
}

Future<void> seedShopTransactionHistory(String shopUid, String architectUid) async {
  final db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'arch-connect-database');
  final batch = db.batch();
  final now = DateTime.now();

  // 1. SETTLED TRANSACTION (Historical - Green)
  // Scenario: A project from 2 weeks ago that you already paid for.
  final docRef1 = db.collection('transactions').doc();
  batch.set(docRef1, {
    "transactionId": docRef1.id,
    "referralId": "ref_old_001",
    "type": "commission_credit", // Standard type

    "amount": 4500.00,
    "currency": "INR",
    "commissionPercent": 5.0,
    "billAmount": 90000.0,

    "fromUid": shopUid,
    "toUid": architectUid,
    "shopId": shopUid,
    "architectId": architectUid,

    "status": "settled", // <--- KEY: This means it's PAID
    "createdAt": Timestamp.fromDate(now.subtract(const Duration(days: 14))),
    "processedAt": Timestamp.fromDate(now.subtract(const Duration(days: 1))), // Paid yesterday
    "clearedAt": Timestamp.fromDate(now.subtract(const Duration(days: 1))),

    "meta": {
      "description": "Commission: Gupta Kitchen",
      "category": "modular_kitchen",
    }
  });

  // 2. DUE TRANSACTION (Active - Red)
  // Scenario: A recent project you accepted but haven't paid yet.
  final docRef2 = db.collection('transactions').doc();
  batch.set(docRef2, {
    "transactionId": docRef2.id,
    "referralId": "ref_new_002",
    "type": "commission_credit",

    "amount": 12000.00,
    "currency": "INR",
    "commissionPercent": 5.0,
    "billAmount": 240000.0,

    "fromUid": shopUid,
    "toUid": architectUid,
    "shopId": shopUid,
    "architectId": architectUid,

    "status": "due", // <--- KEY: This means it's PAYABLE
    "createdAt": Timestamp.fromDate(now.subtract(const Duration(days: 2))),
    "processedAt": null,
    "clearedAt": null,

    "meta": {
      "description": "Commission: City Center Office",
      "category": "tiles",
    }
  });

  await batch.commit();
  debugPrint("✅ Shop Transactions Seeded (1 Settled, 1 Due)!");
}