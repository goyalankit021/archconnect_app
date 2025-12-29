import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/wallet_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PayoutBottomSheet extends ConsumerStatefulWidget {
  final double currentBalance;
  final Map<String, dynamic> bankDetails; // Passed from the wallet screen

  const PayoutBottomSheet({
    super.key,
    required this.currentBalance,
    required this.bankDetails,
  });

  @override
  ConsumerState<PayoutBottomSheet> createState() => _PayoutBottomSheetState();
}

class _PayoutBottomSheetState extends ConsumerState<PayoutBottomSheet> {
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.parse(_amountController.text);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Formatting Bank Info for the record
    final bankInfo = "${widget.bankDetails['bankName']} (${widget.bankDetails['accountNumber']})";

    setState(() => _isLoading = true);

    try {
      // Call the Repo
      await ref.read(walletRepositoryProvider).requestPayout(
        uid: uid,
        amount: amount,
        bankDetails: bankInfo,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close sheet

      // Success Message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Success! ₹${amount.toInt()} withdrawal requested."),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString().replaceAll('Exception:', '')}")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safety: If no bank details exist
    final bankName = widget.bankDetails['bankName'] ?? 'No Bank Linked';
    final accNum = widget.bankDetails['accountNumber'] ?? '----';

    return Padding(
      // Handles keyboard covering input
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Withdraw Funds", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),

            // Bank Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance, color: kPrimaryColor),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Transfer to", style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      Text("$bankName - $accNum", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Amount Input
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: "₹ ",
                labelText: "Enter Amount",
                hintText: "Min ₹1000",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) return "Enter amount";
                final amt = double.tryParse(value);
                if (amt == null) return "Invalid amount";
                if (amt < 1000) return "Minimum withdrawal is ₹1000";
                if (amt > widget.currentBalance) return "Exceeds balance (₹${widget.currentBalance})";
                return null;
              },
            ),

            // Available Balance Hint
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 24),
              child: Text(
                "Available Balance: ₹${widget.currentBalance}",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("CONFIRM WITHDRAWAL"),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}