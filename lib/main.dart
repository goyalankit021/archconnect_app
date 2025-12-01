import 'package:flutter/material.dart';
import 'app.dart'; // Import our new app root
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core

void main() async{
  // We can add more initialization logic here later (like Firebase)
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase before running the app
  await Firebase.initializeApp();

  runApp(const ArchConnectApp());
}