import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Required for Logout
import '../../../core/services/storage_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/user_provider.dart';
import '../../auth/data/user_repository.dart';
import '../../auth/screens/login_screen.dart'; // Required for Redirect
import 'bank_details_form.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final walletStreamProvider = StreamProvider.family<DocumentSnapshot, String>((ref, uid) {
  return ref.read(userRepositoryProvider).getWalletStream(uid);
});

class ArchitectProfileScreen extends ConsumerStatefulWidget {
  const ArchitectProfileScreen({super.key});

  @override
  ConsumerState<ArchitectProfileScreen> createState() => _ArchitectProfileScreenState();
}

class _ArchitectProfileScreenState extends ConsumerState<ArchitectProfileScreen> {

  // --- UPLOAD LOGIC (Kept exactly as is) ---
  Future<void> _handleUpload({
    required String uid,
    required String docType,
  }) async {
    final source = await showModalBottomSheet<bool>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, false),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final File? file = await ref.read(storageServiceProvider).pickImage(fromCamera: source);
    if (file == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Uploading... Please wait.")),
    );

    try {
      String path;
      if (docType == 'profile') {
        path = 'users/$uid/profile.jpg';
      } else {
        path = 'users/$uid/kyc/$docType.jpg';
      }

      final url = await ref.read(storageServiceProvider).uploadFile(file: file, path: path);

      if (url != null) {
        if (docType == 'profile') {
          await ref.read(userRepositoryProvider).updateProfilePhoto(uid, url);
        } else {
          await ref.read(userRepositoryProvider).uploadKycDocument(
            uid: uid,
            docType: docType,
            url: url,
          );
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Upload Successful!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload Failed: $e")),
      );
    }
  }

