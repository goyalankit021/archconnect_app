import 'package:flutter/material.dart';
import 'login_screen.dart'; // We'll create this "stub" file next
import '../../../core/theme/app_theme.dart'; // Import our theme colors
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToLogin();
  }

  void _navigateToLogin() {
    Timer(const Duration(seconds: 3), () { // Use Timer for explicit scheduling
      if (mounted) {
        // Replace with a clean named route if possible, but MaterialPageRoute is fine for MVP:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Using theme colors directly
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // We don't need an AppBar for a splash screen
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Our Placeholder Icon
            Image.asset(
              'assets/images/logo/logo_without_name.png', // The path to your file
              height: 80, // Keep the same height for consistent look
              // If your logo is monochrome and needs tinting, use a ColorFilter here.
              // If it's a full-color logo, just leave it as is.
            ),
            const SizedBox(height: 24),
            // 2. The App Name
            Text(
              "ArchConnect",
              style: textTheme.headlineSmall?.copyWith(color: kPrimaryColor),
            ),
            const SizedBox(height: 40),

            // 3. The Loading Spinner
            const CircularProgressIndicator(
              color: kPrimaryVariant, // Use our theme color
            ),
            const SizedBox(height: 40),

            // 4. The Tagline
            Text(
              "Building trust, one brick at a time.",
              style: textTheme.bodyMedium?.copyWith(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}