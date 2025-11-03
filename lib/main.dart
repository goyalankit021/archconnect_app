import 'package:flutter/material.dart';
import 'app.dart'; // Import our new app root

void main() {
  // We can add more initialization logic here later (like Firebase)
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ArchConnectApp());
}