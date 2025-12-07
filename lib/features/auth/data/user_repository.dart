import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRepositoryProvider = Provider((ref) {
  return UserRepository(
      FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'arch-connect-database'
      )
  );
});

class UserRepository {
  final FirebaseFirestore _firestore;
  UserRepository(this._firestore);

  Future<void> saveUserProfile({
    required User user,
    required String name,
    required String firmName,
    required String role, // 'architect' or 'shop'
    required String city,
    required String state,
  }) async {
    final batch = _firestore.batch();
    final timestamp = FieldValue.serverTimestamp();

    // ====================================================
    // 1. USERS COLLECTION (Exact Schema Match)
    // ====================================================
    final userRef = _firestore.collection('users').doc(user.uid);

    final userData = {
      "uid": user.uid,
      "role": role,
      "name": name,
      "phone": user.phoneNumber,
      "email": null, // Captured later
      "profilePhotoUrl": null,

      // FIRM OBJECT (As per Schema)
      "firm": {
        "name": firmName,
        "isFirmAccount": false, // Default
        "license": null // Captured in 'Complete Profile'
      },

      "createdAt": timestamp,
      "updatedAt": timestamp,
      "status": "active",

      // 🚩 THE FLAG
      "isProfileComplete": false,

      // METADATA (Location goes here for User)
      "metadata": {
        "city": city,
        "state": state,
        "deviceIds": [],
        "lastLoginAt": timestamp,
        "appVersion": "1.0.0",
      },

      "trustScore": 100,
      "kycStatus": "pending",
      "kycDocuments": {},
    };

    batch.set(userRef, userData);

    // ====================================================
    // 2. ROLE SPECIFIC COLLECTIONS
    // ====================================================

    if (role == 'architect') {
      // ---> WALLETS COLLECTION
      final walletRef = _firestore.collection('wallets').doc(user.uid);
      batch.set(walletRef, {
        "uid": user.uid,
        "balance": 0.00,
        "pendingBalance": 0.00,
        "frozenBalance": 0.00,
        "currency": "INR",
        "lastUpdatedAt": timestamp,

        // Counters
        "totalEarned": 0.00,
        "totalWithdrawn": 0.00,
        "transactionCount": 0,

        // Settings
        "autoPayoutThreshold": 10000.00,
        "minimumBalance": 0.00,

        // Bank Details (Placeholder structure)
        "bankDetails": {
          "upi": null,
          "accountNumber": null,
          "ifsc": null,
          "bankName": null
        }
      });

    } else if (role == 'shop') {
      // ---> SHOPS COLLECTION
      final shopRef = _firestore.collection('shops').doc(user.uid);

      batch.set(shopRef, {
        "shopId": user.uid,
        "ownerUid": user.uid,
        "name": firmName, // Shop Name
        "description": "New Shop",

        // ADDRESS OBJECT (Location goes here for Shop)
        "address": {
          "street": "", // Captured later
          "city": city,
          "state": state,
          "pincode": "" // Captured later
        },

        "phone": user.phoneNumber,
        "whatsapp": user.phoneNumber,

        "categories": ["general"],
        "brands": [],

        // Commission
        "commissionDefaultPercent": 5.0,
        "commissionTiers": {
          "hardware": 3.0,
          "tiles": 5.0,
          "paint": 4.0
        },

        "status": "active",
        "createdAt": timestamp,
        "updatedAt": timestamp,
        "profilePhotoUrl": null,
        "galleryImages": [],

        "location": {
          "lat": 0.0,
          "lng": 0.0,
          "geohash": ""
        },

        // Business Hours (Default Structure)
        "businessHours": {
          "monday": {"open": "09:00", "close": "20:00"},
          "sunday": {"open": "10:00", "close": "18:00"}
        },

        "ratings": {
          "average": 0.0,
          "count": 0
        }
      });
    }

    // ====================================================
    // 3. COMMIT
    // ====================================================
    await batch.commit();
  }

  // --- UPDATE KYC DOCUMENTS ---
  Future<void> uploadKycDocument({
    required String uid,
    required String docType, // 'aadhar' or 'pan'
    required String url,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      "kycDocuments.$docType": url,
      "updatedAt": FieldValue.serverTimestamp(),
      // Note: We DO NOT change kycStatus here.
      // Manual verification is required by Admin.
    });
  }

  // --- UPDATE PROFILE PHOTO ---
  Future<void> updateProfilePhoto(String uid, String url) async {
    await _firestore.collection('users').doc(uid).update({
      "profilePhotoUrl": url,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  // --- UPDATE BANK DETAILS ---
  Future<void> updateBankDetails({
    required String uid,
    required String accountNumber,
    required String ifsc,
    required String bankName,
    required String upiId,
  }) async {
    // 1. Reference the Wallet Document
    final walletRef = _firestore.collection('wallets').doc(uid);

    // 2. Update the specific map field
    await walletRef.update({
      "bankDetails": {
        "accountNumber": accountNumber,
        "ifsc": ifsc.toUpperCase(),
        "bankName": bankName,
        "upi": upiId,
      },
      "lastUpdatedAt": FieldValue.serverTimestamp(),
    });

    // 3. OPTIONAL: Check if Profile is now "Complete"
    // For now, we just save the bank data.
  }

  // --- FETCH WALLET DATA (To display it) ---
  Stream<DocumentSnapshot> getWalletStream(String uid) {
    return _firestore.collection('wallets').doc(uid).snapshots();
  }

  Future<void> updatePersonalDetails({
    required String uid,
    required String name,
    required String firmName,
    required String email,
    required String city,
    required String state,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      "name": name,
      "email": email,
      "firm.name": firmName,       // Dot notation updates ONLY the name inside firm
      "metadata.city": city,       // Dot notation updates ONLY the city
      "metadata.state": state,     // Dot notation updates ONLY the state
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }
}