import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Needed for input formatters
import '../../../core/theme/app_theme.dart'; // Importing our world-class theme
import 'otp_verification_screen.dart'; // Navigation target
import '../logic/auth_controller.dart'; // Auth controller
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Controller to retrieve the text
  final TextEditingController _phoneController = TextEditingController();
  // Key to identify the form and trigger validation
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // Always dispose controllers to free up memory (World-Class Standard)
    _phoneController.dispose();
    super.dispose();
  }

  void _onContinue() {
    // 1. Validate the input (Must be 10 digits)
    if (_formKey.currentState!.validate()) {
      // Show a loading indicator (optional but good UX)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sending OTP...")),
      );

      // Call the Controller!
      ref.read(authControllerProvider).sendOtp(
        context: context,
        phoneNumber: _phoneController.text,
      );

      // 2. Navigate to OTP Screen (We pass the phone number forward)
      // Navigator.of(context).push(
      //   MaterialPageRoute(
      //     builder: (context) => OtpVerificationScreen(
      //       phoneNumber: _phoneController.text,
      //     ),
      //   ),
      // );
    }
  }


  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive spacing
    final size = MediaQuery.of(context).size;
    // Access our theme text styles
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: kBackgroundColor,
      // SafeArea ensures we don't hide behind notches or status bars
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: size.height,
          child: SingleChildScrollView(
            // Padding: 24 is a standard "comfortable" margin for mobile
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dynamic spacing based on screen height
                  SizedBox(height: size.height * 0.08),

                  // --- 1. Logo Section ---
                  Center(
                    child: Image.asset(
                      'assets/images/logo/logo_without_name.png',
                      height: 70,
                      // Ensure this path matches your actual asset path exactly!
                    ),
                  ),
                  SizedBox(height: size.height * 0.05),

                  // --- 2. Welcome Text ---
                  Text(
                    "Welcome.",
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Enter your mobile number to begin.",
                    style: textTheme.bodyMedium,
                  ),

                  SizedBox(height: size.height * 0.06),

                  // --- 3. Input Field ---
                  Text(
                    "Mobile Number",
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    // World-Class UX: Larger text for easy reading
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.2
                    ),
                    // Restrictions: Max 10 chars, Digits only
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(10),
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      hintText: "98765 43210",
                      // The "+91" prefix
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Text(
                          "+91 ",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: kTextPrimary,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                    // Validation Logic
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Phone number is required";
                      }
                      if (value.length != 10) {
                        return "Please enter a valid 10-digit number";
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // --- 4. Legal / Terms ---
                  Text(
                    "By continuing, you agree to our Terms & Conditions and Privacy Policy.",
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),

                  SizedBox(height: size.height * 0.05),

                  // --- 5. Action Button ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onContinue,
                      child: const Text("CONTINUE"),
                    ),
                  ),

                  // Bottom padding for scrolling safety
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}