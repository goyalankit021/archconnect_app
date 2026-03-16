import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/logger_service.dart'; // ✅ Added Logger
import '../../leads/screens/view_leads_screen.dart';
// import '../home/screens/track_status_screen.dart'; // Add this for Architect routing later

final userNotificationsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'arch-connect-database')
      .collection('notifications')
      .where('toUid', isEqualTo: uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) => doc.data()).toList();
  });
});

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifAsync = ref.watch(userNotificationsProvider);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: notifAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) return _buildEmptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = notifications[index];
              return _buildNotificationCard(context, ref, data);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    final bool isRead = data['read'] ?? false;
    final String type = data['type'] ?? 'general';

    return Container(
      decoration: BoxDecoration(
        color: isRead ? Colors.white : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: isRead ? null : Border.all(color: Colors.blue.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _getIconColor(type).withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(_getIcon(type), color: _getIconColor(type), size: 24),
        ),
        title: Text(
          data['title'] ?? "Notification",
          style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(data['body'] ?? "", style: const TextStyle(color: kTextSecondary, fontSize: 12)),
        ),
        trailing: Text(_formatTime(data['createdAt']), style: const TextStyle(fontSize: 10, color: Colors.grey)),
        onTap: () async {
          final String notifId = data['notificationId'];

          // ✅ LOG IT: Debugging notification clicks
          ref.read(loggerServiceProvider).logDebug("User tapped notification: $notifId (Type: $type)");

          final Map<String, dynamic> updates = {
            'clicked': true,
            'clickedAt': FieldValue.serverTimestamp(),
          };

          if (!isRead) {
            updates['read'] = true;
            updates['readAt'] = FieldValue.serverTimestamp();
          }

          try {
            await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'arch-connect-database')
                .collection('notifications')
                .doc(notifId)
                .update(updates);
          } catch (e) {
            ref.read(loggerServiceProvider).logDebug("Error updating notification status: $e");
          }

          // --- FIXED NAVIGATION LOGIC ---
          if (context.mounted) {
            // TODO (V2): Ensure role check before pushing to ViewLeadsScreen
            // Since ViewLeadsScreen is meant for Shops, if an Architect clicks a referral update,
            // they should go to TrackStatusScreen instead.

            if (type == 'referral_initiated') {
              try {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ViewLeadsScreen()),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Screen not found")));
              }
            } else {
              // General notifications (no hard routing yet)
            }
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.notifications_off_outlined, size: 40, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          const Text("No notifications yet", style: TextStyle(color: kTextSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  IconData _getIcon(String type) {
    if (type.contains('referral')) return Icons.person_add_alt_1;
    if (type.contains('money') || type.contains('payout')) return Icons.account_balance_wallet;
    if (type.contains('shop') || type.contains('order')) return Icons.shopping_bag;
    return Icons.notifications;
  }

  Color _getIconColor(String type) {
    if (type.contains('referral')) return Colors.blue;
    if (type.contains('money') || type.contains('payout')) return Colors.green;
    if (type.contains('shop') || type.contains('order')) return Colors.purple;
    return Colors.orange;
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      return "${date.day}/${date.month}";
    }
    return "";
  }
}