  // --- NEW: SETTINGS SHEET LOGIC ---
  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),

              // 1. Support
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle), child: const Icon(Icons.support_agent, color: Colors.blue, size: 20)),
                title: const Text("Contact Support", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Emailing support...")));
                },
              ),

              // 2. Share
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.shade50, shape: BoxShape.circle), child: const Icon(Icons.share, color: Colors.orange, size: 20)),
                title: const Text("Share App", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening Share Menu...")));
                },
              ),

              // 3. Terms
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purple.shade50, shape: BoxShape.circle), child: const Icon(Icons.description, color: Colors.purple, size: 20)),
                title: const Text("Terms & Conditions", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onTap: () => Navigator.pop(context),
              ),

              // ✅ FIX: Removed SizedBox, changed color to shade300 (Visible but Soft)
              Divider(height: 24, thickness: 1, color: Colors.grey.shade300),

              // 4. LOGOUT
              ListTile(
                visualDensity: VisualDensity.compact,
                // Moved padding slightly to align perfectly with the divider
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: const Icon(Icons.logout, color: Colors.red, size: 20)),
                title: const Text("Log Out", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                onTap: () async {
                  Navigator.pop(context);
                  // ✅ STEP 1: CLEAR ZOMBIE DATA
                  // This forces the app to fetch fresh data next time, no matter what.
                  ref.invalidate(userProfileStreamProvider);
                  ref.invalidate(walletStreamProvider); // Clear wallet cache too
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (Route<dynamic> route) => false,
                    );
                  }
                },
              ),
              const SizedBox(height: 8), // Bottom padding
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileStreamProvider);

    return userAsync.when(
      data: (userData) {
        if (userData == null) return const Scaffold(body: Center(child: Text("User not found")));

        final uid = userData['uid'];
        final name = userData['name'] ?? "Architect";
        final firmName = userData['firm']?['name'] ?? "Firm Name";
        final isVerified = userData['kycStatus'] == 'verified';
        final isProfileComplete = userData['isProfileComplete'] ?? false;
        final profileUrl = userData['profilePhotoUrl'];

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: kBackgroundColor,
            appBar: AppBar(
              title: const Text("My Profile"),
              centerTitle: true,
              backgroundColor: kPrimaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              // ✅ ADDED: SETTINGS ACTION
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: _showSettingsSheet, // Opens the new menu
                ),
              ],
            ),
            body: Column(
              children: [
                // --- HEADER ---
                Container(
                  color: kPrimaryColor,
                  padding: const EdgeInsets.only(bottom: 30, left: 24, right: 24),
                  child: Column(
                    children: [
                      // Profile Pic
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white,
                            backgroundImage: profileUrl != null ? NetworkImage(profileUrl) : null,
                            child: profileUrl == null
                                ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _handleUpload(uid: uid, docType: 'profile'),
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(width: 8),
                          Icon(isVerified ? Icons.verified : Icons.verified_outlined, color: isVerified ? Colors.blue : Colors.white54, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(firmName, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14)),
                    ],
                  ),
                ),

                // --- BANNER ---
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
                              Text("Profile Incomplete", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900)),
                              Text("Complete KYC & Bank details to unlock withdrawals.", style: TextStyle(fontSize: 12, color: Colors.orange.shade800)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // --- TABS ---
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

                Expanded(
                  child: TabBarView(
                    children: [
                      _buildPersonalTab(userData),
                      _buildBankTab(userData),
                      _buildKycTab(userData, uid),
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

  // --- EXISTING TABS (Kept Exactly as is) ---
  Widget _buildPersonalTab(Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildInfoTile("Phone Number", data['phone'] ?? "", Icons.phone),
          _buildInfoTile("Email", data['email'] ?? "Not provided", Icons.email_outlined),
          _buildInfoTile("City", data['metadata']?['city'] ?? "N/A", Icons.location_city),
          _buildInfoTile("State", data['metadata']?['state'] ?? "N/A", Icons.map),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showEditPersonalSheet(data),
              child: const Text("Edit Personal Details"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankTab(Map<String, dynamic> userData) {
    final uid = userData['uid'];
    final walletAsync = ref.watch(walletStreamProvider(uid));

    return walletAsync.when(
      data: (snapshot) {
        final walletData = snapshot.data() as Map<String, dynamic>?;
        final bankDetails = walletData?['bankDetails'] as Map<String, dynamic>?;

        if (bankDetails == null || bankDetails['accountNumber'] == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.account_balance, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text("No Bank Account Linked"),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BankDetailsForm()),
                    );
                  },
                  child: const Text("Add Bank Details"),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade600]),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.account_balance, color: Colors.white),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                          child: const Text("PRIMARY", style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      bankDetails['bankName']?.toString().toUpperCase() ?? "BANK NAME",
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bankDetails['accountNumber'] ?? "****",
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("IFSC Code", style: TextStyle(color: Colors.white70, fontSize: 10)),
                            Text(bankDetails['ifsc'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("UPI ID", style: TextStyle(color: Colors.white70, fontSize: 10)),
                            Text(bankDetails['upi'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BankDetailsForm()),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text("Update Details"),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text("Error loading wallet: $e")),
    );
  }

  Widget _buildKycTab(Map<String, dynamic> data, String uid) {
    final kycStatus = data['kycStatus'] ?? 'pending';
    final docs = data['kycDocuments'] ?? {};
    final aadharUrl = docs['aadhar'];
    final panUrl = docs['pan'];

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
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: statusColor.withOpacity(0.3))),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: statusColor),
                const SizedBox(width: 12),
                Text("Current Status: ${kycStatus.toString().toUpperCase()}", style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text("Required Documents", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),

          _buildUploadCard(
            title: "Aadhar Card",
            subtitle: aadharUrl != null ? "Document Uploaded" : "Front & Back required",
            isUploaded: aadharUrl != null,
            onTap: () => _handleUpload(uid: uid, docType: 'aadhar'),
          ),
          const SizedBox(height: 12),
          _buildUploadCard(
            title: "PAN Card",
            subtitle: panUrl != null ? "Document Uploaded" : "Clear photo required",
            isUploaded: panUrl != null,
            onTap: () => _handleUpload(uid: uid, docType: 'pan'),
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
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: kTextSecondary, size: 20)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))]),
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required bool isUploaded,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: isUploaded ? Colors.green : Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(isUploaded ? Icons.check_circle : Icons.upload_file, color: isUploaded ? Colors.green : kTextSecondary),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey))])),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: isUploaded ? Colors.green : kPrimaryColor),
            child: Text(isUploaded ? "Change" : "Upload"),
          ),
        ],
      ),
    );
  }

  void _showEditPersonalSheet(Map<String, dynamic> userData) {
    final uid = userData['uid'];
    final nameCtrl = TextEditingController(text: userData['name']);
    final firmCtrl = TextEditingController(text: userData['firm']?['name']);
    final emailCtrl = TextEditingController(text: userData['email']);
    final cityCtrl = TextEditingController(text: userData['metadata']?['city']);
    final stateCtrl = TextEditingController(text: userData['metadata']?['state']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  "Edit Personal Details",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 20),

              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: firmCtrl,
                decoration: const InputDecoration(labelText: "Firm Name", prefixIcon: Icon(Icons.business)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email Address", prefixIcon: Icon(Icons.email)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(labelText: "City", prefixIcon: Icon(Icons.location_city)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: stateCtrl,
                      decoration: const InputDecoration(labelText: "State", prefixIcon: Icon(Icons.map)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Updating Profile...")),
                      );

                      await ref.read(userRepositoryProvider).updatePersonalDetails(
                        uid: uid,
                        name: nameCtrl.text.trim(),
                        firmName: firmCtrl.text.trim(),
                        email: emailCtrl.text.trim(),
                        city: cityCtrl.text.trim(),
                        state: stateCtrl.text.trim(),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Profile Updated Successfully!")),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e")),
                      );
                    }
                  },
                  child: const Text("SAVE CHANGES"),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}