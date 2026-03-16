import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../services/logger_service.dart'; // ✅ Inject Logger

final storageServiceProvider = Provider((ref) {
  final logger = ref.read(loggerServiceProvider);
  return StorageService(logger);
});

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  final LoggerService _logger;

  StorageService(this._logger);

  // --- 1. PICK IMAGE ---
  Future<File?> pickImage({required bool fromCamera}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 50, // Optimal for mobile
      );

      if (pickedFile != null) return File(pickedFile.path);
      return null;

    } catch (e, s) {
      _logger.logError(e, s, reason: "Image Picker Failed (Camera/Gallery Permission?)");
      return null;
    }
  }

  // --- 2. UPLOAD FILE ---
  Future<String?> uploadFile({required File file, required String path}) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();

      _logger.logDebug("File uploaded successfully to: $path");
      return downloadUrl;

    } catch (e, s) {
      _logger.logError(e, s, reason: "Firebase Storage Upload Failed: $path");
      throw Exception("Upload failed: $e");
    }
  }

  // --- 3. DELETE FILE ---
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
      _logger.logDebug("File deleted successfully: $url");
    } catch (e, s) {
      // Non-fatal error, but we log it to know if storage is clogging up
      _logger.logError(e, s, reason: "Failed to delete file from Storage: $url");
    }
  }
}