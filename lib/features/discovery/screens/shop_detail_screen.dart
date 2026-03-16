import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../discovery/data/referral_repository.dart';

class ShopDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> shopData;
  final String shopId;

  const ShopDetailScreen({
    super.key,
    required this.shopData,
    required this.shopId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = shopData['name'] ?? "Unknown Shop";
    final description = shopData['description'] ?? "No description available.";
    final photoUrl = shopData['profilePhotoUrl'];
    final commission = shopData['commissionDefaultPercent'] ?? 0.0;
    final categories = List<String>.from(shopData['categories'] ?? []);
    final brands = List<String>.from(shopData['brands'] ?? []);
    final gallery = List<String>.from(shopData['galleryImages'] ?? []);

    final address = shopData['address'] ?? {};
    final fullAddress = "${address['street'] ?? ''}, ${address['city'] ?? ''}";

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // --- 1. APP BAR WITH IMAGE ---
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: kPrimaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(name, style: const TextStyle(fontSize: 16, shadows: [Shadow(blurRadius: 10, color: Colors.black)])),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  photoUrl != null
                      ? Image.network(photoUrl, fit: BoxFit.cover)
                      : Container(color: Colors.grey, child: const Icon(Icons.store, size: 50, color: Colors.white)),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 2. CONTENT ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // COMMISSION CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [Colors.green.shade700, Colors.green.shade500]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Referral Commission", style: TextStyle(color: Colors.white70, fontSize: 14)),
                            Text("Guaranteed payout", style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                        Text("$commission%", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ABOUT SECTION
                  const Text("About the Shop", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(description, style: TextStyle(color: kTextSecondary, height: 1.5)),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // CONTACT INFO
                  const Text("Contact Info", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildContactButton(
                          icon: Icons.phone,
                          label: "Call Shop",
                          color: Colors.blue,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Phone: ${shopData['phone']}")));
                          }
                      ),
                      const SizedBox(width: 12),
                      _buildContactButton(
                          icon: Icons.message,
                          label: "WhatsApp",
                          color: Colors.green,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("WhatsApp: ${shopData['whatsapp']}")));
                          }
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // BUSINESS HOURS
                  const Text("Working Hours", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildHoursList(shopData['businessHours']),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(child: Text(fullAddress, style: TextStyle(color: kTextSecondary, fontSize: 14))),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // WHAT WE SELL
                  const Text("Products & Brands", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ...categories.map((c) => _buildTag(c, Colors.blue.shade50, Colors.blue.shade800)),
                      ...brands.map((b) => _buildTag(b, Colors.grey.shade100, Colors.grey.shade800)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // GALLERY
                  if (gallery.isNotEmpty) ...[
                    const Text("Gallery", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: gallery.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(gallery[index], width: 120, fit: BoxFit.cover),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // --- 3. BOTTOM ACTION BAR (FIXED FOR RESPONSIVENESS) ---
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              height: 56, // Enforce consistent height
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => _showReferralForm(context, ref),
                child: const Text("REFER A CLIENT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color bg, Color textC) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textC)),
    );
  }

  Widget _buildContactButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHoursList(dynamic businessHours) {
    final hours = businessHours as Map<String, dynamic>? ?? {};
    if (hours.isEmpty) return const Text("Hours not updated", style: TextStyle(color: Colors.grey));

    String getRange(String day) {
      final d = hours[day];
      if (d == null) return "Closed";
      return "${d['open']} - ${d['close']}";
    }

    return Column(
      children: [
        _buildHourRow("Mon - Sat", getRange("monday")),
        const SizedBox(height: 8),
        _buildHourRow("Sunday", getRange("sunday"), isHighlight: true),
      ],
    );
  }

  Widget _buildHourRow(String day, String time, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(day, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
        Text(time, style: TextStyle(fontWeight: FontWeight.bold, color: time == "Closed" ? Colors.red : (isHighlight ? Colors.black : Colors.black87))),
      ],
    );
  }

  void _showReferralForm(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final projectCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    String selectedType = "residential";
    bool isLoading = false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: kBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  // --- HEADER ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      border: Border(bottom: BorderSide(color: Colors.black12)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("New Referral", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                  ),

                  // --- FORM BODY ---
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. TRUST ANCHOR
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.store, color: Colors.green),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text("Referral for ${shopData['name']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text("Locked Commission: ${shopData['commissionDefaultPercent']}%", style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // 2. CLIENT DETAILS
                            const Text("Client Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: nameCtrl,
                              decoration: const InputDecoration(labelText: "Client Name", prefixIcon: Icon(Icons.person)),
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: phoneCtrl,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: "Phone Number", prefixIcon: Icon(Icons.phone)),
                              validator: (v) => v!.length < 10 ? "Invalid Phone" : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: addressCtrl,
                              decoration: const InputDecoration(labelText: "Address (Area/City)", prefixIcon: Icon(Icons.location_on)),
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),

                            const SizedBox(height: 24),

                            // 3. PROJECT DETAILS
                            const Text("Project Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: projectCtrl,
                              decoration: const InputDecoration(labelText: "Project Name (e.g. 3BHK Sharma House)", prefixIcon: Icon(Icons.home_work)),
                              validator: (v) => v!.isEmpty ? "Required" : null,
                            ),
                            const SizedBox(height: 16),

                            const Text("Project Type", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: ["residential", "commercial", "renovation"].map((type) {
                                final isSelected = selectedType == type;
                                return ChoiceChip(
                                  label: Text(type[0].toUpperCase() + type.substring(1)),
                                  selected: isSelected,
                                  onSelected: (val) => setSheetState(() => selectedType = type),
                                  selectedColor: kPrimaryColor,
                                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                                  checkmarkColor: Colors.white,
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 24),

                            // 4. NOTES
                            const Text("Notes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: notesCtrl,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                  labelText: "Requirements (e.g. Needs premium tiles)",
                                  alignLabelWithHint: true,
                                  border: OutlineInputBorder()
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- FOOTER BUTTON ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Colors.black12)),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56, // Consistent height
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, elevation: 0),
                        onPressed: isLoading ? null : () async {
                          if (formKey.currentState!.validate()) {
                            setSheetState(() => isLoading = true);
                            FocusScope.of(context).unfocus(); // ✅ FIX: Drop keyboard on submit

                            try {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user == null) throw Exception("User not found");

                              await ref.read(referralRepositoryProvider).createReferral(
                                architectUid: user.uid,
                                architectName: user.displayName ?? "Architect", // ✅ Added
                                shopId: shopId,
                                shopName: shopData['name'] ?? "Unknown Shop",   // ✅ Added
                                commissionPercent: (shopData['commissionDefaultPercent'] ?? 0.0).toDouble(),
                                clientInfo: {
                                  "name": nameCtrl.text.trim(),
                                  "phone": phoneCtrl.text.trim(),
                                  "address": addressCtrl.text.trim(),
                                },
                                projectName: projectCtrl.text.trim(),
                                projectType: selectedType,
                                notes: notesCtrl.text.trim(),
                              );

                              if (!ctx.mounted) return; // ✅ Use 'ctx' (the sheet's context), not 'context' (the screen's context)
                              Navigator.of(ctx).pop(); // ✅ Closes the bottom sheet safely

                              // Show the success message using the main screen's context
                              ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Referral Sent Successfully! 🚀"), backgroundColor: Colors.green)
                              );

                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                            } finally {
                              if (context.mounted) setSheetState(() => isLoading = false);
                            }
                          }
                        },
                        child: isLoading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("CONFIRM & SEND", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  )
                ],
              ),
            );
          }
      ),
    );
  }
}