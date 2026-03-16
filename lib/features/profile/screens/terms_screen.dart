import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Terms & Services", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("1. Introduction"),
            _buildParagraph("Welcome to ArchConnect. By using our application, you agree to facilitate transparent business connections between Architects and Material Suppliers (Shops)."),

            _buildSectionTitle("2. How it Works"),
            _buildParagraph("ArchConnect serves as a bridge. Architects refer clients to registered Shops. Once a purchase is confirmed by the Shop, the transaction is logged, and the agreed commission is tracked within the app."),

            _buildSectionTitle("3. Commissions & Payments"),
            _buildParagraph("Commissions are calculated based on the successful conversion of referrals. ArchConnect tracks these amounts, but the actual fund transfer is subject to the agreement between the Architect and the Shop Owner."),

            _buildSectionTitle("4. User Responsibilities"),
            _buildParagraph("• Architects must provide genuine client leads.\n• Shops must accurately log bill amounts and honor commission agreements.\n• Any disputes regarding amounts are to be resolved between parties.\n• Architects can withdraw the commission only when shop transfers commission."),

            _buildSectionTitle("5. Data Privacy"),
            _buildParagraph("We take your privacy seriously. Your KYC documents (Aadhar/PAN) are encrypted and used solely for identity verification purposes. We do not sell your data to third parties."),

            const SizedBox(height: 40),
            Center(
              child: Text(
                "Version 1.0.0",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryColor),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, height: 1.6, color: kTextPrimary),
    );
  }
}