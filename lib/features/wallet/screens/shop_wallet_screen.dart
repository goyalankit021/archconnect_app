import 'package:archconnect_app/features/wallet/screens/shop_transaction_history_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'ledger_history_screen.dart';

const Color tBackgroundColor = Color(0xFFF9FAFB);

// --- PROVIDERS (Same as before) ---
final shopStatsProvider = StreamProvider.autoDispose<DocumentSnapshot>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'arch-connect-database')
      .collection('shop_stats').doc(uid).snapshots();
});

final shopLedgersProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return const Stream.empty();
  return FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'arch-connect-database')
      .collection('ledgers')
      .where('shopId', isEqualTo: uid)
      .orderBy('lastTransactionAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
});

// --- 2. NEW PROVIDER: PLATFORM BANK DETAILS ---
final platformBankDetailsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final doc = await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'arch-connect-database')
      .collection('platform_settings')
      .doc('payment_config')
      .get();
  return doc.data() ?? {};
});

class ShopWalletScreen extends ConsumerWidget {
  const ShopWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(shopStatsProvider);
    final ledgersAsync = ref.watch(shopLedgersProvider);

    return Scaffold(
      backgroundColor: tBackgroundColor,
      appBar: AppBar(
        title: const Text("My Business", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HERO STATS CARD ---
            statsAsync.when(
              data: (snapshot) {
                final data = snapshot.data() as Map<String, dynamic>? ?? {};
                return _buildTotalRevenueCard(context, data);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text("Stats unavailable"),
            ),
            // --- INSERT THIS NEW BLOCK HERE ---
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  "Balance updates after admin verification (12-24 hrs)",
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // --- 2. SECTION TITLE ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Partner Ledgers", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            // --- 3. LEDGERS LIST ---
            ledgersAsync.when(
              data: (ledgers) {
                if (ledgers.isEmpty) return _buildEmptyState();
                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: ledgers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildLedgerCard(context, ledgers[index]),
                );
              },
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
              error: (e, s) => Center(child: Text("Error: $e")),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGET: PREMIUM REVENUE CARD ---
  Widget _buildTotalRevenueCard(BuildContext context, Map<String, dynamic> data) {
    final double revenue = (data['totalRevenue'] ?? 0).toDouble();
    final double paid = (data['totalPaid'] ?? 0).toDouble();
    final double due = (data['totalDue'] ?? 0).toDouble();
    final double comm = (data['totalCommission'] ?? 0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade900, Colors.green.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Business Generated", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(revenue),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              _buildStatItem("Total Paid", "₹${_compactFormat(paid)}", Icons.verified),
              Container(height: 30, width: 1, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 20)),
              _buildStatItem("Payable", "₹${_compactFormat(due)}", Icons.pending_actions),
              Container(height: 30, width: 1, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 20)),
              _buildStatItem("Total Comm.", "₹${_compactFormat(comm)}", Icons.pie_chart_outline),
            ],
          ),

          const SizedBox(height: 24),

          // --- 1. PAY DUES BUTTON ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showPaymentDetailsSheet(context),
              icon: const Icon(Icons.account_balance, size: 18, color: Colors.green),
              label: const Text("CLEAR DUES", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          // --- 2. VIEW HISTORY LINK ---
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShopTransactionHistoryScreen(),
                  ),
                );
              },
              child: const Text("View Transaction History", style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  // --- DYNAMIC PAYMENT SHEET ---
  void _showPaymentDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) {
        // Use Consumer to fetch data inside the sheet
        return Consumer(
          builder: (context, ref, child) {
            final bankDetailsAsync = ref.watch(platformBankDetailsProvider);

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Platform Bank Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  bankDetailsAsync.when(
                    data: (data) {
                      if (data.isEmpty) return const Text("Bank details not configured.");

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Transfer the due commission to the following account:", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 20),

                          _buildCopyableRow(context, "Beneficiary", data['beneficiaryName'] ?? "ArchConnect"),
                          const SizedBox(height: 16),
                          _buildCopyableRow(context, "Bank Name", data['bankName'] ?? "N/A"),
                          const SizedBox(height: 16),
                          _buildCopyableRow(context, "Account No", data['accountNumber'] ?? "N/A"),
                          const SizedBox(height: 16),
                          _buildCopyableRow(context, "IFSC Code", data['ifscCode'] ?? "N/A"),
                          const SizedBox(height: 16),
                          _buildCopyableRow(context, "UPI ID", data['upiId'] ?? "N/A"),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text("Error loading details: $e"),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCopyableRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 20, color: Colors.blue),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$label copied!")));
          },
        )
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 12),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildLedgerCard(BuildContext context, Map<String, dynamic> data) {
    final String name = data['architectName'] ?? "Unknown Architect";
    final double totalSales = (data['totalSales'] ?? 0).toDouble();
    final double dueAmount = (data['dueAmount'] ?? 0).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LedgerHistoryScreen(
                  partnerId: data['architectUid'], // Ensure this field exists in ledger
                  partnerName: name,
                  isArchitectView: false,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: Icon(Icons.person, color: Colors.blue.shade700, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text("Sales: ₹${_compactFormat(totalSales)}", style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: dueAmount > 0 ? Colors.red.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: dueAmount > 0 ? Colors.red.shade100 : Colors.green.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(dueAmount > 0 ? "PAYABLE" : "SETTLED", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: dueAmount > 0 ? Colors.red.shade800 : Colors.green.shade800)),
                      if (dueAmount > 0)
                        Text("₹${_compactFormat(dueAmount)}", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: dueAmount > 0 ? Colors.red.shade900 : Colors.green.shade900)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 40),
          Icon(Icons.storefront_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text("No business history yet.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount == 0) return "₹0.00";
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return format.format(amount);
  }

  String _compactFormat(double amount) {
    if (amount >= 100000) return "${(amount / 100000).toStringAsFixed(1)}L";
    if (amount >= 1000) return "${(amount / 1000).toStringAsFixed(1)}k";
    return amount.toStringAsFixed(0);
  }
}