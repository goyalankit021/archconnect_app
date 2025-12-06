import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/wallet_card.dart';
import 'shop_selection_screen.dart';

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
                  CircleAvatar(
                    backgroundColor: kSurfaceColor,
                    child: const Icon(Icons.person, color: kPrimaryColor),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 2. The Premium Wallet Card
              // TODO: Fetch real wallet data from Firestore
              const WalletCard(balance: 0.00, totalEarned: 0.00),

              const SizedBox(height: 30),

              // 3. Quick Actions Title
              Text(
                "Quick Actions",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // 4. The "Send Referral" Button (Big & Prominent)
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ShopSelectionScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: kPrimaryColor),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Send New Referral",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "Connect a client to a shop",
                            style: TextStyle(
                              color: kTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: kTextSecondary),
                    ],
                  ),
                ),
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
}