import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/otp_verification_screen.dart';
import '../screens/create_profile_screen.dart';
import '../../../core/authentication/auth_wrapper.dart';
import '../../../core/services/logger_service.dart'; // ✅ Logger injected

// 1. The State Provider
// ✅ FIX: We pass 'ref' into the controller so it can access the Logger safely
final authControllerProvider = Provider((ref) => AuthController(FirebaseAuth.instance, ref));

class AuthController {
  final FirebaseAuth _auth;
  final Ref _ref; // Used to read other Riverpod providers

  AuthController(this._auth, this._ref);

  // Variable to store the "Verification ID" needed for Step 2
  String? _verificationId;

  // --- FUNCTION 1: SEND OTP ---
  Future<void> sendOtp({
    required BuildContext context,
    required String phoneNumber,
  }) async {
    try {
      _ref.read(loggerServiceProvider).logDebug("Requesting OTP for $phoneNumber");

      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$phoneNumber',

        // A. Auto-verify (Android only - sometimes happens instantly)
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            _ref.read(loggerServiceProvider).logDebug("Auto Verification Triggered!");
            await _auth.signInWithCredential(credential);

            if (!context.mounted) return;
            await _checkUserAndRoute(context);
          } catch (e, s) {
            _ref.read(loggerServiceProvider).logError(e, s, reason: "Auto-verification sign-in failed");
          }
        },

        // B. Handling Errors
        verificationFailed: (FirebaseAuthException e) {
          _ref.read(loggerServiceProvider).logError(e, null, reason: "OTP Verification Failed: ${e.code}");
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Verification Failed: ${e.message}")),
          );
        },

        // C. Code Sent (This is the Happy Path)
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId; // SAVE THIS ID!
          _ref.read(loggerServiceProvider).logDebug("OTP Code Sent successfully.");

          if (!context.mounted) return;
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
    } catch (e, s) {
      _ref.read(loggerServiceProvider).logError(e, s, reason: "Send OTP Catch Block");
      if (!context.mounted) return;
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
      if (_verificationId == null) {
        throw Exception("Verification ID is missing. Please request a new OTP.");
      }

      _ref.read(loggerServiceProvider).logDebug("Verifying user inputted OTP...");

      // 1. Create a Credential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: userOtp,
      );

      // 2. Sign In
      await _auth.signInWithCredential(credential);

      // 3. Check DB and Route
      if (!context.mounted) return;
      await _checkUserAndRoute(context);

    } on FirebaseAuthException catch (e, s) {
      _ref.read(loggerServiceProvider).logError(e, s, reason: "Invalid OTP Entered");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid OTP: ${e.message}")),
      );
    } catch (e, s) {
      _ref.read(loggerServiceProvider).logError(e, s, reason: "OTP Verification Unknown Error");
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  // --- HELPER: CHECK DB & ROUTE ---
  // Extracted this logic so both Auto-Verify and Manual-Verify can use it
  Future<void> _checkUserAndRoute(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final db = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: 'arch-connect-database'
    );

    final doc = await db.collection('users').doc(user.uid).get();

    if (!context.mounted) return;

    if (doc.exists) {
      // ✅ SUCCESS: Existing User Login
      _ref.read(loggerServiceProvider).logAudit(
        entityType: 'auth',
        entityId: user.uid,
        action: 'login',
        description: 'User logged in successfully',
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const AuthWrapper()),
            (route) => false,
      );
    } else {
      // ✅ SUCCESS: New User Signup
      _ref.read(loggerServiceProvider).logAudit(
        entityType: 'auth',
        entityId: user.uid,
        action: 'signup_started',
        description: 'New user verified OTP, heading to profile creation',
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => CreateProfileScreen(phoneNumber: user.phoneNumber ?? ""),
        ),
            (route) => false,
      );
    }
  }
}