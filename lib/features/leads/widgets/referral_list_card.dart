import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReferralListCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const ReferralListCard({
    super.key,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final client = data['clientInfo'] ?? {};
    final status = data['status'] ?? 'pending';
    final double commission = (data['commissionAmount'] ?? 0).toDouble();

    // LOGIC: Determine Colors & Text based on Status
    Color statusColor = Colors.orange;
    String statusText = "Pending";
    IconData statusIcon = Icons.hourglass_top;

    if (status == 'confirmed') {
      statusColor = Colors.green;
      statusText = "Confirmed";
      statusIcon = Icons.check_circle;
    } else if (status == 'rejected') {
      statusColor = Colors.red;
      statusText = "Rejected";
      statusIcon = Icons.cancel;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // 1. LEFT COLOR STRIP (Dynamic Color)
              Container(width: 6, color: statusColor),

              // 2. CONTENT
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data['projectName'] ?? "Project",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Show Commission Badge ONLY if confirmed
                          if (status == 'confirmed')
                            Row(
                              children: [
                                // Commission (The Cost)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "₹${commission.toStringAsFixed(0)}",
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                  ),
                                ),
                              ],
                            )
                          else
                            _buildDateBadge(data['createdAt']),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Subtitle (Address)
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              client['address'] ?? "No location",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(statusIcon, size: 14, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusText,
                                style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          Text(
                            "View Details >",
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateBadge(dynamic timestamp) {
    String text = "Today";
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      text = "${date.day}/${date.month}";
    }
    return Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 12));
  }
}