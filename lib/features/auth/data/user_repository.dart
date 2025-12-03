import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider to access this repo anywhere
final userRepositoryProvider = Provider((ref) {
  // We explicitly target your named database here
  return UserRepository(
      FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'arch-connect-database' // <--- The name you set
      )
  );
});

class UserRepository {
  final FirebaseFirestore _firestore;
  UserRepository(this._firestore);

  // --- 1. Check if User Exists ---
  Future<bool> checkUserExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      throw Exception("Failed to check user: $e");
    }
  }

  // --- 2. Get User Role (For routing) ---
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // --- 3. Save New User Profile ---
  Future<void> saveUserProfile({
    required User user,
    required String name,
    required String firmName,
    required String role, // 'architect' or 'shop'
  }) async {
    final batch = _firestore.batch();

    // A. Reference to the User Document
    final userRef = _firestore.collection('users').doc(user.uid);

    // B. Data based on your Schema
    final userData = {
      "uid": user.uid,
      "role": role,
      "name": name,
      "phone": user.phoneNumber,
      "firm": {
        "name": firmName,
        "isFirmAccount": true, // Defaulting for now
      },
      "createdAt": FieldValue.serverTimestamp(),
      "status": "active",
      "metadata": {
        "lastLoginAt": FieldValue.serverTimestamp(),
        "appVersion": "1.0.0",
      },
      // Initialize basic stats
      "trustScore": 100,
      "kycStatus": "pending",
    };

    batch.set(userRef, userData);

    // C. Role Specific Setup
    if (role == 'architect') {
      // Create empty Wallet for Architect
      final walletRef = _firestore.collection('wallets').doc(user.uid);
      batch.set(walletRef, {
        "uid": user.uid,
        "balance": 0.00,
        "pendingBalance": 0.00,
        "currency": "INR",
        "lastUpdatedAt": FieldValue.serverTimestamp(),
        "totalEarned": 0.00,
      });
    } else if (role == 'shop') {
      // Create Shop Entry (We use the same UID for owner reference)
      // Note: In a real app, we might generate a specific shopId,
      // but for MVP, using UID as shopID or a derivative is fine.
      final shopRef = _firestore.collection('shops').doc(user.uid);
      batch.set(shopRef, {
        "shopId": user.uid,
        "ownerUid": user.uid,
        "name": firmName, // Shop name is usually the firm name
        "phone": user.phoneNumber,
        "status": "active",
        "commissionDefaultPercent": 0.0, // Needs setup later
        "createdAt": FieldValue.serverTimestamp(),
        "ratings": {"average": 0.0, "count": 0},
      });
    }

    // D. Commit all changes at once (Atomic Transaction)
    await batch.commit();
  }
}