import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/shop_repository.dart';

class ShopSelectionScreen extends ConsumerStatefulWidget {
  const ShopSelectionScreen({super.key});

  @override
  ConsumerState<ShopSelectionScreen> createState() => _ShopSelectionScreenState();
}

class _ShopSelectionScreenState extends ConsumerState<ShopSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(allShopsProvider);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Select a Shop"),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: kPrimaryColor,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: "Search by Name or Firm...",
                prefixIcon: const Icon(Icons.search, color: kTextSecondary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // 2. The List
          Expanded(
            child: shopsAsync.when(
              data: (shops) {
                // --- FILTER LOGIC ---
                final filteredShops = shops.where((shop) {
                  final name = (shop['name'] ?? "").toString().toLowerCase();
                  final firm = (shop['firm']?['name'] ?? "").toString().toLowerCase();
                  return name.contains(_searchQuery) || firm.contains(_searchQuery);
                }).toList();

                if (filteredShops.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store_mall_directory_outlined, size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 10),
                        const Text("No shops found matching your search."),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredShops.length,
                  itemBuilder: (context, index) {
                    final shop = filteredShops[index];
                    final shopName = shop['firm']?['name'] ?? "Unknown Shop";
                    final ownerName = shop['name'] ?? "Owner";

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: kPrimaryColor.withOpacity(0.1),
                          radius: 25,
                          child: Text(
                            shopName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryColor),
                          ),
                        ),
                        title: Text(
                          shopName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text("Owner: $ownerName"),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: kTextSecondary),
                                const SizedBox(width: 4),
                                Text("Location details...", style: TextStyle(fontSize: 12, color: kTextSecondary)),
                              ],
                            )
                          ],
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            backgroundColor: kPrimaryColor,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            // TODO: Navigate to Referral Form with this Shop's ID
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Selected: $shopName")),
                            );
                          },
                          child: const Text("Select"),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text("Error: $err")),
            ),
          ),
        ],
      ),
    );
  }
}