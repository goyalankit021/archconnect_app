import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../orders/screens/my_orders_screen.dart';

final recentActivityProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'arch-connect-database')
      .collection('referrals')
      .where('shopId', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .limit(5)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

class ShopRecentActivity extends ConsumerWidget {
  const ShopRecentActivity({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(recentActivityProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Recent Activity",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyOrdersScreen()),
                );
              },
              child: Text(
                "View All",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // --- SEPARATE ITEMS LIST ---
        activityAsync.when(
          data: (items) {
            if (items.isEmpty) return _buildEmptyState();

            return Column(
              children: items.map((data) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10), // Spacing between cards
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _buildMinimalTile(context, data),
                );
              }).toList(),
            );
          },
          loading: () => const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(strokeWidth: 2),
          )),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }

  // --- COMPACT TILE ---
  Widget _buildMinimalTile(BuildContext context, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';

    IconData icon = Icons.hourglass_top;
    Color color = Colors.orange;
    String statusText = "New Lead";

    if (status == 'confirmed') {
      icon = Icons.check_circle_outline;
      color = Colors.green;
      statusText = "Order Confirmed";
    } else if (status == 'rejected') {
      icon = Icons.cancel_outlined;
      color = Colors.grey;
      statusText = "Pass";
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Added vertical padding
      dense: true,

      // Leading Icon
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: color),
      ),

      // Title
      title: Text(
        data['projectName'] ?? "Unknown Project",
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),

      // Subtitle
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2.0),
        child: Text(
          "$statusText • ${_formatDate(data['createdAt'])}",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ),

      // Trailing Amount (Only if confirmed)
      trailing: (status == 'confirmed' && data['commissionAmount'] != null)
          ? Text(
        "₹${data['commissionAmount']}",
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
      )
          : null,
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Center(
        child: Text("No recent activity", style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inDays == 0) return "Today";
      if (diff.inDays == 1) return "Yesterday";
      return "${date.day}/${date.month}";
    }
    return "";
  }
}