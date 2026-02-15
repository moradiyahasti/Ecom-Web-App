// lib/presentation/screens/admin/payment_verification_screen.dart
// ============================================================
// ADMIN PANEL: View & verify payment screenshots
// ============================================================

import 'dart:convert';
import 'package:demo/data/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

class PaymentVerificationScreen extends StatefulWidget {
  final int adminId; // Pass your admin user's ID

  const PaymentVerificationScreen({super.key, required this.adminId});

  @override
  State<PaymentVerificationScreen> createState() =>
      _PaymentVerificationScreenState();
}

class _PaymentVerificationScreenState
    extends State<PaymentVerificationScreen> {
  List<Map<String, dynamic>> _payments = [];
  bool _isLoading  = true;
  String _filter   = 'pending'; // pending | all

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  // ---- Load data from PHP backend ----
  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);

    try {
      final endpoint = _filter == 'pending'
          ? '/api/payment-proof/admin/pending'
          : '/api/payment-proof/admin/all';

      final url      = Uri.parse("${ApiService.baseUrl}$endpoint");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() => _payments =
              List<Map<String, dynamic>>.from(data['data']));
        }
      }
    } catch (e) {
      debugPrint("Error loading payments: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ---- Approve or Reject ----
  Future<void> _verify(int orderId, bool approve) async {
    String? reason;

    // Ask for rejection reason if rejecting
    if (!approve) {
      reason = await _askRejectionReason();
      if (reason == null) return; // user cancelled
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(approve ? "Approve Payment?" : "Reject Payment?"),
        content: Text(approve
            ? "Order #$orderId will be moved to PROCESSING."
            : "Order #$orderId will be CANCELLED.\nReason: ${reason ?? '-'}"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: approve ? Colors.green : Colors.red),
            child: Text(approve ? "Approve" : "Reject",
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ApiService.adminVerifyPayment(
      orderId: orderId,
      adminId: widget.adminId,
      isApproved: approve,
      rejectionReason: reason,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(success ? (approve ? "✅ Approved!" : "❌ Rejected") : "Failed"),
        backgroundColor: success
            ? (approve ? Colors.green : Colors.red)
            : Colors.grey,
      ));

      if (success) _loadPayments(); // refresh list
    }
  }

  Future<String?> _askRejectionReason() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Rejection Reason"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
              hintText: "e.g. Payment amount mismatch"),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(
                context,
                controller.text.trim().isEmpty
                    ? "Payment not verified"
                    : controller.text.trim()),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  // ---- Full-screen image viewer ----
  void _viewImage(String url) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text("Payment Screenshot"),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                "${ApiService.baseUrl}$url",
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image, color: Colors.white, size: 80),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- BUILD ----
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text("Payment Verification",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF5B3DF5),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh),
            tooltip: "Refresh",
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFF5B3DF5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip("Pending", "pending"),
                const SizedBox(width: 8),
                _filterChip("All", "all"),
                const Spacer(),
                if (!_isLoading)
                  Text("${_payments.length} results",
                      style: GoogleFonts.poppins(
                          color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _loadPayments,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _payments.length,
                    itemBuilder: (_, i) => _buildCard(_payments[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> p) {
    final orderId   = p['order_id'];
    final amount    = p['total_amount']?.toString() ?? '?';
    final userName  = p['user_name'] ?? 'Unknown';
    final userEmail = p['user_email'] ?? '';
    final txnId     = p['upi_transaction_id'];
    final imgUrl    = p['screenshot_url'] as String?;
    final uploaded  = p['uploaded_at'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B3DF5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text("Order #$orderId",
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF5B3DF5))),
                ),
                const Spacer(),
                Text("₹$amount",
                    style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700)),
              ],
            ),
            const SizedBox(height: 12),

            // User info
            _infoRow(Icons.person_outline, userName),
            _infoRow(Icons.email_outlined, userEmail),
            if (txnId != null) _infoRow(Icons.tag, "TXN: $txnId"),
            _infoRow(Icons.access_time, uploaded.toString().substring(0, 16)),

            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 8),

            // Screenshot
            if (imgUrl != null) ...[
              Text("Payment Screenshot",
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _viewImage(imgUrl),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.network(
                        "${ApiService.baseUrl}$imgUrl",
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          color: Colors.grey.shade100,
                          child: const Center(
                              child: Icon(Icons.broken_image, size: 50)),
                        ),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            height: 200,
                            color: Colors.grey.shade100,
                            child: const Center(
                                child: CircularProgressIndicator()),
                          );
                        },
                      ),
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.zoom_in,
                              color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _verify(orderId, false),
                    icon: const Icon(Icons.close, size: 18, color: Colors.red),
                    label: Text("Reject",
                        style: GoogleFonts.poppins(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _verify(orderId, true),
                    icon: const Icon(Icons.check, size: 18),
                    label: Text("Approve",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _filter == 'pending'
                ? "No pending verifications"
                : "No payment proofs found",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: _loadPayments, child: const Text("Refresh")),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = value);
        _loadPayments();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white54),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: selected ? const Color(0xFF5B3DF5) : Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey.shade700)),
          ),
        ],
      ),
    );
  }
}