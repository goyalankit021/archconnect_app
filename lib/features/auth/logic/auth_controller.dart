import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/otp_verification_screen.dart';
import '../screens/create_profile_screen.dart';
import '../data/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../home/screens/home_screen.dart';

// 1. The State Provider
// This allows us to access this controller from ANY screen.
final authControllerProvider = Provider((ref) => AuthController(FirebaseAuth.instance));

class AuthController {
  final FirebaseAuth _auth;

  AuthController(this._auth);

  // Variable to store the "Verification ID" needed for Step 2
  String? _verificationId;

  // --- FUNCTION 1: SEND OTP ---
  Future<void> sendOtp({
    required BuildContext context,
    required String phoneNumber,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',

        // A. Auto-verify (Android only - sometimes happens instantly)
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          // TODO: Navigate to Home Dashboard
          print("Auto Verification Complete!");
        },

        // B. Handling Errors
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Verification Failed: ${e.message}")),
          );
        },

        // C. Code Sent (This is the Happy Path)
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId; // SAVE THIS ID!

          // Navigate to OTP Screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(phoneNumber: phoneNumber),
            ),
          );
        },

        // D. Timeout
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  // --- FUNCTION 2: VERIFY OTP ---
  Future<void> verifyOtp({
    required BuildContext context,
    required String userOtp,
  }) async {
    try {
      // 1. Create a Credential using the ID we saved and the Code the user typed
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: userOtp,
      );

      // 2. Sign In
      await _auth.signInWithCredential(credential);

      // 3. Check Database
      final userRepo = ProviderContainer().read(userRepositoryProvider); // OR pass Ref to AuthController
      // *Better Way for Riverpod*: Pass 'Ref' to AuthController constructor.
      // For now, let's keep it simple and just do a direct check:

      final uid = _auth.currentUser!.uid;
      // 1. Point to the specific database
      final db = FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'arch-connect-database'
      );
      // 2. Check the document
      final doc = await db.collection('users').doc(uid).get();

      if (doc.exists) {
        // User Exists -> Go to Home Screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()), // <--- Update this
              (route) => false,
        );
      } else {
        // User New -> Go to Create Profile
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => CreateProfileScreen(phoneNumber: _auth.currentUser?.phoneNumber ?? ""),
          ),
              (route) => false,
        );
      }

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid OTP: ${e.message}")),
      );
    }
  }
}