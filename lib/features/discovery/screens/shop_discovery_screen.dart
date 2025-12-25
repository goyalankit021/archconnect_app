import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/user_provider.dart';
import '../../home/data/shop_repository.dart';
import 'shop_detail_screen.dart';

// Provider to fetch shops
final activeShopsProvider = StreamProvider<List<DocumentSnapshot<Map<String, dynamic>>>>((ref) {
  return ref.read(shopRepositoryProvider).getActiveShopsStream();
});

class ShopDiscoveryScreen extends ConsumerStatefulWidget {
  const ShopDiscoveryScreen({super.key});

  @override
  ConsumerState<ShopDiscoveryScreen> createState() => _ShopDiscoveryScreenState();
}

class _ShopDiscoveryScreenState extends ConsumerState<ShopDiscoveryScreen> {
  // --- SEARCH & FILTER STATE ---
  String _searchQuery = "";
  String _selectedSort = "relevance"; // 'relevance', 'comm_high', 'comm_low'
  Set<String> _selectedCategories = {}; // Stores selected filter tags

  // --- FILTER LOGIC ---
  List<DocumentSnapshot<Map<String, dynamic>>> _applyFilters(
      List<DocumentSnapshot<Map<String, dynamic>>> allShops) {

    return allShops.where((doc) {
      final data = doc.data()!;
      final name = (data['name'] ?? "").toString().toLowerCase();
      final categories = List<String>.from(data['categories'] ?? []);

      // 1. Search Filter (Name)
      if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) {
        return false;
      }

      // 2. Category Filter (If any selected)
      if (_selectedCategories.isNotEmpty) {
        // Check if shop has ANY of the selected categories
        bool hasCategory = categories.any((cat) => _selectedCategories.contains(cat));
        if (!hasCategory) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        // 3. Sorting Logic
        final dataA = a.data()!;
        final dataB = b.data()!;
        final commA = (dataA['commissionDefaultPercent'] ?? 0.0) as num;
        final commB = (dataB['commissionDefaultPercent'] ?? 0.0) as num;

        if (_selectedSort == 'comm_high') {
          return commB.compareTo(commA); // Descending
        } else if (_selectedSort == 'comm_low') {
          return commA.compareTo(commB); // Ascending
        }
        return 0; // Relevance (Default Firestore order)
      });
  }

  // --- SHOW FILTER SHEET ---
  void _showFilterSheet(List<String> allAvailableCategories) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          // Local state for the sheet before "Applying"
          String tempSort = _selectedSort;
          Set<String> tempCategories = Set.from(_selectedCategories);

