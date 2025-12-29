import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final referralRepositoryProvider = Provider((ref) => ReferralRepository());

// 1. Stream ALL referrals (For Track Status Screen)
final referralsStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.read(referralRepositoryProvider).getReferrals(uid);
});

// 2. Stream RECENT referrals (For Dashboard Activity - Limit 3)
final recentActivityStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return ref.read(referralRepositoryProvider).getRecentReferrals(uid);
});

class ReferralRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database'
  );

  // Fetch Full List
  Stream<List<Map<String, dynamic>>> getReferrals(String uid) {
    return _db
        .collection('referrals')
        .where('architectUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Fetch Top 3
  Stream<List<Map<String, dynamic>>> getRecentReferrals(String uid) {
    return _db
        .collection('referrals')
        .where('architectUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(3) // ✅ Optimization: Only fetch 3
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}