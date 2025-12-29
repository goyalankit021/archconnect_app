import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ReferralDetailScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const ReferralDetailScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Extract Data Helpers
    final client = data['clientInfo'] as Map<String, dynamic>? ?? {};
    final status = data['status'] ?? 'pending';
    final notes = data['notes'] ?? 'No notes provided.';
    final materials = List<String>.from(data['materialCategories'] ?? []);

    // Financials
    final billAmount = (data['billAmount'] ?? 0).toDouble();
    final expectedAmount = (data['expectedAmount'] ?? 0).toDouble();
    final commissionAmt = (data['commissionAmount'] ?? 0).toDouble();

    // Logic: Show money if we have a real bill OR a confirmed expectation
    final bool showFinancials = (status == 'confirmed' || status == 'completed') && (billAmount > 0 || expectedAmount > 0);

    // Status Color Logic
    Color color;
    String statusText;
    switch(status) {
      case 'confirmed': color = Colors.blue; statusText = "Accepted & Processing"; break;
      case 'completed': color = Colors.green; statusText = "Completed & Paid"; break;
      case 'rejected': color = Colors.red; statusText = "Declined"; break;
      default: color = Colors.orange; statusText = "Pending Review";
    }

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Referral Details", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. STATUS BANNER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: color, size: 30),
                  const SizedBox(height: 8),
                  Text(statusText.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ✅ 2. FINANCIAL CARD (New Addition)
            if (showFinancials) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
                  border: Border.all(color: Colors.green.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long, color: Colors.green),
                        const SizedBox(width: 8),
                        Text("Financial Details", style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildFinanceRow("Bill Amount", billAmount > 0 ? billAmount : expectedAmount, isBold: true),
                    const SizedBox(height: 8),
                    _buildFinanceRow("Your Commission (5%)", commissionAmt > 0 ? commissionAmt : (expectedAmount * 0.05), isGreen: true),

                    if (status == 'confirmed')
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Text(
                          "⚠️ Please verify this amount with the shop.",
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade800, fontStyle: FontStyle.italic),
                        ),
                      )
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 3. PROJECT INFO
            _buildSectionHeader("Project Details"),
            _buildInfoRow(Icons.work_outline, "Project Name", data['projectName'] ?? 'N/A'),
            _buildInfoRow(Icons.category_outlined, "Type", (data['projectType'] ?? 'N/A').toString().toUpperCase()),
            _buildInfoRow(Icons.storefront, "Sent To", data['shopName'] ?? 'Unknown Shop'),

            const Divider(height: 32),

            // 4. CLIENT INFO
            _buildSectionHeader("Client Information"),
            _buildInfoRow(Icons.person_outline, "Name", client['name'] ?? 'N/A'),
            _buildInfoRow(Icons.phone_outlined, "Phone", client['phone'] ?? 'N/A'),
            _buildInfoRow(Icons.location_on_outlined, "Site Address", client['address'] ?? 'N/A'),

            const Divider(height: 32),

            // 5. REQUIREMENTS
            _buildSectionHeader("Requirements"),
            if (materials.isNotEmpty)
              Wrap(
                spacing: 8,
                children: materials.map((m) => Chip(
                  label: Text(m.toUpperCase(), style: const TextStyle(fontSize: 10)),
                  backgroundColor: kSurfaceColor,
                )).toList(),
              )
            else
              const Text("No specific categories selected", style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 16),
            const Text("Architect's Notes:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: kTextSecondary)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Text(notes, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceRow(String label, double amount, {bool isBold = false, bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: isGreen ? Colors.green.shade700 : kTextSecondary, fontWeight: isGreen ? FontWeight.bold : FontWeight.normal)),
        Text(
            "₹${amount.toStringAsFixed(0)}",
            style: TextStyle(
                fontSize: isBold || isGreen ? 18 : 16,
                fontWeight: FontWeight.bold,
                color: isGreen ? Colors.green.shade800 : Colors.black
            )
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}