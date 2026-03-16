import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/data/shop_repository.dart';
import 'shop_detail_screen.dart';

final activeShopsProvider = StreamProvider.autoDispose<List<DocumentSnapshot<Map<String, dynamic>>>>((ref) {
  return ref.read(shopRepositoryProvider).getActiveShopsStream();
});

class ShopDiscoveryScreen extends ConsumerStatefulWidget {
  const ShopDiscoveryScreen({super.key});

  @override
  ConsumerState<ShopDiscoveryScreen> createState() => _ShopDiscoveryScreenState();
}

class _ShopDiscoveryScreenState extends ConsumerState<ShopDiscoveryScreen> {
  String _searchQuery = "";
  String _selectedSort = "relevance";
  Set<String> _selectedCategories = {};

  List<DocumentSnapshot<Map<String, dynamic>>> _applyFilters(List<DocumentSnapshot<Map<String, dynamic>>> allShops) {
    return allShops.where((doc) {
      final data = doc.data()!;
      final name = (data['name'] ?? "").toString().toLowerCase();
      final categories = List<String>.from(data['categories'] ?? []);

      if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) {
        return false;
      }

      if (_selectedCategories.isNotEmpty) {
        bool hasCategory = categories.any((cat) => _selectedCategories.contains(cat));
        if (!hasCategory) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) {
        final dataA = a.data()!;
        final dataB = b.data()!;
        final commA = (dataA['commissionDefaultPercent'] ?? 0.0) as num;
        final commB = (dataB['commissionDefaultPercent'] ?? 0.0) as num;

        if (_selectedSort == 'comm_high') return commB.compareTo(commA);
        if (_selectedSort == 'comm_low') return commA.compareTo(commB);
        return 0;
      });
  }

  void _showFilterSheet(List<String> allAvailableCategories) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) {
          String tempSort = _selectedSort;
          Set<String> tempCategories = Set.from(_selectedCategories);

          return StatefulBuilder(
              builder: (context, setSheetState) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Filter & Sort", style: Theme.of(context).textTheme.headlineSmall),
                          TextButton(
                              onPressed: () {
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
                                selected ? tempCategories.add(cat) : tempCategories.remove(cat);
                              });
                            },
                          );
                        }).toList(),
                      ),

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: kPrimaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16)
                          ),
                          onPressed: () {
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
        title: const Text("Find Shops", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
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
                InkWell(
                  onTap: () {
                    shopsAsync.whenData((shops) {
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
                        border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: Icon(
                        Icons.tune,
                        color: _selectedCategories.isNotEmpty || _selectedSort != 'relevance'
                            ? Colors.white
                            : Colors.grey.shade700
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: shopsAsync.when(
              data: (shops) {
                final filteredShops = _applyFilters(shops);

                if (filteredShops.isEmpty) {
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.store_outlined, size: 60, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text("No shops found matching your criteria.", style: TextStyle(color: Colors.grey)),
                          ]
                      )
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredShops.length,
                  itemBuilder: (context, index) {
                    final shopDoc = filteredShops[index];
                    final shopData = shopDoc.data()!;
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

  Widget _buildShopCard(BuildContext context, Map<String, dynamic> data, String shopId) {
    final name = data['name'] ?? "Unknown Shop";
    final photoUrl = data['profilePhotoUrl'];
    final commission = data['commissionDefaultPercent'] ?? 0.0;
    final categories = List<String>.from(data['categories'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShopDetailScreen(shopData: data, shopId: shopId),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
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

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 6),

                      if (categories.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: [
                            _buildMiniTag(categories[0]),
                            if (categories.length > 1) _buildMiniTag(categories[1]),
                            if (categories.length > 2)
                              Text(
                                  "+${categories.length - 2}",
                                  style: const TextStyle(fontSize: 10, color: kTextSecondary, height: 1.5)
                              ),
                          ],
                        )
                      else
                        const Text("General", style: TextStyle(fontSize: 11, color: kTextSecondary)),
                    ],
                  ),
                ),

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
          style: const TextStyle(fontSize: 9, color: kTextSecondary, fontWeight: FontWeight.bold)
      ),
    );
  }
}