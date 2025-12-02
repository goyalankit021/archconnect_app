import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <--- Import this!
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // WRAP THE APP IN PROVIDERSCOPE
  runApp(
    const ProviderScope( // <--- This was likely missing or removed
      child: ArchConnectApp(),
    ),
  );
}