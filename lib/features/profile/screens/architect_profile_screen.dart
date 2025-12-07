import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/user_provider.dart'; // To get the live user stream

class ArchitectProfileScreen extends ConsumerStatefulWidget {
  const ArchitectProfileScreen({super.key});

  @override
  ConsumerState<ArchitectProfileScreen> createState() => _ArchitectProfileScreenState();
}

class _ArchitectProfileScreenState extends ConsumerState<ArchitectProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileStreamProvider);

    return userAsync.when(
      data: (userData) {
        if (userData == null) return const Scaffold(body: Center(child: Text("User not found")));

        // Extract Data
        final name = userData['name'] ?? "Architect";
        final firmName = userData['firm']?['name'] ?? "Firm Name";
        final isVerified = userData['kycStatus'] == 'verified';
        final isProfileComplete = userData['isProfileComplete'] ?? false;
        final profileUrl = userData['profilePhotoUrl'];

        return DefaultTabController(
          length: 3, // Personal, Bank, KYC
          child: Scaffold(
            backgroundColor: kBackgroundColor,
            appBar: AppBar(
              title: const Text("My Profile"),
              centerTitle: true,
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            body: Column(
              children: [
                // --- 1. THE HEADER SECTION ---
                Container(
                  color: kPrimaryColor,
                  padding: const EdgeInsets.only(bottom: 30, left: 24, right: 24),
                  child: Column(
                    children: [
                      // Profile Pic with Edit Badge
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: profileUrl != null
                                ? NetworkImage(profileUrl)
                                : null,
                            child: profileUrl == null
                                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kPrimaryVariant,
                                shape: BoxShape.circle,
                                border: Border.all(color: kPrimaryColor, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Name & Verified Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isVerified)
                            const Icon(Icons.verified, color: Colors.blue, size: 20)
                          else
                            const Icon(Icons.verified_outlined, color: Colors.white54, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        firmName,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // --- 2. THE WARNING BANNER ---
                if (!isProfileComplete)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    color: Colors.orange.shade50,
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Profile Incomplete",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade900
                                ),
                              ),
                              Text(
                                "Complete KYC & Bank details to unlock withdrawals.",
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange.shade800
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.orange),
                      ],
                    ),
                  ),

                // --- 3. THE TABS ---
                Container(
                  color: Colors.white,
                  child: TabBar(
                    labelColor: kPrimaryColor,
                    unselectedLabelColor: kTextSecondary,
                    indicatorColor: kPrimaryColor,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: "Personal"),
                      Tab(text: "Bank Details"),
                      Tab(text: "KYC Docs"),
                    ],
                  ),
                ),

                // --- 4. THE CONTENT AREA ---
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB A: Personal Info
                      _buildPersonalTab(userData),

                      // TAB B: Bank Info
                      _buildBankTab(userData),

                      // TAB C: KYC Info
                      _buildKycTab(userData),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text("Error: $e"))),
    );
  }

  // --- TAB WIDGETS (Placeholders for now) ---

  Widget _buildPersonalTab(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildInfoTile("Phone Number", data['phone'] ?? "", Icons.phone),
          _buildInfoTile(
              "Email",
              data['email'] ?? "Not provided", // Handles null value gracefully
              Icons.email_outlined
          ),
          _buildInfoTile("City", data['metadata']?['city'] ?? "N/A", Icons.location_city),
          _buildInfoTile("State", data['metadata']?['state'] ?? "N/A", Icons.map),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {}, // TODO: Edit Personal Info
              child: const Text("Edit Personal Details"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankTab(Map<String, dynamic> data) {
    // Note: We will fetch Wallet Data separately in the next step
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No Bank Account Linked"),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {}, // TODO: Open Bank Form
            child: const Text("Add Bank Details"),
          ),
        ],
      ),
    );
  }

  Widget _buildKycTab(Map<String, dynamic> data) {
    final kycStatus = data['kycStatus'] ?? 'pending';

    Color statusColor = Colors.orange;
    if (kycStatus == 'verified') statusColor = Colors.green;
    if (kycStatus == 'rejected') statusColor = Colors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: statusColor),
                const SizedBox(width: 12),
                Text(
                  "Current Status: ${kycStatus.toString().toUpperCase()}",
                  style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text("Required Documents", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),

          _buildUploadCard("Aadhar Card", "Front & Back required"),
          const SizedBox(height: 12),
          _buildUploadCard("PAN Card", "Clear photo required"),

          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {}, // TODO: Trigger File Picker
              child: const Text("Submit for Verification"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: kTextSecondary, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.upload_file, color: kTextSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            child: const Text("Upload"),
          ),
        ],
      ),
    );
  }
}