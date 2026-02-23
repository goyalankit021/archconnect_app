import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/logger_service.dart'; // ✅ Added Logger Service

// ✅ FIX: Injected the Logger Service into the Repository
final userRepositoryProvider = Provider((ref) {
  final logger = ref.read(loggerServiceProvider);
  return UserRepository(
    FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'arch-connect-database'
    ),
    logger,
  );
});

class UserRepository {
  final FirebaseFirestore _firestore;
  final LoggerService _logger; // ✅ Internal logger reference

  UserRepository(this._firestore, this._logger);

  // --- SAVE USER PROFILE (INITIAL SETUP) ---
  Future<void> saveUserProfile({
    required User user,
    required String name,
    required String firmName,
    required String role, // 'architect' or 'shop'
    required String city,
    required String state,
  }) async {
    // We use a Batch to ensure ALL documents are created, or NONE are.
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
      "email": null,
      "profilePhotoUrl": null,
      "firm": {
        "name": firmName,
        "isFirmAccount": false,
        "license": null
      },
      "createdAt": timestamp,
      "updatedAt": timestamp,
      "status": "active",
      "isProfileComplete": false, // 🚩 THE FLAG
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
      // ---> WALLETS COLLECTION (Architects)
      final walletRef = _firestore.collection('wallets').doc(user.uid);
      batch.set(walletRef, {
        "uid": user.uid,
        "balance": 0.00,
        "pendingBalance": 0.00,
        "frozenBalance": 0.00,
        "currency": "INR",
        "lastUpdatedAt": timestamp,
        "totalEarned": 0.00,
        "totalWithdrawn": 0.00,
        "transactionCount": 0,
        "autoPayoutThreshold": 10000.00,
        "minimumBalance": 0.00,
        "bankDetails": {
          "upi": null,
          "accountNumber": null,
          "ifsc": null,
          "bankName": null
        }
      });

    } else if (role == 'shop') {
      // ---> SHOPS COLLECTION (Shops)
      final shopRef = _firestore.collection('shops').doc(user.uid);
      batch.set(shopRef, {
        "shopId": user.uid,
        "ownerUid": user.uid,
        "name": firmName,
        "description": "New Shop",
        "address": {
          "street": "",
          "city": city,
          "state": state,
          "pincode": ""
        },
        "phone": user.phoneNumber,
        "whatsapp": user.phoneNumber,
        "categories": ["general"],
        "brands": [],
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
        "location": {"lat": 0.0, "lng": 0.0, "geohash": ""},
        "businessHours": {
          "monday": {"open": "09:00", "close": "20:00"},
          "sunday": {"open": "10:00", "close": "18:00"}
        },
        "ratings": {"average": 0.0, "count": 0}
      });

      // ---> SHOP STATS COLLECTION
      final statsRef = _firestore.collection('shop_stats').doc(user.uid);
      batch.set(statsRef, {
        "totalRevenue": 0.0,
        "totalCommission": 0.0,
        "totalPaid": 0.0,
        "totalDue": 0.0,
        "activeReferrals": 0,
        "updatedAt": timestamp,
      });
    }

    // ====================================================
    // 3. COMMIT BATCH
    // ====================================================
    await batch.commit();
    _logger.logDebug("Batch commit successful for new user: ${user.uid} ($role)");
  }

  // --- UPDATE KYC DOCUMENTS ---
  Future<void> uploadKycDocument({
    required String uid,
    required String docType,
    required String url,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      "kycDocuments.$docType": url,
      "kycStatus": "verification_pending",
      "updatedAt": FieldValue.serverTimestamp(),
    });

    // ✅ LOG IT: High value security action
    _logger.logAudit(
        entityType: 'user_kyc',
        entityId: uid,
        action: 'upload_document',
        description: 'User uploaded KYC document: $docType',
        severity: 'info'
    );
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
    final walletRef = _firestore.collection('wallets').doc(uid);

    await walletRef.update({
      "bankDetails": {
        "accountNumber": accountNumber,
        "ifsc": ifsc.toUpperCase(),
        "bankName": bankName,
        "upi": upiId,
      },
      "lastUpdatedAt": FieldValue.serverTimestamp(),
    });

    // ✅ LOG IT: High value financial security action
    _logger.logAudit(
        entityType: 'wallet',
        entityId: uid,
        action: 'update_bank_details',
        description: 'User updated their payout bank details',
        severity: 'warning', // Warning severity because bank details changed
        category: 'security'
    );
  }

  // --- FETCH WALLET DATA ---
  Stream<DocumentSnapshot> getWalletStream(String uid) {
    return _firestore.collection('wallets').doc(uid).snapshots();
  }

  // --- UPDATE PERSONAL DETAILS ---
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
      "firm.name": firmName,
      "metadata.city": city,
      "metadata.state": state,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    _logger.logAudit(
        entityType: 'user_profile',
        entityId: uid,
        action: 'update_personal_details',
        description: 'User updated core personal info',
        severity: 'info'
    );
  }
}