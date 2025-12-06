import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/user_provider.dart'; // Import the stream provider
import 'architect_home.dart';
import 'shop_home.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the user data stream
    final userAsyncValue = ref.watch(userProfileStreamProvider);

    return userAsyncValue.when(
      // 1. Data Loaded Successfully
      data: (userData) {
        if (userData == null) {
          return const Scaffold(body: Center(child: Text("User not found")));
        }

        final role = userData['role'];

        // THE SWITCH LOGIC
        if (role == 'architect') {
          return ArchitectHome(userData: userData);
        } else if (role == 'shop') {
          return ShopHome(userData: userData);
        } else {
          return const Scaffold(body: Center(child: Text("Unknown Role")));
        }
      },

      // 2. Loading State
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),

      // 3. Error State
      error: (err, stack) => Scaffold(
        body: Center(child: Text("Error: $err")),
      ),
    );
  }
}