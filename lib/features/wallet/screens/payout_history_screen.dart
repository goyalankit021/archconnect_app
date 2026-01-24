import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/wallet_repository.dart';
import '../widgets/transaction_card.dart';

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
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = payouts[index];

              // --- MAPPING DATA TO SHARED CARD ---
              return TransactionCard(
                title: "Withdrawal Request", // Static title for this screen

                // Map the fields
                amount: (data['amount'] ?? 0).toDouble(),
                status: data['status'] ?? 'requested',
                date: data['requestedAt'], // Using 'requestedAt' for architect history

                // Optional: Show notes if rejected
                subtitle: data['notes'] != null && data['notes'].toString().isNotEmpty
                    ? data['notes']
                    : null,
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text("Error: $e")),
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
}