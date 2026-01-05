import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart'; // Needed for Firebase.app()
import '../../../core/theme/app_theme.dart';
import 'referral_details_sheet.dart'; // Adjust path
import '../widgets/referral_list_card.dart';

// --- PROVIDER ---
final shopLeadsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'arch-connect-database')
      .collection('referrals')
      .where('shopId', isEqualTo: uid)
      .where('status', whereIn: ['pending', 'rejected'])
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

class ViewLeadsScreen extends ConsumerWidget {
  const ViewLeadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(shopLeadsProvider);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Incoming Leads", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: leadsAsync.when(
        data: (leads) {
          if (leads.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: leads.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final data = leads[index];

              // USE THE SHARED WIDGET
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No leads yet", style: TextStyle(color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  // --- HELPER: Date Display ---
  Widget _buildDateBadge(dynamic timestamp) {
    // Simple date formatter
    String text = "Today";
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      text = "${date.day}/${date.month}";
    }

    return Text(
      text,
      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
    );
  }

  Widget _buildRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87))),
      ],
    );
  }

  // --- HELPER: Status Badge ---
  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5
        ),
      ),
    );
  }
}