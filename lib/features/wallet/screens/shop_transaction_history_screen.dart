import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/transaction_card.dart';

// --- PROVIDER ---
final shopTransactionsProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();

  return FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'arch-connect-database')
      .collection('transactions')
      .where('shopId', isEqualTo: uid) // Filter for this shop
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

class ShopTransactionHistoryScreen extends ConsumerWidget {
  const ShopTransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(shopTransactionsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Transaction History", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final data = transactions[index];
              final meta = data['meta'] ?? {};

              // Map data to the generic card
              return TransactionCard(
                title: meta['description'] ?? "Commission Transaction",
                subtitle: meta['category'] != null ? "Category: ${meta['category']}" : null,
                amount: (data['amount'] ?? 0).toDouble(),
                status: data['status'] ?? 'unknown',
                date: data['createdAt'],
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
          Icon(Icons.receipt_long, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No transactions yet.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}