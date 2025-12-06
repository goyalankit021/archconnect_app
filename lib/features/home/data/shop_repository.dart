import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final shopRepositoryProvider = Provider((ref) {
  return ShopRepository(
      FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'arch-connect-database'
      )
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
}

// A FutureProvider to easily load this in the UI
final allShopsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(shopRepositoryProvider).getAllShops();
});