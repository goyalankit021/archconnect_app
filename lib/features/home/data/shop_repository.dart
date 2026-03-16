import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/logger_service.dart'; // ✅ Added Logger

final shopRepositoryProvider = Provider((ref) {
  final logger = ref.read(loggerServiceProvider);
  return ShopRepository(
    FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database',
    ),
    logger,
  );
});

class ShopRepository {
  final FirebaseFirestore _firestore;
  final LoggerService _logger;

  ShopRepository(this._firestore, this._logger);

  // --- FETCH ALL SHOPS ---
  Future<List<Map<String, dynamic>>> getAllShops() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'shop')
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e, s) {
      _logger.logError(e, s, reason: "Failed to fetch all shops");
      throw Exception("Failed to fetch shops: $e");
    }
  }

  // --- GET MY SHOP DETAILS (Stream) ---
  Stream<DocumentSnapshot<Map<String, dynamic>>> getMyShopStream(String uid) {
    return _firestore.collection('shops').doc(uid).snapshots();
  }

  // --- UPDATE SHOP OVERVIEW ---
  Future<void> updateShopOverview({
    required String uid,
    required String description,
    required String whatsapp,
    required List<String> categories,
    required List<String> brands,
    required String email,
  }) async {
    final batch = _firestore.batch();

    final shopRef = _firestore.collection('shops').doc(uid);
    batch.update(shopRef, {
      "description": description,
      "whatsapp": whatsapp,
      "categories": categories,
      "brands": brands,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    final userRef = _firestore.collection('users').doc(uid);
    batch.update(userRef, {
      "email": email,
      "updatedAt": FieldValue.serverTimestamp(),
    });

    await batch.commit();

    _logger.logAudit(
      entityType: 'shop_profile',
      entityId: uid,
      action: 'update_overview',
      description: 'Shop owner updated their business overview and categories',
    );
  }

  // --- UPDATE SHOP PHOTO ---
  Future<void> updateShopPhoto(String uid, String url) async {
    final batch = _firestore.batch();

    final shopRef = _firestore.collection('shops').doc(uid);
    batch.update(shopRef, {"profilePhotoUrl": url, "updatedAt": FieldValue.serverTimestamp()});

    final userRef = _firestore.collection('users').doc(uid);
    batch.update(userRef, {"profilePhotoUrl": url, "updatedAt": FieldValue.serverTimestamp()});

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
      "updatedAt": FieldValue.serverTimestamp(),
    });

    _logger.logAudit(
      entityType: 'shop_profile',
      entityId: uid,
      action: 'update_address',
      description: 'Shop owner updated physical address',
    );
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
      "galleryImages": FieldValue.arrayUnion([url]),
      "updatedAt": FieldValue.serverTimestamp(),
    });

    _logger.logAudit(
      entityType: 'shop_gallery',
      entityId: uid,
      action: 'add_image',
      description: 'Shop added a new photo to public gallery',
    );
  }

  // --- REMOVE IMAGE FROM GALLERY ---
  Future<void> removeGalleryImage(String uid, String url) async {
    try {
      final storageRef = FirebaseStorage.instance.refFromURL(url);
      await storageRef.delete();
    } catch (e, s) {
      _logger.logError(e, s, reason: "Storage delete error during gallery cleanup");
    }

    await _firestore.collection('shops').doc(uid).update({
      "galleryImages": FieldValue.arrayRemove([url]),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  // --- FETCH ACTIVE SHOPS FOR DISCOVERY ---
  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> getActiveShopsStream() {
    return _firestore
        .collection('shops')
        .where('status', isEqualTo: 'active')
    // ✅ CRITICAL FIX: Only show fully verified shops to Architects
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // --- TOGGLE SHOP STATUS (ONLINE/OFFLINE) ---
  Future<void> updateShopStatus(String uid, bool isActive) async {
    await _firestore.collection('shops').doc(uid).update({
      "status": isActive ? "active" : "inactive",
      "updatedAt": FieldValue.serverTimestamp(),
    });

    _logger.logAudit(
      entityType: 'shop_profile',
      entityId: uid,
      action: 'toggle_status',
      description: 'Shop changed visibility status to ${isActive ? "active" : "inactive"}',
    );
  }
}

final allShopsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ref.read(shopRepositoryProvider).getAllShops();
});