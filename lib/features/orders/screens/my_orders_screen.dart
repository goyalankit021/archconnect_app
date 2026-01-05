import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../leads/widgets/referral_list_card.dart';
import '../../leads/screens/referral_details_sheet.dart';

// --- PROVIDER: FETCH ONLY CONFIRMED ORDERS ---
final shopOrdersProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'arch-connect-database')
      .collection('referrals')
      .where('shopId', isEqualTo: uid)
      .where('status', isEqualTo: 'confirmed') // <--- THE KEY DIFFERENCE
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

class MyOrdersScreen extends ConsumerWidget {
  const MyOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(shopOrdersProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Slightly off-white for depth
      appBar: AppBar(
        title: const Text("Active Orders", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = orders[index];

              // USE THE EXACT SAME WIDGET
              return ReferralListCard(
                data: data,
                onTap: () => showReferralDetails(context, data),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  // --- EMPTY STATE ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
            child: Icon(Icons.inventory_2_outlined, size: 40, color: Colors.green.shade300),
          ),
          const SizedBox(height: 16),
          Text("No active orders", style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
          const SizedBox(height: 8),
          const Text("Accept leads to see them here.", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}