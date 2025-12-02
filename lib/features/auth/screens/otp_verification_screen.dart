import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart'; // Import the new package
import '../../../core/theme/app_theme.dart';
import '../logic/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  // Controller to get the OTP text
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verifyOtp() {

    String otp = _otpController.text;
    if (otp.length == 6) {
      // Call the Controller!
      ref.read(authControllerProvider).verifyOtp(
          context: context,
          userOtp: otp
      );
    } else {
      // ... error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter full 6-digit code")),
      );
    }

    // String otp = _otpController.text;
    // if (otp.length == 6) {
    //   // Logic placeholder: We will verify with Firebase here in the next step
    //   print("Verifying OTP: $otp");
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Verifying...")),
    //   );
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Please enter full 6-digit code")),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;

    // Define the style for the OTP boxes
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: const TextStyle(
          fontSize: 20,
          color: kTextPrimary,
          fontWeight: FontWeight.w600
      ),
      decoration: BoxDecoration(
        color: kSurfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: kPrimaryVariant, width: 2),
      ),
    );

    return Scaffold(
      backgroundColor: kBackgroundColor,
      // AppBar allows easy "Back" navigation if they typed wrong number
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: kTextPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.02),

              // 1. Heading
              Text(
                "Verify your number",
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // 2. Subtext with Edit option
              Row(
                children: [
                  Text(
                    "Enter code sent to ",
                    style: textTheme.bodyMedium,
                  ),
                  Text(
                    "+91 ${widget.phoneNumber}",
                    style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: kTextPrimary
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Go back to edit number
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    "Edit Phone Number",
                    style: TextStyle(
                      color: kPrimaryVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.05),

              // 3. OTP Input Field (Pinput)
              Center(
                child: Pinput(
                  length: 6,
                  controller: _otpController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  // Auto-submit when 6 digits are filled
                  onCompleted: (pin) => _verifyOtp(),
                ),
              ),

              SizedBox(height: size.height * 0.05),

              // 4. Resend Code Timer (Static for now)
              Center(
                child: RichText(
                  text: TextSpan(
                    text: "Didn't receive the code? ",
                    style: TextStyle(color: kTextSecondary, fontFamily: 'Poppins'),
                    children: [
                      TextSpan(
                        text: "Resend in 30s",
                        style: TextStyle(
                            color: kTextPrimary,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.05),

              // 5. Verify Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verifyOtp,
                  child: const Text("VERIFY & LOGIN"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}