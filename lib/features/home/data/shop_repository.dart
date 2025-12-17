import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final shopRepositoryProvider = Provider((ref) {
  return ShopRepository(
    FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database',
    ),
  );
});

class ShopRepository {
  final FirebaseFirestore _firestore;

  ShopRepository(this._firestore);

  // Fetch ALL shops
  Future<List<Map<String, dynamic>>> getAllShops() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'shop') // <--- The Filter
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception("Failed to fetch shops: $e");
    }
  }

  // --- GET MY SHOP DETAILS (Stream) ---
  Stream<DocumentSnapshot<Map<String, dynamic>>> getMyShopStream(String uid) {
    return _firestore.collection('shops').doc(uid).snapshots();
  }

  // --- UPDATE SHOP OVERVIEW (SYNCED WITH USER EMAIL) ---
  Future<void> updateShopOverview({
    required String uid,
    required String description,
    required String whatsapp,
    required List<String> categories,
    required List<String> brands,
    required String email, // <--- NEW PARAMETER
  }) async {
    final batch = _firestore.batch();

    // 1. Update Shop Details
    final shopRef = _firestore.collection('shops').doc(uid);
    batch.update(shopRef, {
      "description": description,
      "whatsapp": whatsapp,
      "categories": categories,
      "brands": brands,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    // 2. Update Email in Users Collection
    final userRef = _firestore.collection('users').doc(uid);
    batch.update(userRef, {
      "email": email,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // --- UPDATE SHOP PHOTO (SYNCED) ---
  Future<void> updateShopPhoto(String uid, String url) async {
    final batch = _firestore.batch();

    // 1. Update Shop Document
    final shopRef = _firestore.collection('shops').doc(uid);
    batch.update(shopRef, {
      "profilePhotoUrl": url,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    // 2. Update User Document (For App Drawer/Common UI)
    final userRef = _firestore.collection('users').doc(uid);
    batch.update(userRef, {
      "profilePhotoUrl": url,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // --- UPDATE SHOP ADDRESS ---
  Future<void> updateShopAddress({
    required String uid,
    required String street,
    required String city,
    required String state,
    required String pincode,
  }) async {
    await _firestore.collection('shops').doc(uid).update({
      "address": {
        "street": street,
        "city": city,
        "state": state,
        "pincode": pincode,
      },
      // We also update the top-level location metadata for easier filtering later
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  // --- UPDATE BUSINESS HOURS ---
  Future<void> updateBusinessHours({
    required String uid,
    required Map<String, dynamic> businessHours,
  }) async {
    await _firestore.collection('shops').doc(uid).update({
      "businessHours": businessHours,
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  // --- ADD IMAGE TO GALLERY ---
  Future<void> addGalleryImage(String uid, String url) async {
    await _firestore.collection('shops').doc(uid).update({
      "galleryImages": FieldValue.arrayUnion([url]), // Adds to array
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeGalleryImage(String uid, String url) async {
    // 1. Delete from Cloud Storage (Clean up)
    // We use a try-catch block for storage deletion so it doesn't stop the DB update
    try {
      final storageRef = FirebaseStorage.instance.refFromURL(url);
      await storageRef.delete();
    } catch (e) {
      print("Storage delete error (might already be gone): $e");
    }

    // 2. Remove link from Firestore
    await _firestore.collection('shops').doc(uid).update({
      "galleryImages": FieldValue.arrayRemove([url]),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }
}

// A FutureProvider to easily load this in the UI
final allShopsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  return ref.read(shopRepositoryProvider).getAllShops();
});
