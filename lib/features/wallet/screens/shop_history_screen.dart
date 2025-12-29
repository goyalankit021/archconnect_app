import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/wallet_repository.dart';

class ShopHistoryScreen extends ConsumerWidget {
  final String shopId;
  final String shopName;

  const ShopHistoryScreen({
    super.key,
    required this.shopId,
    required this.shopName
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(shopHistoryProvider(shopId));

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shopName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            const Text("Transaction History", style: TextStyle(color: kTextSecondary, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: historyAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) return _buildEmptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildTransactionCard(transactions[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> data) {
    final type = data['type'] ?? 'unknown';
    final amount = (data['amount'] ?? 0).toDouble();
    final status = data['status'] ?? 'pending';
    final billAmount = (data['billAmount'] ?? 0).toDouble();
    final Timestamp? timestamp = data['createdAt'];

    final meta = data['meta'] as Map<String, dynamic>? ?? {};
    final projectName = meta['projectName'] ?? meta['description'] ?? 'Unknown Project';

    // Visual Logic
    final isCredit = type == 'commission_credit';
    final color = isCredit ? Colors.blue : Colors.green;
    final icon = isCredit ? Icons.add_circle_outline : Icons.check_circle_outline;
    final title = isCredit ? "Commission Earned" : "Payout Received";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(projectName, style: TextStyle(color: kTextSecondary, fontSize: 12)),
                const SizedBox(height: 8),

                // ✅ NEW: Show Bill Amount only for Commissions
                if (isCredit && billAmount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Bill Amount: ₹${billAmount.toStringAsFixed(0)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ),

                const SizedBox(height: 10),

                // Date & Status Row
                Row(
                  children: [
                    Text(_formatDate(timestamp), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                    const Spacer(),
                    _buildStatusBadge(status),
                  ],
                ),
              ],
            ),
          ),

          // Amount
          Column(
            children: [
              Text(
                "₹${amount.toStringAsFixed(0)}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCredit ? Colors.black : Colors.green,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    if (status == 'due' || status == 'pending') color = Colors.orange;
    else if (status == 'settled' || status == 'completed') color = Colors.green;
    else color = Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text("No transactions yet", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }
}