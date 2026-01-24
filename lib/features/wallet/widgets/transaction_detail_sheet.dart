import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../screens/shop_wallet_screen.dart';

class TransactionDetailSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic> transactionData;

  const TransactionDetailSheet({super.key, required this.transactionData});

  @override
  ConsumerState<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends ConsumerState<TransactionDetailSheet> {
  bool _isUploading = false;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // New State for Payment Mode
  String _selectedPaymentMode = "UPI"; // Default

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _uploadAndSubmit() async {
    if (_selectedImage == null) return;

    setState(() => _isUploading = true);

    try {
      final txnId = widget.transactionData['transactionId'];
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // 1. Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('payment_proofs/$uid/$txnId.jpg');

      await storageRef.putFile(_selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();

      // 2. Update Firestore
      await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'arch-connect-database')
          .collection('transactions')
          .doc(txnId)
          .update({
        'status': 'verification_pending',
        'paymentProofUrl': downloadUrl,
        'paymentUploadedAt': FieldValue.serverTimestamp(),
        // Save the selected mode in notes
        'paymentNote': "Paid via $_selectedPaymentMode",
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Proof uploaded! Waiting for verification.")),
        );
      }
    } catch (e) {
      debugPrint("Upload Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.transactionData;
    final status = data['status'] ?? 'due';
    final amount = (data['amount'] ?? 0).toDouble();
    final billAmount = (data['billAmount'] ?? 0).toDouble();
    final meta = data['meta'] ?? {};

    final bankDetailsAsync = ref.watch(platformBankDetailsProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Transaction Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const Divider(),
          const SizedBox(height: 16),

          // Project Info
          _buildInfoRow("Project", meta['projectName'] ?? meta['description'] ?? "N/A"),
          const SizedBox(height: 12),
          _buildInfoRow("Bill Amount", "₹${billAmount.toStringAsFixed(0)}"),
          const SizedBox(height: 12),
          _buildInfoRow("Commission (5%)", "₹${amount.toStringAsFixed(0)}", isBold: true),

          const SizedBox(height: 24),

          // --- CONDITIONAL UI ---
          if (status == 'due') ...[

            // 1. Bank Details Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: bankDetailsAsync.when(
                data: (bankData) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Pay to Platform Account:", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildCopyRow("UPI ID", bankData['upiId'] ?? "N/A"),
                    const SizedBox(height: 12),
                    _buildCopyRow("Bank", bankData['bankName'] ?? "N/A"),
                    const SizedBox(height: 12),
                    _buildCopyRow("Account", bankData['accountNumber'] ?? "N/A"),
                    const SizedBox(height: 12),
                    // ✅ NEW: IFSC Code Added
                    _buildCopyRow("IFSC", bankData['ifscCode'] ?? "N/A"),
                  ],
                ),
                loading: () => const Center(child: LinearProgressIndicator()),
                error: (_,__) => const Text("Could not load bank details"),
              ),
            ),

            const SizedBox(height: 24),

            // 2. Upload Section
            if (_selectedImage == null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text("UPLOAD PAYMENT SCREENSHOT"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: Colors.blue),
                  ),
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ NEW: Payment Mode Selector
                  const Text("Payment Method Used:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildChoiceChip("UPI"),
                      const SizedBox(width: 12),
                      _buildChoiceChip("Bank Transfer"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Image Preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Image.file(_selectedImage!, height: 150, width: double.infinity, fit: BoxFit.cover),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            radius: 16,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 16, color: Colors.white),
                              onPressed: () => setState(() => _selectedImage = null),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _uploadAndSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isUploading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text("SUBMIT PROOF", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),

          ] else if (status == 'verification_pending') ...[
            // State: Verifying
            Center(
              child: Column(
                children: [
                  const Icon(Icons.hourglass_top, size: 40, color: Colors.blue),
                  const SizedBox(height: 8),
                  const Text("Verification Pending", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                  const SizedBox(height: 4),
                  const Text("Admin is reviewing your proof.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  if (data['paymentProofUrl'] != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(data['paymentProofUrl'], height: 200, fit: BoxFit.cover),
                    ),
                ],
              ),
            ),

          ] else ...[
            // State: Settled
            const Center(
              child: Column(
                children: [
                  Icon(Icons.check_circle, size: 50, color: Colors.green),
                  SizedBox(height: 8),
                  Text("Payment Settled", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ✅ NEW: Widget for Payment Mode Selection
  Widget _buildChoiceChip(String label) {
    final bool isSelected = _selectedPaymentMode == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedPaymentMode = label);
      },
      selectedColor: Colors.blue.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.blue.shade900 : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
      ],
    );
  }

  Widget _buildCopyRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 70, // Fixed width for alignment
                child: Text("$label:", style: const TextStyle(fontSize: 13, color: Colors.black54)),
              ),
              Expanded(
                child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label copied!")));
          },
          child: Container(
            padding: const EdgeInsets.all(4),
            child: const Icon(Icons.copy, size: 16, color: Colors.blue),
          ),
        ),
      ],
    );
  }
}