import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/screens/splash_screen.dart';

class ArchConnectApp extends StatelessWidget {
  const ArchConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArchConnect',
      theme: AppTheme.lightTheme, // This applies our theme to the whole app
      debugShowCheckedModeBanner: false, // Hides the "debug" banner
      home: const SplashScreen(), // This is our entry screen
    );
  }
}