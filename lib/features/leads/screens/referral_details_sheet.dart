import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// Import your new service
import '../../../core/services/transaction_service.dart'; // ADJUST PATH

void showReferralDetails(BuildContext context, Map<String, dynamic> data) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ReferralDetailsSheet(data: data),
  );
}

class ReferralDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> data;

  const ReferralDetailsSheet({super.key, required this.data});

  @override
  State<ReferralDetailsSheet> createState() => _ReferralDetailsSheetState();
}

class _ReferralDetailsSheetState extends State<ReferralDetailsSheet> {
  bool _isLoading = false;

  // To store data needed for the transaction
  String _fetchedArchName = "Unknown Architect";
  String _fetchedShopName = "My Shop"; // Default

  FirebaseFirestore get _db => FirebaseFirestore.instanceFor(
      app: Firebase.app(), databaseId: 'arch-connect-database');

  @override
  void initState() {
    super.initState();
    _fetchShopName();
  }

  Future<void> _fetchShopName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();

        setState(() {
          // 1. Try: data['firm']['name']
          // 2. Fallback: data['name'] (Personal Name)
          // 3. Fallback: "My Shop"
          _fetchedShopName = data?['firm']?['name'] ?? data?['name'] ?? "My Shop";
        });
      }
    }
  }


  // --- REJECTION LOGIC (Simple Update) ---
  Future<void> _rejectReferral() async {
    setState(() => _isLoading = true);
    try {
      // Rejection doesn't need the complex batch service
      final q = await _db.collection('referrals').where('referralId', isEqualTo: widget.data['referralId']).limit(1).get();
      if (q.docs.isNotEmpty) {
        await q.docs.first.reference.update({
          'status': 'rejected',
          'respondedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- CONFIRMATION LOGIC (Uses TransactionService) ---
  Future<void> _confirmReferral(double billAmount, double commissionAmount) async {
    setState(() => _isLoading = true);
    try {
      final service = TransactionService();

      // Get the doc ID (assuming 'referralId' field is unique, but better to use doc ID if we had it.
      // Using query to be safe with your data structure)
      final q = await _db.collection('referrals').where('referralId', isEqualTo: widget.data['referralId']).limit(1).get();
      final String docId = q.docs.first.id;

      await service.confirmReferral(
        referralId: docId, // Pass the actual Firestore Doc ID
        architectUid: widget.data['architectUid'],
        architectName: _fetchedArchName,
        shopName: _fetchedShopName,
        billAmount: billAmount,
        commissionAmount: commissionAmount,
        commissionPercent: (widget.data['commissionPercent'] ?? 0).toDouble(),
        projectName: widget.data['projectName'] ?? "Project",
        projectType: widget.data['projectType'] ?? "General",
      );

      if (mounted) {
        Navigator.pop(context); // Close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Referral Accepted! Ledgers Updated. 🚀"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- UI: BILL ENTRY DIALOG ---
  void _showAcceptanceDialog(BuildContext context) {
    final TextEditingController billController = TextEditingController();
    final double commPercent = (widget.data['commissionPercent'] ?? 0).toDouble();
    double calculatedCommission = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Finalize Agreement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Enter the final agreed bill amount. Commission will be calculated automatically.",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  // INPUT FIELD
                  TextField(
                    controller: billController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      prefixText: "₹ ",
                      labelText: "Bill Amount",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    onChanged: (value) {
                      final double bill = double.tryParse(value) ?? 0;
                      setStateDialog(() {
                        calculatedCommission = (bill * commPercent) / 100;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // CALCULATION DISPLAY
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Commission ($commPercent%)", style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
                        Text(
                            "₹${calculatedCommission.toStringAsFixed(0)}",
                            style: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.w900, fontSize: 18)
                        ),
                      ],
                    ),
                  )
                ],
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final double bill = double.tryParse(billController.text) ?? 0;
                    if (bill > 0) {
                      Navigator.pop(context); // Close dialog
                      _confirmReferral(bill, calculatedCommission); // Trigger the Service
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text("Confirm & Accept", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            );
          },
        );
      },
    );
  }

  // --- HELPERS (Call, Image, etc) ---
  // ... (Paste _makePhoneCall and _showFullImage from previous code here) ...
  Future<void> _makePhoneCall(String phoneNumber) async {
    final String cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    final Uri launchUri = Uri(scheme: 'tel', path: cleanNumber);
    try { await launchUrl(launchUri); } catch (e) { /* ignore */ }
  }

  void _showFullImage(BuildContext context, String? imageUrl) {
    if (imageUrl == null) return;
    showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.transparent, child: InteractiveViewer(child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(imageUrl)))));
  }


  @override
  Widget build(BuildContext context) {
    final status = widget.data['status'] ?? 'pending';
    final isPending = status == 'pending';
    final projectType = (widget.data['projectType'] ?? 'General').toString().toUpperCase();

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 20),
                  child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // HEADER
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(widget.data['projectName'] ?? "Project Details", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.2))),
                        const SizedBox(width: 12),
                        _buildStatusPill(status),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // DEAL CARD
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade50, Colors.white],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade100),
                          boxShadow: [
                            BoxShadow(color: Colors.blue.shade50.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
                          ]
                      ),
                      child: _buildDealContent(widget.data, projectType), // <--- Extracted Logic
                    ),
                    const SizedBox(height: 32),

                    // ARCHITECT PROFILE (With Name Capture)
                    Text("REFERRAL SOURCE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 11, letterSpacing: 1.0)),
                    const SizedBox(height: 12),
                    FutureBuilder<DocumentSnapshot>(
                      future: _db.collection('users').doc(widget.data['architectUid']).get(),
                      builder: (context, snapshot) {
                        String name = "Loading...";
                        String firm = "";
                        String phone = "";
                        String? photoUrl;
                        bool isVerified = false;

                        if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
                          final userData = snapshot.data!.data() as Map<String, dynamic>;
                          name = userData['name'] ?? "Unknown Architect";

                          // CAPTURE THE NAME FOR THE LEDGER
                          // We use WidgetsBinding to avoid setState during build
                          if (_fetchedArchName != name) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _fetchedArchName = name);
                            });
                          }

                          phone = userData['phone'] ?? "";
                          photoUrl = userData['profilePhotoUrl'];
                          if (userData['firm'] is Map) {
                            firm = userData['firm']['name'] ?? "Independent Architect";
                          }
                          isVerified = (userData['kycStatus'] == 'verified');
                        }

                        return Row(
                          children: [
                            GestureDetector(
                              onTap: () => _showFullImage(context, photoUrl),
                              child: Container(
                                width: 56, height: 56,
                                decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.shade300),
                                    image: photoUrl != null
                                        ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                                        : null
                                ),
                                child: photoUrl == null ? const Icon(Icons.person, color: Colors.grey) : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), if (isVerified) ...[const SizedBox(width: 6), const Icon(Icons.verified, size: 16, color: Colors.blue)]]),
                                  Text(firm, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                                  if (phone.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4.0), child: Row(children: [Text(phone, style: TextStyle(fontSize: 12, color: Colors.grey.shade800, fontWeight: FontWeight.w600))])),
                                ],
                              ),
                            ),
                            if (phone.isNotEmpty) IconButton(onPressed: () => _makePhoneCall(phone), icon: const Icon(Icons.phone, color: Colors.green), style: IconButton.styleFrom(backgroundColor: Colors.green.shade50))
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // CLIENT INFO
                    Text("CLIENT INFORMATION", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade500, fontSize: 11, letterSpacing: 1.0)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(16)),
                      child: Column(children: [
                        _buildDetailRow(Icons.person_outline, widget.data['clientInfo']['name']),
                        const Divider(height: 24),
                        _buildDetailRow(Icons.phone_outlined, widget.data['clientInfo']['phone']),
                        const Divider(height: 24),
                        _buildDetailRow(Icons.location_on_outlined, widget.data['clientInfo']['address']),
                      ]),
                    ),
                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          ),

          if (isPending)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))]),
                child: Row(
                  children: [
                    Expanded(child: OutlinedButton(
                        onPressed: _isLoading ? null : () => _rejectReferral(),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: Text("Pass", style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold)))),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: ElevatedButton(
                        onPressed: _isLoading ? null : () => _showAcceptanceDialog(context),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                        child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : const Text("Accept Referral", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)))),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Same helpers as before...
  Widget _buildStatusPill(String status) {
    Color color = Colors.orange;
    if (status == 'rejected') color = Colors.red;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)));
  }

  Widget _buildDetailRow(IconData icon, String? text) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, size: 20, color: Colors.grey.shade400), const SizedBox(width: 16), Expanded(child: Text(text ?? 'N/A', style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)))]);
  }

  Widget _buildDealContent(Map<String, dynamic> data, String projectType) {
    final status = data['status'] ?? 'pending';

    // CASE 1: CONFIRMED (Show Real Money)
    if (status == 'confirmed') {
      final double bill = (data['billAmount'] ?? 0).toDouble();
      final double comm = (data['commissionAmount'] ?? 0).toDouble();

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: The Sale (Bill Amount)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("TOTAL SALE", style: TextStyle(color: Colors.blue.shade900, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text(
                  "₹${bill.toStringAsFixed(0)}",
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 24, fontWeight: FontWeight.w800)
              ),
            ],
          ),

          Container(height: 40, width: 1, color: Colors.blue.shade100),

          // Right: The Cost (Commission)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("COMMISSION", style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const SizedBox(height: 4),
              Text(
                  "₹${comm.toStringAsFixed(0)}",
                  style: TextStyle(color: Colors.green.shade700, fontSize: 24, fontWeight: FontWeight.w800)
              ),
            ],
          ),
        ],
      );
    }

    // CASE 2: PENDING/OTHER (Show Percentage & Type)
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("COMMISSION", style: TextStyle(color: Colors.blue.shade900, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Text(
                "${data['commissionPercent']}%",
                style: TextStyle(color: Colors.blue.shade800, fontSize: 32, fontWeight: FontWeight.w800)
            ),
          ],
        ),

        Container(height: 40, width: 1, color: Colors.blue.shade100),

        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("TYPE", style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(height: 4),
            Text(
                projectType,
                style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)
            ),
          ],
        ),
      ],
    );
  }
}