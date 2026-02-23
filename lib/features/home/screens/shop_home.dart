import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../core/theme/app_theme.dart';
import '../../orders/screens/my_orders_screen.dart';
import '../../profile/screens/shop_profile_screen.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../leads/screens/view_leads_screen.dart';
import '../../dashboard/widgets/shop_recent_activity.dart';
import '../../wallet/screens/shop_wallet_screen.dart';

// --- PROVIDER: FETCH REAL STATS ---
final shopStatsProvider = StreamProvider.autoDispose<DocumentSnapshot>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instanceFor(
    app: Firebase.app(),
    databaseId: 'arch-connect-database',
  ).collection('shop_stats').doc(uid).snapshots();
});

class ShopHome extends ConsumerWidget {
  final Map<String, dynamic> userData;

  const ShopHome({super.key, required this.userData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(shopStatsProvider);

    final ownerName = userData['name'] ?? 'Partner';
    final firstName = ownerName.split(' ')[0];
    final firmName = userData['firm']?['name'] ?? 'My Shop';

    String getShopInitials(String name) {
      if (name.isEmpty) return "S";
      List<String> words = name.trim().split(' ');
      if (words.length > 1) return "${words[0][0]}${words[1][0]}".toUpperCase();
      return name[0].toUpperCase();
    }

    final shopInitials = getShopInitials(firmName);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER SECTION ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello, $firstName",
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          firmName,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: kTextSecondary, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen()));
                        },
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopProfileScreen()));
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: CircleAvatar(
                          backgroundColor: Colors.green.shade50,
                          radius: 20,
                          backgroundImage: userData['profilePhotoUrl'] != null ? NetworkImage(userData['profilePhotoUrl']) : null,
                          child: userData['profilePhotoUrl'] == null
                              ? Text(shopInitials, style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 14))
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // --- 2. REVENUE CARD ---
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ShopWalletScreen()));
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade700, Colors.green.shade900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                  ),
                  child: statsAsync.when(
                    data: (snapshot) {
                      final data = snapshot.data() as Map<String, dynamic>? ?? {};
                      final double totalRevenue = (data['totalRevenue'] ?? 0).toDouble();
                      final double totalDue = (data['totalDue'] ?? 0).toDouble();
                      final double totalPaid = (data['totalPaid'] ?? 0).toDouble();

                      String displayRevenue = "₹0";
                      if (totalRevenue >= 10000000) {
                        displayRevenue = "₹${(totalRevenue / 10000000).toStringAsFixed(2)}Cr";
                      } else if (totalRevenue >= 100000) {
                        displayRevenue = "₹${(totalRevenue / 100000).toStringAsFixed(2)}L";
                      } else {
                        displayRevenue = "₹${totalRevenue.toStringAsFixed(0)}";
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Total Revenue", style: TextStyle(color: Colors.white70, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text(displayRevenue, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _buildStatItem("Total Paid", "₹${totalPaid.toStringAsFixed(0)}", Icons.check_circle_outline),
                              Container(height: 30, width: 1, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 20)),
                              _buildStatItem("Payable", "₹${totalDue.toStringAsFixed(0)}", Icons.pending_actions),
                            ],
                          ),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
                    error: (_, __) => const Text("Stats Unavailable", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- 3. QUICK ACTIONS ---
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: "Incoming\nLeads",
                      icon: Icons.assignment_ind_outlined,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ViewLeadsScreen()));
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: "My\nOrders",
                      icon: Icons.inventory_2_outlined,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyOrdersScreen()));
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // --- 4. RECENT ACTIVITY ---
              const ShopRecentActivity(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionCard(BuildContext context, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 16),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}