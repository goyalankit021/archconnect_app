import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/transaction_detail_sheet.dart';

const Color ktBackgroundColor = Color(0xFFF9FAFB);
const Color ktTextSecondary = Colors.grey;

class LedgerParams {
  final String partnerId;
  final bool isArchitectView;

  LedgerParams({required this.partnerId, required this.isArchitectView});

  @override
  bool operator ==(Object other) =>
      other is LedgerParams &&
          other.partnerId == partnerId &&
          other.isArchitectView == isArchitectView;

  @override
  int get hashCode => Object.hash(partnerId, isArchitectView);
}

final ledgerHistoryProvider = StreamProvider.autoDispose.family<List<Map<String, dynamic>>, LedgerParams>((ref, params) {
  final myUid = FirebaseAuth.instance.currentUser?.uid;
  if (myUid == null) return const Stream.empty();

  final db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'arch-connect-database')
      .collection('transactions');

  Query query;
  if (params.isArchitectView) {
    query = db.where('architectId', isEqualTo: myUid).where('shopId', isEqualTo: params.partnerId);
  } else {
    query = db.where('shopId', isEqualTo: myUid).where('architectId', isEqualTo: params.partnerId);
  }

  return query
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList());
});

class LedgerHistoryScreen extends ConsumerWidget {
  final String partnerId;
  final String partnerName;
  final bool isArchitectView;

  const LedgerHistoryScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    this.isArchitectView = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = LedgerParams(partnerId: partnerId, isArchitectView: isArchitectView);
    final historyAsync = ref.watch(ledgerHistoryProvider(params));

    return Scaffold(
      backgroundColor: ktBackgroundColor,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(partnerName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            const Text("Transaction History", style: TextStyle(color: ktTextSecondary, fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: historyAsync.when(
        data: (transactions) {
          if (transactions.isEmpty) return _buildEmptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: transactions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final txn = transactions[index];

              return GestureDetector(
                onTap: () {
                  final isCredit = txn['type'] == 'commission_credit';
                  final status = txn['status'];

                  if (isCredit && !isArchitectView && (status == 'due' || status == 'verification_pending')) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => TransactionDetailSheet(transactionData: txn),
                    );
                  }
                },
                child: _buildTransactionCard(txn),
              );
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

    final isCredit = type == 'commission_credit';
    final color = isCredit ? Colors.blue : Colors.green;
    final icon = isCredit ? Icons.add_circle_outline : Icons.check_circle_outline;

    String title = "Commission Earned";
    if (isCredit) {
      title = isArchitectView ? "Commission Earned" : "Commission Payable";
    } else {
      title = isArchitectView ? "Payout Received" : "Payment Sent";
    }

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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(projectName, style: const TextStyle(color: ktTextSecondary, fontSize: 12)),
                const SizedBox(height: 8),

                if (isCredit && billAmount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      "Bill Amount: ₹${billAmount.toStringAsFixed(0)}",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ),

                const SizedBox(height: 10),

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
    String text = status.toUpperCase();

    if (status == 'due' || status == 'pending') {
      color = Colors.orange;
    } else if (status == 'verification_pending') {
      color = Colors.blue;
      text = "VERIFYING";
    } else if (status == 'settled' || status == 'completed' || status == 'paid') {
      color = Colors.green;
      text = "SETTLED";
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
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