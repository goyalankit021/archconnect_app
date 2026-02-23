import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/authentication/auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() {
    // 3-second delay to show the brand
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Pushes to AuthWrapper, which automatically decides Login vs Home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white, // Ensure a clean background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. Logo
            Image.asset(
              'assets/images/logo/logo_without_name.png',
              height: 80,
            ),
            const SizedBox(height: 24),

            // 2. App Name
            Text(
              "ArchConnect",
              style: textTheme.headlineSmall?.copyWith(
                  color: kPrimaryColor,
                  fontWeight: FontWeight.bold
              ),
            ),
            const SizedBox(height: 40),

            // 3. Loading Spinner
            const CircularProgressIndicator(
              color: kPrimaryVariant,
            ),
            const SizedBox(height: 40),

            // 4. Tagline
            Text(
              "Building trust, one brick at a time.",
              style: textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: Colors.grey.shade600
              ),
            ),
          ],
        ),
      ),
    );
  }
}