          return StatefulBuilder(
              builder: (context, setSheetState) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  height: MediaQuery.of(context).size.height * 0.7, // 70% height
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Filter & Sort", style: Theme.of(context).textTheme.headlineSmall),
                          TextButton(
                              onPressed: () {
                                // Clear Filters
                                setSheetState(() {
                                  tempSort = "relevance";
                                  tempCategories.clear();
                                });
                              },
                              child: const Text("Clear")
                          )
                        ],
                      ),
                      const Divider(),

                      // SORT SECTION
                      const Text("Sort By", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      RadioListTile(
                        title: const Text("Relevance"),
                        value: "relevance",
                        groupValue: tempSort,
                        onChanged: (val) => setSheetState(() => tempSort = val.toString()),
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile(
                        title: const Text("Commission: High to Low"),
                        value: "comm_high",
                        groupValue: tempSort,
                        onChanged: (val) => setSheetState(() => tempSort = val.toString()),
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile(
                        title: const Text("Commission: Low to High"),
                        value: "comm_low",
                        groupValue: tempSort,
                        onChanged: (val) => setSheetState(() => tempSort = val.toString()),
                        contentPadding: EdgeInsets.zero,
                      ),

                      const SizedBox(height: 16),

                      // CATEGORIES SECTION
                      const Text("Categories", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allAvailableCategories.map((cat) {
                          final isSelected = tempCategories.contains(cat);
                          return FilterChip(
                            label: Text(cat.toUpperCase()),
                            selected: isSelected,
                            selectedColor: kPrimaryColor.withOpacity(0.2),
                            checkmarkColor: kPrimaryColor,
                            labelStyle: TextStyle(
                                color: isSelected ? kPrimaryColor : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                            ),
                            onSelected: (selected) {
                              setSheetState(() {
                                if (selected) {
                                  tempCategories.add(cat);
                                } else {
                                  tempCategories.remove(cat);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const Spacer(),

                      // APPLY BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16)
                          ),
                          onPressed: () {
                            // Apply changes to main state
                            setState(() {
                              _selectedSort = tempSort;
                              _selectedCategories = tempCategories;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text("APPLY FILTERS", style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      )
                    ],
                  ),
                );
              }
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    final shopsAsync = ref.watch(activeShopsProvider);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Find Shops"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // --- SEARCH BAR ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search by Shop Name...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // FILTER BUTTON
                InkWell(
                  onTap: () {
                    // We need active shops to extract available categories for the filter
                    shopsAsync.whenData((shops) {
                      // Extract unique categories from all shops
                      final allCats = <String>{};
                      for (var doc in shops) {
                        final cats = List<String>.from(doc.data()!['categories'] ?? []);
                        allCats.addAll(cats);
                      }
                      _showFilterSheet(allCats.toList());
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _selectedCategories.isNotEmpty || _selectedSort != 'relevance'
                          ? kPrimaryColor
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                        Icons.tune,
                        color: _selectedCategories.isNotEmpty || _selectedSort != 'relevance'
                            ? Colors.white
                            : Colors.grey
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- SHOP LIST ---
          Expanded(
            child: shopsAsync.when(
              data: (shops) {
                final filteredShops = _applyFilters(shops);

                if (filteredShops.isEmpty) {
                  return const Center(child: Text("No shops found matching your criteria."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredShops.length,
                  itemBuilder: (context, index) {
                    final shopDoc = filteredShops[index]; // 1. Get the Snapshot
                    final shopData = shopDoc.data()!;     // 2. Get the Data

                    // 3. Build Card
                    // We need to update _buildShopCard to accept the ID or handle the onTap internally
                    return _buildShopCard(context, shopData, shopDoc.id);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text("Error: $e")),
            ),
          ),
        ],
      ),
    );
  }

  // --- SHOP CARD WIDGET ---
  Widget _buildShopCard(BuildContext context, Map<String, dynamic> data, String shopId) {
    final name = data['name'] ?? "Unknown Shop";
    final photoUrl = data['profilePhotoUrl'];
    final commission = data['commissionDefaultPercent'] ?? 0.0;
    final categories = List<String>.from(data['categories'] ?? []);
    final primaryCategory = categories.isNotEmpty ? categories.first.toUpperCase() : "GENERAL";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            // TODO: Navigate to Shop Detail Screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShopDetailScreen(
                  shopData: data,
                  shopId: shopId,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // 1. Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey.shade100,
                    child: photoUrl != null
                        ? Image.network(photoUrl, fit: BoxFit.cover)
                        : const Icon(Icons.store, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),

                // 2. Details
                // 2. Details (Improved)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 6),

                      // Categories Row (Smart Display)
                      if (categories.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: [
                            // Show first category
                            _buildMiniTag(categories[0]),

                            // Show second category if available
                            if (categories.length > 1)
                              _buildMiniTag(categories[1]),

                            // Show count if more exist
                            if (categories.length > 2)
                              Text(
                                  "+${categories.length - 2}",
                                  style: TextStyle(fontSize: 10, color: kTextSecondary, height: 1.5)
                              ),
                          ],
                        )
                      else
                        Text("General", style: TextStyle(fontSize: 11, color: kTextSecondary)),
                    ],
                  ),
                ),

                // 3. Commission Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    children: [
                      Text("$commission%", style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Comm.", style: TextStyle(color: Colors.green.shade600, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
      child: Text(
          text.toUpperCase(),
          style: TextStyle(fontSize: 9, color: kTextSecondary, fontWeight: FontWeight.bold)
      ),
    );
  }
}