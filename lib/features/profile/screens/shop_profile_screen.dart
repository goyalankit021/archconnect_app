import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/user_provider.dart';
import '../../home/data/shop_repository.dart';
import 'dart:io';
import '../../../core/services/storage_service.dart';

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
  // --- ROBUST EDIT SHEET ---
  void _showEditOverviewSheet(String uid, Map<String, dynamic> data, String currentEmail) {
    // 1. Setup Controllers
    final descCtrl = TextEditingController(text: data['description']);
    final whatsappCtrl = TextEditingController(text: data['whatsapp']);
    final emailCtrl = TextEditingController(text: currentEmail); // <--- NEW CONTROLLER

    // 2. Setup Lists (Copy existing data)
    // We use standard Dart Lists so we can modify them
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
        // StatefulBuilder is CRITICAL here to update the sheet UI when adding tags
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
                // Added scroll view for safety
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

                    // Description
                    TextField(
                      controller: descCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Shop Description",
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // WhatsApp
                    TextField(
                      controller: whatsappCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "WhatsApp Number",
                        prefixIcon: Icon(Icons.message),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // ✅ NEW: Email Field
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: "Email ID", prefixIcon: Icon(Icons.email)),
                    ),
                    const SizedBox(height: 24),

                    // --- CATEGORIES EDITOR ---
                    Text(
                      "Categories",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: categories
                          .map(
                            (cat) => Chip(
                              label: Text(cat),
                              backgroundColor: Colors.green[50],
                              onDeleted: () =>
                                  setSheetState(() => categories.remove(cat)),
                              deleteIconColor: Colors.red,
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
                              hintText: "Add Category (e.g. Tiles)",
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
                            if (categoryInputCtrl.text.isNotEmpty) {
                              setSheetState(() {
                                categories.add(
                                  categoryInputCtrl.text.trim().toLowerCase(),
                                ); // Lowercase for search
                                categoryInputCtrl.clear();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- BRANDS EDITOR ---
                    Text(
                      "Brands Deal In",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: brands
                          .map(
                            (brand) => Chip(
                              label: Text(brand),
                              backgroundColor: Colors.blue[50],
                              onDeleted: () =>
                                  setSheetState(() => brands.remove(brand)),
                              deleteIconColor: Colors.red,
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
                              hintText: "Add Brand (e.g. Kajaria)",
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
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Saving Changes...")),
                          );

                          await ref
                              .read(shopRepositoryProvider)
                              .updateShopOverview(
                                uid: uid,
                                description: descCtrl.text.trim(),
                                whatsapp: whatsappCtrl.text.trim(),
                                categories: categories,
                                // Pass the list
                                brands: brands, // Pass the list
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

  // --- EDIT ADDRESS SHEET ---
  void _showEditAddressSheet(String uid, Map<String, dynamic> data) {
    final address = data['address'] ?? {};

    final streetCtrl = TextEditingController(text: address['street']);
    final cityCtrl = TextEditingController(text: address['city']);
    final stateCtrl = TextEditingController(text: address['state']);
    final pinCtrl = TextEditingController(text: address['pincode']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Edit Shop Address", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Street Address (Multi-line)
              TextField(
                controller: streetCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                    labelText: "Street Address / Landmark",
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Icons.add_road)
                ),
              ),
              const SizedBox(height: 16),

              // City & State
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
              const SizedBox(height: 16),

              // Pincode
              TextField(
                controller: pinCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(labelText: "Pincode", prefixIcon: Icon(Icons.pin_drop), counterText: ""),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updating Address...")));

                    await ref.read(shopRepositoryProvider).updateShopAddress(
                      uid: uid,
                      street: streetCtrl.text.trim(),
                      city: cityCtrl.text.trim(),
                      state: stateCtrl.text.trim(),
                      pincode: pinCtrl.text.trim(),
                    );

                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address Updated!")));
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

  // --- HANDLE PHOTO UPLOAD ---
  Future<void> _handlePhotoUpload(String uid) async {
    // 1. Pick Image (Gallery)
    final file = await ref
        .read(storageServiceProvider)
        .pickImage(fromCamera: false);

    if (file != null) {
      // 2. Show Loading
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Uploading Logo...")));

      try {
        // 3. Upload to Storage
        final url = await ref.read(storageServiceProvider).uploadFile(
            file: file,
            path: 'shops/$uid/profile.jpg'
        );

        if (url != null) {
          // 4. Save URL to Database
          await ref.read(shopRepositoryProvider).updateShopPhoto(uid, url);

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

  @override
  Widget build(BuildContext context) {
    // 1. Get User Auth Data (for UID)
    final userAsync = ref.watch(userProfileStreamProvider);

    return userAsync.when(
      data: (userData) {
        if (userData == null) {
          return const Scaffold(body: Center(child: Text("User not found")));
        }

        final uid = userData['uid'];
        final userEmail = userData['email'] ?? ""; // <--- GET EMAIL FROM USER DATA

        // 2. Get Shop Data (Using the UID)
        final shopAsync = ref.watch(myShopStreamProvider(uid));

        return shopAsync.when(
          data: (shopSnapshot) {
            final shopData = shopSnapshot.data();
            if (shopData == null) {
              return const Scaffold(
                body: Center(child: Text("Shop data missing")),
              );
            }

            // Extract Data
            final name = shopData['name'] ?? "My Shop";
            final city = shopData['address']?['city'] ?? "Location";
            final categories = List<String>.from(shopData['categories'] ?? []);

            return DefaultTabController(
              length: 3,
              child: Scaffold(
                backgroundColor: kBackgroundColor,
                appBar: AppBar(
                  title: const Text("Shop Profile"),
                  backgroundColor: Colors.green[800], // Shop Theme Color
                  foregroundColor: Colors.white,
                  centerTitle: true,
                ),
                body: Column(
                  children: [
                    // --- HEADER ---
                    // --- HEADER (Updated with Clickable Avatar) ---
                    Container(
                      width: double.infinity, // Ensure full width
                      color: Colors.green[800],
                      padding: const EdgeInsets.only(
                        bottom: 30,
                        left: 24,
                        right: 24,
                      ),
                      child: Column(
                        children: [
                          // CLICKABLE AVATAR STACK
                          GestureDetector(
                            onTap: () => _handlePhotoUpload(uid),
                            // <--- TRIGGER UPLOAD
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white,
                                  // Show Network Image if available, else show Icon
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
                                // Camera Badge
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
                          // ✅ NEW: VISIBILITY TOGGLE
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  (shopData['status'] == 'active') ? "SHOP IS ONLINE" : "SHOP IS OFFLINE",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(width: 8),
                                Switch(
                                  value: shopData['status'] == 'active',
                                  activeColor: Colors.white,
                                  activeTrackColor: Colors.greenAccent,
                                  inactiveThumbColor: Colors.grey,
                                  inactiveTrackColor: Colors.white24,
                                  onChanged: (val) async {
                                    // Optimistic update (UI changes instantly, DB follows)
                                    await ref.read(shopRepositoryProvider).updateShopStatus(uid, val);
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
                        ],
                      ),
                    ),

                    // --- CONTENT ---
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildOverviewTab(shopData, uid, userEmail),
                          // Pass UID for edits
                          _buildAddressTab(shopData, uid),
                          _buildOperationsTab(shopData, uid),
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

  Widget _buildOverviewTab(Map<String, dynamic> data, String uid, String email) {
    final categories = List<dynamic>.from(data['categories'] ?? []);
    final commission = data['commissionDefaultPercent'] ?? 0.0; // Default if missing

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ NEW: Commission Badge
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.purple.shade700, Colors.purple.shade500]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                  child: const Icon(Icons.percent, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("My Base Commission", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text("$commission%", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          // About Section
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

          // Contact Info
          _buildInfoTile("Phone", data['phone'] ?? "", Icons.phone),
          _buildInfoTile("Email", email.isNotEmpty ? email : "Not provided", Icons.email_outlined),
          _buildInfoTile(
            "WhatsApp",
            data['whatsapp'] ?? "Not linked",
            Icons.message_outlined,
          ),

          const SizedBox(height: 24),

          // Categories
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

          // Brands (NEW)
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

  Widget _buildAddressTab(Map<String, dynamic> data, String uid) {
    final address = data['address'] ?? {};
    final street = address['street'] ?? "No street address provided";
    final city = address['city'] ?? "";
    final state = address['state'] ?? "";
    final pincode = address['pincode'] ?? "";

    final fullAddress = "$street\n$city, $state - $pincode";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Shop Location", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => _showEditAddressSheet(uid, data),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text("Edit"),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Address Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.store_mall_directory, color: Colors.green, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Registered Address",
                        style: TextStyle(fontSize: 12, color: kTextSecondary, fontWeight: FontWeight.bold),
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

          // Placeholder for Map Integration
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
                Text("Map View Coming Soon", style: TextStyle(color: kTextSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- EDIT HOURS SHEET ---
  void _showEditHoursSheet(String uid, Map<String, dynamic> currentHours) {
    // Helper to format TimeOfDay to String (e.g., "09:00")
    String formatTime(TimeOfDay t) {
      final hour = t.hour.toString().padLeft(2, '0');
      final minute = t.minute.toString().padLeft(2, '0');
      return "$hour:$minute";
    }

    // Helper to pick time
    Future<String?> pickTime(BuildContext context, String? current) async {
      final now = TimeOfDay.now();
      final picked = await showTimePicker(
          context: context,
          initialTime: current != null
              ? TimeOfDay(hour: int.parse(current.split(":")[0]), minute: int.parse(current.split(":")[1]))
              : now
      );
      if (picked != null) return formatTime(picked);
      return null;
    }

    // State for the sheet
    Map<String, dynamic> newHours = Map.from(currentHours);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setSheetState) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Edit Business Hours", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // We simplify to 2 Groups for MVP: Weekdays & Sunday
                    _buildDayRow(context, "Weekdays (Mon-Sat)", "monday", newHours, setSheetState, pickTime),
                    const Divider(),
                    _buildDayRow(context, "Sunday", "sunday", newHours, setSheetState, pickTime),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          // Logic: Copy 'monday' settings to tue-sat for consistency if needed
                          // For now, we save strictly what was edited
                          await ref.read(shopRepositoryProvider).updateBusinessHours(uid: uid, businessHours: newHours);
                        },
                        child: const Text("SAVE HOURS"),
                      ),
                    )
                  ],
                ),
              );
            }
        );
      },
    );
  }

  // Widget for a single day row in the sheet
  Widget _buildDayRow(
      BuildContext context,
      String label,
      String key,
      Map<String, dynamic> hours,
      StateSetter setState,
      Function pickTime
      ) {
    final dayData = hours[key] as Map<String, dynamic>? ?? {"open": "09:00", "close": "20:00"};
    final open = dayData['open'];
    final close = dayData['close'];

    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        TextButton(
          onPressed: () async {
            final t = await pickTime(context, open);
            if (t != null) setState(() => hours[key] = {...dayData, "open": t});
          },
          child: Text(open, style: const TextStyle(fontSize: 16)),
        ),
        const Text("-"),
        TextButton(
          onPressed: () async {
            final t = await pickTime(context, close);
            if (t != null) setState(() => hours[key] = {...dayData, "close": t});
          },
          child: Text(close, style: const TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Future<void> _handleGalleryUpload(String uid) async {
    final file = await ref.read(storageServiceProvider).pickImage(fromCamera: false);
    if (file == null) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploading Image...")));

    // ✅ NEW: Structured Path: shops/{uid}/gallery/image_123.jpg
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'shops/$uid/gallery/img_$timestamp.jpg';

    try {
      final url = await ref.read(storageServiceProvider).uploadFile(file: file, path: path);
      if (url != null) {
        await ref.read(shopRepositoryProvider).addGalleryImage(uid, url);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Image Added!")));
      }
    } catch (e) {
      print(e);
    }
  }

  Widget _buildOperationsTab(Map<String, dynamic> data, String uid) {
    final businessHours = data['businessHours'] as Map<String, dynamic>? ?? {};
    final gallery = List<String>.from(data['galleryImages'] ?? []);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- BUSINESS HOURS ---
          // --- BUSINESS HOURS ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Business Hours", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: kPrimaryColor),
                onPressed: () => _showEditHoursSheet(uid, businessHours),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
            child: Column(
              children: [
                _buildDisplayHourRow("Mon - Sat", businessHours['monday']),
                const Divider(),
                _buildDisplayHourRow("Sunday", businessHours['sunday']),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --- GALLERY ---
          Text("Shop Gallery", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
            itemCount: gallery.length >= 4 ? gallery.length : gallery.length + 1,
            itemBuilder: (context, index) {
              final isLimitReached = gallery.length >= 4;
              // The "Add Button" is the first item
              if (!isLimitReached && index == 0) {
                return GestureDetector(
                  onTap: () => _handleGalleryUpload(uid),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_a_photo, color: Colors.grey),
                        const SizedBox(height: 4),
                        Text("${gallery.length}/4", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              }

              // ✅ LOGIC: Get Image URL
              // If limit not reached, array starts at index-1.
              // If limit reached, array starts at index.
              final url = isLimitReached ? gallery[index] : gallery[index - 1];

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
                      onTap: () async {
                        await ref.read(shopRepositoryProvider).removeGalleryImage(uid, url);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.close, size: 14, color: Colors.red),
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
    // Data might be null, or a map {open:..., close:...}
    final map = data as Map<String, dynamic>?;
    final timeStr = map != null ? "${map['open']} - ${map['close']}" : "Closed";
    final color = map != null ? kTextPrimary : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(timeStr, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
