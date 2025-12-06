import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Get Current User ID
final currentUserProvider = Provider<User?>((ref) {
  return FirebaseAuth.instance.currentUser;
});

// 2. Stream the User Profile Data (Real-time!)
final userProfileStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  final user = ref.watch(currentUserProvider);

  if (user == null) return Stream.value(null);

  // POINT TO YOUR SPECIFIC DATABASE ID
  final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database'
  );

  // Listen to the specific user document
  return db.collection('users').doc(user.uid).snapshots().map((snapshot) {
    return snapshot.data();
  });
});