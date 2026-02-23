import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/architect_home.dart';
import '../../features/home/screens/shop_home.dart';

// ⚡️ 1. THE AUTH PROVIDER
// Removed 'autoDispose' so it stays alive as long as the app is open
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// ⚡️ 2. THE ROLE PROVIDER
final userRoleProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, uid) async {

  // Connect to the specific named database
  final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database'
  );

  // Force a fetch from the server to prevent stale cache data
  final doc = await db
      .collection('users')
      .doc(uid)
      .get(const GetOptions(source: Source.serverAndCache));

  if (!doc.exists) {
    // 🚨 ANTI-LOOP FIX: If they are Authed but have no DB profile, sign them out.
    // This happens if profile creation failed during initial signup.
    await FirebaseAuth.instance.signOut();
    throw Exception("Profile incomplete. Signed out for safety.");
  }

  return doc.data()!;
});

// 🚦 3. THE WIDGET (The Traffic Cop)
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the Authentication State (Login/Logout)
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),

      // If Auth itself fails (e.g., bad tokens)
      error: (e, stack) => Scaffold(
        body: Center(child: Text("Auth Error: $e", textAlign: TextAlign.center)),
      ),

      data: (user) {
        // CASE A: No User Logged In -> Go to Login
        if (user == null) {
          return const LoginScreen();
        }

        // CASE B: User Logged In -> Fetch Role from DB
        final userDataAsync = ref.watch(userRoleProvider(user.uid));

        return userDataAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),

          error: (e, stack) {
            // CASE C: Error fetching DB profile (or missing doc caught by our fix)
            // They are already signed out by the provider, so LoginScreen is safe.
            return const LoginScreen();
          },

          data: (userData) {
            final role = userData['role'];

            // CASE D: Route based on exact Role
            if (role == 'architect') {
              return ArchitectHome(userData: userData);
            } else if (role == 'shop') {
              return ShopHome(userData: userData);
            } else {
              // Failsafe for corrupted data
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 50),
                      const SizedBox(height: 16),
                      Text("Invalid Role: $role"),
                      TextButton(
                        onPressed: () => FirebaseAuth.instance.signOut(),
                        child: const Text("Log Out"),
                      )
                    ],
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}