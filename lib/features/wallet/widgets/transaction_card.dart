import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TransactionCard extends StatelessWidget {
  final double amount;
  final String status;
  final Timestamp? date;
  final String title;
  final String? subtitle;

  const TransactionCard({
    super.key,
    required this.amount,
    required this.status,
    required this.date,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    IconData icon = Icons.history;
    String statusText = status.toUpperCase();

    switch (status.toLowerCase()) {
      case 'settled':
      case 'completed':
      case 'paid':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        statusText = "Paid";
        break;

      case 'due':
        color = Colors.red;
        icon = Icons.pending_actions;
        statusText = "Due";
        break;

      case 'requested':
      case 'processing':
        color = Colors.orange;
        icon = Icons.hourglass_top;
        statusText = "Processing";
        break;

      case 'rejected':
      case 'cancelled':
        color = Colors.grey;
        icon = Icons.block;
        statusText = "Cancelled";
        break;
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
          Container(
            padding: const EdgeInsets.all(12),
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
                Text(
                  "$statusText • ${_formatDate(date)}",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(subtitle!, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                  ),
              ],
            ),
          ),
          Text(
            "₹${amount.toStringAsFixed(0)}",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
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