import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/wallet_card.dart';
import '../../profile/screens/architect_profile_screen.dart';
import '../../discovery/screens/shop_discovery_screen.dart';
import '../../notifications/screens/notification_screen.dart';
import '../../wallet/screens/architect_wallet_screen.dart';
import '../../wallet/data/wallet_repository.dart';
import 'track_status_screen.dart';
import '../../discovery/data/referral_repository.dart';
import '../../../scripts/seed_notifications.dart';

class ArchitectHome extends ConsumerWidget {
  final Map<String, dynamic> userData;

  const ArchitectHome({super.key, required this.userData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullName = userData['name'] ?? 'Architect';
    final firstName = fullName.split(' ')[0];

    final walletAsync = ref.watch(walletStreamProvider);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hello, Ar. $firstName",
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Let's grow your network.",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.notifications_outlined,
                          color: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const NotificationScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ArchitectProfileScreen(),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: kSurfaceColor,
                          child: const Icon(Icons.person, color: kPrimaryColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 2. The Premium Wallet Card (NOW WITH REAL DATA)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ArchitectWalletScreen(),
                    ),
                  );
                },
                child: walletAsync.when(
                  data: (data) => WalletCard(
                    balance: (data['balance'] ?? 0).toDouble(),
                    totalEarned: (data['totalEarned'] ?? 0).toDouble(),
                  ),
                  loading: () =>
                      const WalletCard(balance: 0.00, totalEarned: 0.00),
                  // Skeleton state
                  error: (e, s) => const WalletCard(
                    balance: 0.00,
                    totalEarned: 0.00,
                  ), // Error state
                ),
              ),

              const SizedBox(height: 30),

              // 3. Quick Actions
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: "Send New\nReferral",
                      icon: Icons.send_rounded,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ShopDiscoveryScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: "Track\nStatus",
                      icon: Icons.history_edu,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TrackStatusScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 5. Recent Activity (Dynamic!)
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
                      // Navigate to Full List
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TrackStatusScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "View All",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        // Soft grey instead of Primary Blue
                        fontSize: 12,
                        // Slightly smaller
                        fontWeight: FontWeight.w500, // Normal weight, not bold
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // THE DYNAMIC LIST
              ref
                  .watch(recentActivityStreamProvider)
                  .when(
                    data: (recentList) {
                      if (recentList.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              "No referrals sent yet.",
                              style: TextStyle(color: kTextSecondary),
                            ),
                          ),
                        );
                      }
                      // Reuse the logic from TrackStatusScreen (or a simplified version)
                      // For now, let's create a simple list tile for the dashboard
                      return Column(
                        children: recentList
                            .map(
                              (data) => _buildRecentActivityTile(context, data),
                            )
                            .toList(),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => Text("Error loading activity: $e"),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
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
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivityTile(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final clientName = data['clientInfo']?['name'] ?? 'Client';
    final shopName = data['shopName'] ?? 'Shop';
    final status = data['status'] ?? 'pending';

    IconData icon;
    Color color;

    switch (status) {
      case 'confirmed':
        icon = Icons.check_circle_outline;
        color = Colors.blue;
        break;
      case 'completed':
        icon = Icons.monetization_on_outlined;
        color = Colors.green;
        break;
      case 'rejected':
        icon = Icons.cancel_outlined;
        color = Colors.red;
        break;
      default:
        icon = Icons.access_time;
        color = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Referral for $clientName",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "$shopName • ${status.toString().toUpperCase()}",
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
