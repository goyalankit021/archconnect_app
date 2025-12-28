import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // ✅ Added for Firebase.app()
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/architect_home.dart';
import '../../features/home/screens/shop_home.dart';

// ⚡️ 1. THE LOGIC PROVIDER (The Brain)
final authStateProvider = StreamProvider.autoDispose<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final userRoleProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, uid) async {
  // ✅ FIX: Connect to the NAMED database, not the default one
  final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'arch-connect-database'
  );

  // Force a fetch from the SERVER, ignoring local cache (prevents zombie data)
  final doc = await db
      .collection('users')
      .doc(uid)
      .get(const GetOptions(source: Source.serverAndCache));

  if (!doc.exists) throw Exception("User document not found");
  return doc.data()!;
});

// 🚦 2. THE WIDGET (The Traffic Cop)
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the Authentication State (Login/Logout)
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, stack) => Center(child: Text("Auth Error: $e")),
      data: (user) {

        // CASE A: No User Logged In -> Go to Login
        if (user == null) {
          return const LoginScreen();
        }

        // CASE B: User Logged In -> Fetch Role
        final userDataAsync = ref.watch(userRoleProvider(user.uid));

        return userDataAsync.when(
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, stack) {
            // If error (e.g., user deleted or network fail), go back to login for safety
            return const LoginScreen();
          },
          data: (userData) {
            final role = userData['role'];

            // CASE C: Route based on Role
            if (role == 'architect') {
              return ArchitectHome(userData: userData);
            } else if (role == 'shop') {
              return ShopHome(userData: userData);
            } else {
              return const Scaffold(body: Center(child: Text("Error: Unknown Role")));
            }
          },
        );
      },
    );
  }
}