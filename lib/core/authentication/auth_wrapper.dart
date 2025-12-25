import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/architect_home.dart';
import '../../features/home/screens/shop_home.dart';
import '../theme/app_theme.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. LISTEN TO AUTH STATE (Login/Logout)
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // State A: Waiting for Firebase to check local storage
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // State B: No User Found (Go to Login)
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // State C: User Found! Now check their Role.
        final User user = snapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instanceFor(
              app: Firebase.app(),
              databaseId: 'arch-connect-database'
          ).collection('users').doc(user.uid).get(),

          builder: (context, userSnapshot) {
            // Loading Role...
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
              // Edge case: User is in Auth but not in Database (Deleted account?)
              return const LoginScreen();
            }

            // GET DATA
            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
            final role = userData['role'];

            // ROUTING LOGIC
            if (role == 'architect') {
              return ArchitectHome(userData: userData);
            } else if (role == 'shop') {
              return ShopHome(userData: userData);
            } else {
              // Unknown role
              return const Scaffold(body: Center(child: Text("Error: Unknown Role")));
            }
          },
        );
      },
    );
  }
}