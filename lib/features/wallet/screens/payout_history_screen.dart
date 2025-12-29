import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/wallet_repository.dart';

class PayoutHistoryScreen extends ConsumerWidget {
  const PayoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(payoutHistoryProvider);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("Withdrawal History", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: historyAsync.when(
        data: (payouts) {
          if (payouts.isEmpty) return _buildEmptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: payouts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _buildPayoutCard(payouts[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
      ),
    );
  }

  Widget _buildPayoutCard(Map<String, dynamic> data) {
    final amount = (data['amount'] ?? 0).toDouble();
    final status = data['status'] ?? 'requested';
    final Timestamp? requestedAt = data['requestedAt'];
    final notes = data['notes'] ?? '';

    // Status Logic
    Color color;
    IconData icon;
    String statusText;

    switch (status) {
      case 'requested':
      case 'processing':
        color = Colors.orange;
        icon = Icons.hourglass_top; // Represents "Frozen/Processing"
        statusText = "Processing";
        break;
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle;
        statusText = "Paid to Bank";
        break;
      case 'rejected':
      case 'cancelled':
        color = Colors.red;
        icon = Icons.error_outline;
        statusText = "Failed/Rejected";
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
        statusText = status.toString().toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // 1. Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),

          // 2. Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(statusText, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                const SizedBox(height: 4),
                Text(_formatDate(requestedAt), style: TextStyle(color: kTextSecondary, fontSize: 12)),
                if (notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(notes, style: TextStyle(fontSize: 11, color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
                  ),
              ],
            ),
          ),

          // 3. Amount
          Text(
            "₹${amount.toStringAsFixed(0)}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No withdrawals yet.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return "";
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}