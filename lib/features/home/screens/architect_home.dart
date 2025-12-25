import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/wallet_card.dart';
import 'shop_selection_screen.dart';
import '../../profile/screens/architect_profile_screen.dart';
import '../../discovery/screens/shop_discovery_screen.dart'; // <--- Import this
import '../../notifications/screens/notification_screen.dart';

// Import the script at the top ToDo Delete this later
import '../../../scripts/seed_notifications.dart';

class ArchitectHome extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ArchitectHome({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    // Extract Name (and handle split logic if needed to show First Name)
    final fullName = userData['name'] ?? 'Architect';
    final firstName = fullName.split(' ')[0];

    return Scaffold(
      backgroundColor: kBackgroundColor,
      // Custom App Bar Area
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Let's grow your network.",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // ✅ NEW: Notification Bell
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationScreen()),
                          );
                        },
                      ),

                      const SizedBox(width: 8), // Small gap

                      // Existing Profile Icon
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ArchitectProfileScreen()),
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

              // 2. The Premium Wallet Card
              // TODO: Fetch real wallet data from Firestore
              const WalletCard(balance: 0.00, totalEarned: 0.00),

              const SizedBox(height: 30),

              // 3. Quick Actions Title
              // --- QUICK ACTIONS ROW ---
              Row(
                children: [
                  // 1. SEND REFERRAL CARD
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: "Send New\nReferral",
                      icon: Icons.send_rounded,
                      color: Colors.blue,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ShopDiscoveryScreen()),
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 16),

                  // 2. TRACK STATUS CARD
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: "Track\nStatus",
                      icon: Icons.history_edu, // Changed icon for variety
                      color: Colors.orange,
                      // Todo Remove this later and uncomment below lines
                      onTap: () async {
                        // TEMPORARY TRIGGER
                        await seedNotifications();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Seed Data Added! Check Bell Icon."))
                        );
                      },
                      // onTap: () {
                      //   // We will build this screen later
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //       const SnackBar(content: Text("Tracking Screen Coming Soon!"))
                      //   );
                      // },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 5. Recent Activity Placeholder
              Text(
                "Recent Activity",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Center(
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text(
                      "No referrals sent yet.",
                      style: TextStyle(color: kTextSecondary),
                    ),
                  ],
                ),
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
        required VoidCallback onTap, // <--- Add this parameter
      }) {
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
          onTap: onTap, // <--- Use it here
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