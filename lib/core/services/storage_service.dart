import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// Provider to access this service anywhere
final storageServiceProvider = Provider((ref) => StorageService());

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // --- 1. PICK IMAGE (From Camera or Gallery) ---
  Future<File?> pickImage({required bool fromCamera}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 80, // Optimize size automatically
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print("Error picking image: $e");
      return null;
    }
  }

  // --- 2. UPLOAD FILE ---
  // Returns the download URL (String) to save in Firestore
  Future<String?> uploadFile({
    required File file,
    required String path, // e.g., "kyc/user_123_pan.jpg"
  }) async {
    try {
      // Create the reference in the cloud
      final ref = _storage.ref().child(path);

      // Upload
      final uploadTask = ref.putFile(file);

      // Wait for completion
      final snapshot = await uploadTask.whenComplete(() {});

      // Get the URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading file: $e");
      throw Exception("Upload failed: $e");
    }
  }
}