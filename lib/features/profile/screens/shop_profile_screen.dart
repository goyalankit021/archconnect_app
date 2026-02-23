import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/user_provider.dart';
import '../../auth/data/user_repository.dart';
import '../../home/data/shop_repository.dart';
import '../../../core/services/storage_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'terms_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../../auth/screens/login_screen.dart';

// 1. PROVIDER FOR SHOP DATA
final myShopStreamProvider =
    StreamProvider.family<DocumentSnapshot<Map<String, dynamic>>, String>((
      ref,
      uid,
    ) {
      return ref.read(shopRepositoryProvider).getMyShopStream(uid);
    });

class ShopProfileScreen extends ConsumerStatefulWidget {
  const ShopProfileScreen({super.key});

  @override
  ConsumerState<ShopProfileScreen> createState() => _ShopProfileScreenState();
}

class _ShopProfileScreenState extends ConsumerState<ShopProfileScreen> {
  // --- HANDLE KYC UPLOAD (Unified Logic) ---
  Future<void> _handleKycUpload(String uid, String docType) async {
    // docType: 'shopBoard' or 'gst'
    final file = await ref
        .read(storageServiceProvider)
        .pickImage(fromCamera: false);
    if (file == null) return;

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Uploading Document...")));

    try {
      // 1. Storage Path: Unified with Architects
      // Path: users/{uid}/kyc/{docType}.jpg
      final path = 'users/$uid/kyc/$docType.jpg';

      final url = await ref
          .read(storageServiceProvider)
          .uploadFile(file: file, path: path);

      if (url != null) {
        // 2. Update DB: Use the existing UserRepository function
        // This updates the 'users' collection
        await ref
            .read(userRepositoryProvider)
            .uploadKycDocument(uid: uid, docType: docType, url: url);

        // ✅ TODO: Trigger Notification to Admin Panel
        // Future feature: Send FCM or create a 'notifications' doc for Admin
        // print("TODO: Notify Admin about new KYC doc from $uid");

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Document Uploaded!")));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload Error: $e")));
    }
  }

  // --- 3. REDESIGNED KYC TAB ---
  Widget _buildKycTab(Map<String, dynamic> userData, String uid, String status) {
    final docs = userData['kycDocuments'] as Map<String, dynamic>? ?? {};
    final shopBoardUrl = docs['shopBoard'];
    final gstUrl = docs['gst'];

    // Lock if verified (Cannot edit anymore)
    final isLocked = status == 'verified';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Verification Documents", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text("Upload clear photos to enable your account.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 24),

          // 1. Shop Board
          _buildPrettyKycCard(
            title: "Shop Board Photo",
            subtitle: "Front view with name visible",
            uploadedUrl: shopBoardUrl,
            status: status,
            onTap: isLocked ? null : () => _handleKycUpload(uid, 'shopBoard'),
          ),

          const SizedBox(height: 16),

          // 2. GST / Proof
          _buildPrettyKycCard(
            title: "Business Proof (GST)",
            subtitle: "Government registration doc",
            uploadedUrl: gstUrl,
            status: status,
            onTap: isLocked ? null : () => _handleKycUpload(uid, 'gst'),
          ),
        ],
      ),
    );
  }

  // --- PRETTY KYC CARD ---
  Widget _buildPrettyKycCard({
    required String title,
    required String subtitle,
    String? uploadedUrl,
    required String status,
    VoidCallback? onTap,
  }) {
    Color iconColor = Colors.grey;
    IconData icon = Icons.cloud_upload_outlined;

    if (uploadedUrl != null) {
      if (status == 'verified') {
        icon = Icons.check_circle;
        iconColor = Colors.green;
      } else if (status == 'verification_pending') {
        icon = Icons.hourglass_top; // Show it's waiting
        iconColor = Colors.blue;
      } else if (status == 'rejected') {
        icon = Icons.error;
        iconColor = Colors.red;
      } else {
        // Just uploaded locally but not handled yet
        icon = Icons.check_circle_outline;
        iconColor = Colors.orange;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(Icons.description, color: iconColor, size: 20),
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            trailing: IconButton(
              icon: Icon(icon, color: iconColor),
              onPressed: onTap,
            ),
            onTap: onTap,
          ),

          // Show Image Preview if exists
          if (uploadedUrl != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  uploadedUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 180,
                      color: Colors.grey.shade100,
                      child: const Center(child: Icon(Icons.image, color: Colors.grey)),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- HELPER: ALERT BANNER ---
  Widget _buildAlertBanner(Color color, IconData icon, String title, String subtitle) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. HANDLE PHOTO UPLOAD (FIXED) ---
  Future<void> _handlePhotoUpload(String uid) async {
    final file = await ref
        .read(storageServiceProvider)
        .pickImage(fromCamera: false);

    if (file != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Uploading Logo...")));

      try {
        // Upload to Storage
        final url = await ref
            .read(storageServiceProvider)
            .uploadFile(file: file, path: 'users/$uid/profile.jpg');

        if (url != null) {
          // Update Database
          await ref.read(shopRepositoryProvider).updateShopPhoto(uid, url);
          await ref.read(userRepositoryProvider).updateProfilePhoto(uid, url);

          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Shop Logo Updated!")));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  // --- 2. SETTINGS SHEET ---
  void _showSettingsSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              _buildSettingsTile(
                Icons.support_agent,
                Colors.blue,
                "Contact Support",
                () {
                  Navigator.pop(context);
                  _showContactSupportDialog();
                },
              ),

              _buildSettingsTile(Icons.share, Colors.orange, "Share App", () {
                Navigator.pop(context);
                Share.share(
                  'Join ArchConnect! Grow your business with verified Architects.\n\nDownload: https://archconnect.app',
                );
              }),

              _buildSettingsTile(
                Icons.description,
                Colors.purple,
                "Terms & Services",
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsScreen(),
                    ),
                  );
                },
              ),

              Divider(height: 24, thickness: 1, color: Colors.grey.shade300),

              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout, color: Colors.red, size: 20),
                ),
                title: const Text(
                  "Logout",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    Color color,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }

  // --- 3. CONTACT SUPPORT DIALOG (FIXED EMAIL) ---
  void _showContactSupportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Center(
          child: Column(
            children: [
              Icon(Icons.headset_mic, size: 40, color: kPrimaryColor),
              SizedBox(height: 12),
              Text(
                "Contact Support",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "We are here to help! Reach out via:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            _buildContactTile(
              icon: Icons.phone,
              color: Colors.green,
              title: "Call Us",
              subtitle: "+91 80599 04727",
              onTap: () async {
                final Uri launchUri = Uri(scheme: 'tel', path: '+918059904727');
                if (await canLaunchUrl(launchUri)) await launchUrl(launchUri);
              },
            ),
            const SizedBox(height: 12),

            // ✅ FIXED EMAIL LOGIC
            _buildContactTile(
              icon: Icons.email,
              color: Colors.blue,
              title: "Email Us",
              subtitle: "archconnect021@gmail.com",
              onTap: () async {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'archconnect021@gmail.com',
                );

                if (await canLaunchUrl(emailLaunchUri)) {
                  await launchUrl(emailLaunchUri);
                } else {
                  // Fallback for Android 11+ if manifest not updated, trying generic view
                  try {
                    await launchUrl(
                      emailLaunchUri,
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("No email app found")),
                    );
                  }
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CLOSE", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- 4. RESTORED: Edit Overview Sheet ---
  void _showEditOverviewSheet(
    String uid,
    Map<String, dynamic> data,
    String currentEmail,
  ) {
    final descCtrl = TextEditingController(text: data['description']);
    final whatsappCtrl = TextEditingController(text: data['whatsapp']);
    final emailCtrl = TextEditingController(text: currentEmail);

    List<String> categories = List<String>.from(data['categories'] ?? []);
    List<String> brands = List<String>.from(data['brands'] ?? []);

    final categoryInputCtrl = TextEditingController();
    final brandInputCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Edit Shop Overview",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Shop Description",
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: whatsappCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "WhatsApp Number",
                        prefixIcon: Icon(Icons.message),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email ID",
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Categories
                    Text(
                      "Categories",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTextSecondary,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: categories
                          .map(
                            (cat) => Chip(
                              label: Text(cat),
                              backgroundColor: Colors.green[50],
                              onDeleted: () =>
                                  setSheetState(() => categories.remove(cat)),
                            ),
                          )
                          .toList(),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: categoryInputCtrl,
                            decoration: const InputDecoration(
                              hintText: "Add Category",
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.green,
                          ),
                          onPressed: () {
                            if (categoryInputCtrl.text.isNotEmpty)
                              setSheetState(() {
                                categories.add(
                                  categoryInputCtrl.text.trim().toLowerCase(),
                                );
                                categoryInputCtrl.clear();
                              });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Brands
                    Text(
                      "Brands Deal In",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTextSecondary,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: brands
                          .map(
                            (brand) => Chip(
                              label: Text(brand),
                              backgroundColor: Colors.blue[50],
                              onDeleted: () =>
                                  setSheetState(() => brands.remove(brand)),
                            ),
                          )
                          .toList(),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: brandInputCtrl,
                            decoration: const InputDecoration(
                              hintText: "Add Brand",
                              isDense: true,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle,
                            color: Colors.blue,
                          ),
                          onPressed: () {
                            if (brandInputCtrl.text.isNotEmpty) {
                              setSheetState(() {
                                brands.add(brandInputCtrl.text.trim());
                                brandInputCtrl.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await ref
                              .read(shopRepositoryProvider)
                              .updateShopOverview(
                                uid: uid,
                                description: descCtrl.text.trim(),
                                whatsapp: whatsappCtrl.text.trim(),
                                categories: categories,
                                brands: brands,
                                email: emailCtrl.text.trim(),
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Shop Info Updated!")),
                          );
                        },
                        child: const Text("SAVE CHANGES"),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 5. RESTORED: Edit Address Sheet ---
  void _showEditAddressSheet(String uid, Map<String, dynamic> data) {
    final address = data['address'] ?? {};
    final streetCtrl = TextEditingController(text: address['street']);
    final cityCtrl = TextEditingController(text: address['city']);
    final stateCtrl = TextEditingController(text: address['state']);
    final pinCtrl = TextEditingController(text: address['pincode']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit Shop Address",
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: streetCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: "Street Address",
                  prefixIcon: Icon(Icons.add_road),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(
                        labelText: "City",
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: stateCtrl,
                      decoration: const InputDecoration(
                        labelText: "State",
                        prefixIcon: Icon(Icons.map),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: "Pincode",
                  prefixIcon: Icon(Icons.pin_drop),
                  counterText: "",
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await ref
                        .read(shopRepositoryProvider)
                        .updateShopAddress(
                          uid: uid,
                          street: streetCtrl.text.trim(),
                          city: cityCtrl.text.trim(),
                          state: stateCtrl.text.trim(),
                          pincode: pinCtrl.text.trim(),
                        );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Address Updated!")),
                    );
                  },
                  child: const Text("SAVE ADDRESS"),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // --- 6. RESTORED: Edit Hours Sheet ---
  void _showEditHoursSheet(String uid, Map<String, dynamic> currentHours) {
    String formatTime(TimeOfDay t) =>
        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
    Future<String?> pickTime(BuildContext context, String? current) async {
      final picked = await showTimePicker(
        context: context,
        initialTime: current != null
            ? TimeOfDay(
                hour: int.parse(current.split(":")[0]),
                minute: int.parse(current.split(":")[1]),
              )
            : TimeOfDay.now(),
      );
      return picked != null ? formatTime(picked) : null;
    }

    Map<String, dynamic> newHours = Map.from(currentHours);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Edit Business Hours",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDayRow(
                    context,
                    "Weekdays",
                    "monday",
                    newHours,
                    setSheetState,
                    pickTime,
                  ),
                  const Divider(),
                  _buildDayRow(
                    context,
                    "Sunday",
                    "sunday",
                    newHours,
                    setSheetState,
                    pickTime,
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await ref
                            .read(shopRepositoryProvider)
                            .updateBusinessHours(
                              uid: uid,
                              businessHours: newHours,
                            );
                      },
                      child: const Text("SAVE HOURS"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDayRow(
    BuildContext context,
    String label,
    String key,
    Map<String, dynamic> hours,
    StateSetter setState,
    Function pickTime,
  ) {
    final dayData =
        hours[key] as Map<String, dynamic>? ??
        {"open": "09:00", "close": "20:00"};
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        TextButton(
          onPressed: () async {
            final t = await pickTime(context, dayData['open']);
            if (t != null) setState(() => hours[key] = {...dayData, "open": t});
          },
          child: Text(dayData['open'], style: const TextStyle(fontSize: 16)),
        ),
        const Text("-"),
        TextButton(
          onPressed: () async {
            final t = await pickTime(context, dayData['close']);
            if (t != null)
              setState(() => hours[key] = {...dayData, "close": t});
          },
          child: Text(dayData['close'], style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  // --- 7. RESTORED: Gallery Upload ---
  Future<void> _handleGalleryUpload(String uid) async {
    final file = await ref
        .read(storageServiceProvider)
        .pickImage(fromCamera: false);
    if (file == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Uploading Image...")));
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    try {
      final url = await ref
          .read(storageServiceProvider)
          .uploadFile(
            file: file,
            path: 'shops/$uid/gallery/img_$timestamp.jpg',
          );
      if (url != null) {
        await ref.read(shopRepositoryProvider).addGalleryImage(uid, url);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Image Added!")));
      }
    } catch (e) {
      print(e);
    }
  }

  // --- 8. MAIN BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileStreamProvider);

    return userAsync.when(
      data: (userData) {
        if (userData == null)
          return const Scaffold(body: Center(child: Text("User not found")));

        final uid = userData['uid'];
        final userEmail = userData['email'] ?? "";
        final kycStatus = userData['kycStatus'] ?? 'pending';
        final isProfileComplete = userData['isProfileComplete'] ?? false;

        final shopAsync = ref.watch(myShopStreamProvider(uid));

        return shopAsync.when(
          data: (shopSnapshot) {
            final shopData = shopSnapshot.data() ?? {};
            final name = shopData['name'] ?? "My Shop";
            final city = shopData['address']?['city'] ?? "Location";

            return DefaultTabController(
              length: 4,
              child: Scaffold(
                backgroundColor: kBackgroundColor,
                appBar: AppBar(
                  title: const Text("Shop Profile"),
                  backgroundColor: Colors.green[800],
                  foregroundColor: Colors.white,
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: _showSettingsSheet,
                    ),
                  ],
                ),
                body: Column(
                  children: [
                    // --- HEADER ---
                    Container(
                      width: double.infinity,
                      color: Colors.green[800],
                      padding: const EdgeInsets.only(
                        bottom: 30,
                        left: 24,
                        right: 24,
                      ),
                      child: Column(
                        children: [
                          // ✅ UPDATED STATUS BANNERS
                          if (kycStatus == 'pending')
                            _buildAlertBanner(
                              Colors.orange,
                              Icons.cloud_upload,
                              "KYC Pending",
                              "Upload documents to get verified.",
                            )
                          else if (!isProfileComplete)
                            _buildAlertBanner(
                              Colors.redAccent,
                              Icons.edit_note,
                              "Setup Required",
                              "Complete your profile details.",
                            )
                          else if (kycStatus == 'verification_pending')
                            _buildAlertBanner(
                              Colors.blue,
                              Icons.hourglass_top,
                              "Under Review",
                              "Admin is verifying your documents.",
                            )
                          else if (kycStatus == 'rejected')
                            _buildAlertBanner(
                              Colors.red,
                              Icons.error_outline,
                              "KYC Rejected",
                              "Please re-upload valid documents.",
                            )
                          else if (kycStatus == 'verified')
                            _buildAlertBanner(
                              Colors.green,
                              Icons.verified,
                              "Verified Shop",
                              "You are fully approved!",
                            ),

                          // AVATAR
                          GestureDetector(
                            onTap: () => _handlePhotoUpload(uid),
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white,
                                  backgroundImage:
                                      shopData['profilePhotoUrl'] != null
                                      ? NetworkImage(
                                          shopData['profilePhotoUrl'],
                                        )
                                      : null,
                                  child: shopData['profilePhotoUrl'] == null
                                      ? const Icon(
                                          Icons.storefront,
                                          size: 40,
                                          color: Colors.green,
                                        )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.green,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 14,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            city,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // STATUS TOGGLE
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  (shopData['status'] == 'active')
                                      ? "SHOP IS ONLINE"
                                      : "SHOP IS OFFLINE",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: shopData['status'] == 'active',
                                  activeColor: Colors.white,
                                  activeTrackColor: Colors.greenAccent,
                                  inactiveThumbColor: Colors.grey,
                                  inactiveTrackColor: Colors.white24,
                                  onChanged: (val) async {
                                    await ref
                                        .read(shopRepositoryProvider)
                                        .updateShopStatus(uid, val);
                                  },
                                ),
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
                        labelColor: Colors.green[800],
                        unselectedLabelColor: kTextSecondary,
                        indicatorColor: Colors.green[800],
                        tabs: const [
                          Tab(text: "Overview"),
                          Tab(text: "Address"),
                          Tab(text: "Operations"),
                          Tab(text: "KYC Docs"),
                        ],
                      ),
                    ),

                    // --- CONTENT ---
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildOverviewTab(shopData, uid, userEmail),
                          _buildAddressTab(shopData, uid),
                          _buildOperationsTab(shopData, uid),
                          _buildKycTab(userData, uid, kycStatus),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, s) => Scaffold(body: Center(child: Text("Error: $e"))),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text("Error: $e"))),
    );
  }

  // --- 9. RESTORED: Tab Content Builders ---
  Widget _buildOverviewTab(
    Map<String, dynamic> data,
    String uid,
    String email,
  ) {
    final categories = List<dynamic>.from(data['categories'] ?? []);
    final commission = data['commissionDefaultPercent'] ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Commission Badge
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade700, Colors.purple.shade500],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.percent,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "My Base Commission",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      "$commission%",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "About",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: kPrimaryColor),
                onPressed: () => _showEditOverviewSheet(uid, data, email),
              ),
            ],
          ),
          Text(
            data['description'] ?? "No description provided.",
            style: TextStyle(color: kTextSecondary, height: 1.5),
          ),
          const SizedBox(height: 24),

          _buildInfoTile("Phone", data['phone'] ?? "", Icons.phone),
          _buildInfoTile(
            "Email",
            email.isNotEmpty ? email : "Not provided",
            Icons.email_outlined,
          ),
          _buildInfoTile(
            "WhatsApp",
            data['whatsapp'] ?? "Not linked",
            Icons.message_outlined,
          ),

          const SizedBox(height: 24),
          Text(
            "Categories",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: categories
                .map(
                  (cat) => Chip(
                    label: Text(
                      cat.toString().toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Colors.green[50],
                    labelStyle: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                .toList(),
          ),

          const SizedBox(height: 24),
          Text(
            "Brands",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: (data['brands'] as List<dynamic>? ?? [])
                .map(
                  (brand) => Chip(
                    label: Text(
                      brand.toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: Colors.blue[50],
                    labelStyle: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressTab(Map<String, dynamic> data, String uid) {
    final address = data['address'] ?? {};
    final fullAddress =
        "${address['street'] ?? 'No street'}\n${address['city'] ?? ''}, ${address['state'] ?? ''} - ${address['pincode'] ?? ''}";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Shop Location",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () => _showEditAddressSheet(uid, data),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text("Edit"),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.store_mall_directory,
                  color: Colors.green,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Registered Address",
                        style: TextStyle(
                          fontSize: 12,
                          color: kTextSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        fullAddress,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  "Map View Coming Soon",
                  style: TextStyle(color: kTextSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsTab(Map<String, dynamic> data, String uid) {
    final businessHours = data['businessHours'] as Map<String, dynamic>? ?? {};
    final gallery = List<String>.from(data['galleryImages'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Business Hours",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: kPrimaryColor),
                onPressed: () => _showEditHoursSheet(uid, businessHours),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildDisplayHourRow("Mon - Sat", businessHours['monday']),
                const Divider(),
                _buildDisplayHourRow("Sunday", businessHours['sunday']),
              ],
            ),
          ),
          const SizedBox(height: 30),

          Text(
            "Shop Gallery",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: gallery.length >= 4
                ? gallery.length
                : gallery.length + 1,
            itemBuilder: (context, index) {
              if (gallery.length < 4 && index == 0) {
                return GestureDetector(
                  onTap: () => _handleGalleryUpload(uid),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo, color: Colors.grey),
                        const SizedBox(height: 4),
                        Text(
                          "${gallery.length}/4",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final url = (gallery.length < 4)
                  ? gallery[index - 1]
                  : gallery[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(url, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => ref
                          .read(shopRepositoryProvider)
                          .removeGalleryImage(uid, url),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayHourRow(String label, dynamic data) {
    final map = data as Map<String, dynamic>?;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            map != null ? "${map['open']} - ${map['close']}" : "Closed",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: map != null ? kTextPrimary : Colors.red,
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
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
