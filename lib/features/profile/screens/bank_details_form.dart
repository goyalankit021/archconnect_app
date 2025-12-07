import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/data/user_repository.dart';

class BankDetailsForm extends ConsumerStatefulWidget {
  const BankDetailsForm({super.key});

  @override
  ConsumerState<BankDetailsForm> createState() => _BankDetailsFormState();
}

class _BankDetailsFormState extends ConsumerState<BankDetailsForm> {
  final _formKey = GlobalKey<FormState>();
  final _accController = TextEditingController();
  final _ifscController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _upiController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _accController.dispose();
    _ifscController.dispose();
    _bankNameController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _saveDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final uid = FirebaseAuth.instance.currentUser!.uid;

        await ref.read(userRepositoryProvider).updateBankDetails(
          uid: uid,
          accountNumber: _accController.text.trim(),
          ifsc: _ifscController.text.trim(),
          bankName: _bankNameController.text.trim(),
          upiId: _upiController.text.trim(),
        );

        if (!mounted) return;
        Navigator.pop(context); // Close the form
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bank Details Saved Successfully!")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Add Bank Details"),
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Payout Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Ensure these details are correct. Earnings will be transferred here.",
                style: TextStyle(color: kTextSecondary, fontSize: 13),
              ),
              const SizedBox(height: 24),

              // Account Number
              TextFormField(
                controller: _accController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Account Number",
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (val) => val!.length < 9 ? "Invalid Account Number" : null,
              ),
              const SizedBox(height: 16),

              // IFSC Code
              TextFormField(
                controller: _ifscController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: "IFSC Code",
                  prefixIcon: Icon(Icons.account_balance),
                  hintText: "e.g. HDFC0001234",
                ),
                validator: (val) => val!.length != 11 ? "IFSC must be 11 characters" : null,
              ),
              const SizedBox(height: 16),

              // Bank Name
              TextFormField(
                controller: _bankNameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: "Bank Name",
                  prefixIcon: Icon(Icons.business),
                  hintText: "e.g. HDFC Bank",
                ),
                validator: (val) => val!.isEmpty ? "Bank Name Required" : null,
              ),
              const SizedBox(height: 16),

              // UPI ID
              TextFormField(
                controller: _upiController,
                decoration: const InputDecoration(
                  labelText: "UPI ID",
                  prefixIcon: Icon(Icons.qr_code),
                  hintText: "e.g. name@okaxis",
                ),
                validator: (val) => !val!.contains("@") ? "Invalid UPI ID" : null,
              ),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveDetails,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("SAVE SECURELY"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}