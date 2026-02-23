import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import '../../../core/theme/app_theme.dart';
import '../logic/auth_controller.dart';
import '../../../core/services/logger_service.dart'; // ✅ Added Logger

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const OtpVerificationScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();

  Timer? _timer;
  int _start = 30;
  bool _isResendAvailable = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void startTimer() {
    setState(() {
      _isResendAvailable = false;
      _start = 30;
    });

    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
          _isResendAvailable = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void _resendOtp() {
    // ✅ LOG IT: Track SMS Quota usage
    ref.read(loggerServiceProvider).logAudit(
        entityType: 'auth',
        entityId: widget.phoneNumber,
        action: 'resend_otp',
        description: 'User requested a new OTP',
        severity: 'info'
    );

    ref.read(authControllerProvider).sendOtp(
        context: context,
        phoneNumber: widget.phoneNumber
    );

    startTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("OTP Resent!")),
    );
  }

  void _verifyOtp() {
    String otp = _otpController.text;
    if (otp.length == 6) {
      ref.read(authControllerProvider).verifyOtp(
          context: context,
          userOtp: otp
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter full 6-digit code")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textTheme = Theme.of(context).textTheme;

    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: const TextStyle(fontSize: 20, color: kTextPrimary, fontWeight: FontWeight.w600),
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
              Text("Verify your number", style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text("Enter code sent to ", style: textTheme.bodyMedium),
                  Text("+91 ${widget.phoneNumber}", style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: kTextPrimary)),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text("Edit Phone Number", style: TextStyle(color: kPrimaryVariant, fontWeight: FontWeight.w600)),
                ),
              ),
              SizedBox(height: size.height * 0.05),

              Center(
                child: Pinput(
                  length: 6,
                  controller: _otpController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  onCompleted: (pin) => _verifyOtp(), // Auto-verify on 6th digit
                ),
              ),

              SizedBox(height: size.height * 0.05),

              Center(
                child: _isResendAvailable
                    ? TextButton(
                  onPressed: _resendOtp,
                  child: const Text(
                    "Resend OTP",
                    style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                )
                    : RichText(
                  text: TextSpan(
                    text: "Didn't receive the code? ",
                    style: const TextStyle(color: kTextSecondary, fontFamily: 'Poppins'),
                    children: [
                      TextSpan(
                        text: "Resend in ${_start}s",
                        style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.05),

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