import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ShopHome extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ShopHome({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final firmName = userData['firm']?['name'] ?? 'My Shop';

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Shop Dashboard"),
        backgroundColor: Colors.green[800], // Different color for distinction
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront, size: 80, color: Colors.green[800]),
            const SizedBox(height: 20),
            Text(
              firmName,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            const Text("Active Leads: 0"),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[800]),
              onPressed: () {},
              icon: const Icon(Icons.receipt_long),
              label: const Text("Record New Sale"),
            )
          ],
        ),
      ),
    );
  }
}