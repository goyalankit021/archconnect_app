import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../data/wallet_repository.dart';
import 'ledger_history_screen.dart';
import '../widgets/payout_bottom_sheet.dart';
import 'payout_history_screen.dart';

class ArchitectWalletScreen extends ConsumerWidget {
  const ArchitectWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletStreamProvider);
    final ledgersAsync = ref.watch(ledgersStreamProvider);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text("My Earnings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. MAIN BALANCE CARD ---
            walletAsync.when(
              data: (data) => _buildTotalBalanceCard(context, data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Container(padding: const EdgeInsets.all(20), child: Text("Error: $e")),
            ),

            const SizedBox(height: 30),

            // --- 2. BREAKDOWN TITLE ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Earnings by Shop",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                // Optional: Date Filter Icon could go here
              ],
            ),
            const SizedBox(height: 16),

            // --- 3. LEDGERS LIST ---
            ledgersAsync.when(
              data: (ledgers) {
                if (ledgers.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.separated(
                  physics: const NeverScrollableScrollPhysics(), // Let the page scroll
                  shrinkWrap: true,
                  itemCount: ledgers.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildLedgerCard(ledgers[index], context);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Text("Could not load history: $e"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalBalanceCard(BuildContext context, Map<String, dynamic> data) {
    final double balance = (data['balance'] ?? 0).toDouble();
    final double pending = (data['pendingBalance'] ?? 0).toDouble();
    final double totalEarned = (data['totalEarned'] ?? 0).toDouble();
    final double totalWithdrawn = (data['totalWithdrawn'] ?? 0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimaryColor, kPrimaryVariant],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: kPrimaryColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Available Balance", style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            "₹${balance.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          // ✅ NEW: WITHDRAW BUTTON
          const SizedBox(height: 24),

          // Stats Row
          Row(
            children: [
              _buildStatItem("Total Earned", "₹${totalEarned.toStringAsFixed(0)}", Icons.verified),
              Container(height: 30, width: 1, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 20)),
              _buildStatItem("Withdrawn", "₹${totalWithdrawn.toStringAsFixed(0)}", Icons.history),
              Container(height: 30, width: 1, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 20)),
              _buildStatItem("Pending", "₹${pending.toStringAsFixed(0)}", Icons.hourglass_empty),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Check if user has enough to even open the sheet
                if (balance < 1000) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Minimum balance of ₹1,000 required to withdraw."))
                  );
                  return;
                }

                // Show the Sheet
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, // Important for keyboard handling
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20))
                  ),
                  builder: (context) => PayoutBottomSheet(
                    currentBalance: balance,
                    // Pass the bank details from the wallet doc
                    bankDetails: data['bankDetails'] ?? {},
                  ),
                );
              },
              icon: const Icon(Icons.account_balance, size: 18, color: kPrimaryColor),
              label: const Text("WITHDRAW FUNDS", style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          // ✅ NEW: History Link
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PayoutHistoryScreen())
                );
              },
              child: const Text("View Withdrawal History", style: TextStyle(color: Colors.white70, fontSize: 12)),
            ),
          ),
        ],
      ),
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

  Widget _buildLedgerCard(Map<String, dynamic> ledger, BuildContext context) {
    final shopName = ledger['shopName'] ?? 'Unknown Shop';
    final totalEarned = (ledger['totalCommission'] ?? 0).toDouble();
    final due = (ledger['dueAmount'] ?? 0).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
        ],
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
                  partnerId: ledger['shopId'], // Pass the Shop's ID
                  partnerName: shopName,       // Pass the Shop's Name
                  isArchitectView: true
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // 1. Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.shade50, shape: BoxShape.circle),
                  child: const Icon(Icons.storefront, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 16),

                // 2. Name & Total
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shopName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text("Lifetime: ₹${totalEarned.toStringAsFixed(0)}", style: TextStyle(color: kTextSecondary, fontSize: 12)),
                    ],
                  ),
                ),

                // 3. Clean Status Badge (No Arrow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: due > 0 ? Colors.orange.shade50 : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: due > 0 ? Colors.orange.shade200 : Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        due > 0 ? "DUE" : "SETTLED",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: due > 0 ? Colors.orange.shade800 : Colors.green.shade800,
                        ),
                      ),
                      if (due > 0)
                        Text(
                          "₹${due.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: due > 0 ? Colors.orange.shade900 : Colors.green.shade900,
                          ),
                        ),
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
          Icon(Icons.account_balance_wallet_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text("No earnings yet.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}