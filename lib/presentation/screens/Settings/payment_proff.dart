// lib/presentation/screens/Settings/payment_proff_web_to_app.dart
// ✅ WEB → MOBILE APP REDIRECT SOLUTION

import 'dart:io';
import 'package:demo/data/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// ✅ Conditional import for web
import 'dart:html' as html' if (dart.library.io) 'dart:io';

class PaymentProofScreen extends StatefulWidget {
  final int orderId;
  final int userId;
  final double totalAmount;
  final String upiId;

  const PaymentProofScreen({
    super.key,
    required this.orderId,
    required this.userId,
    required this.totalAmount,
    required this.upiId,
  });

  @override
  State<PaymentProofScreen> createState() => _PaymentProofScreenState();
}

class _PaymentProofScreenState extends State<PaymentProofScreen> {
  File? _selectedImage;
  final TextEditingController _txnIdController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  String _flowStep = 'idle';

  @override
  void dispose() {
    _txnIdController.dispose();
    super.dispose();
  }

  // ✅ WEB → APP REDIRECT: Build UPI payment URL
  String _buildUpiUrl(String scheme) {
    final upiParams = 'pa=${Uri.encodeComponent(widget.upiId)}'
        '&pn=${Uri.encodeComponent("Shree Nails")}'
        '&am=${widget.totalAmount.toInt()}'
        '&cu=INR'
        '&tn=${Uri.encodeComponent("Order #${widget.orderId}")}';

    return '$scheme://upi/pay?$upiParams';
  }

  // ✅ ANDROID INTENT URL (works from browser)
  String _buildIntentUrl(String packageName, String scheme) {
    final upiParams = 'pa=${Uri.encodeComponent(widget.upiId)}'
        '&pn=${Uri.encodeComponent("Shree Nails")}'
        '&am=${widget.totalAmount.toInt()}'
        '&cu=INR'
        '&tn=${Uri.encodeComponent("Order #${widget.orderId}")}';

    return 'intent://upi/pay?$upiParams#Intent;scheme=$scheme;package=$packageName;end';
  }

  // ✅ OPEN UPI APP FROM WEB
  Future<void> _openUpiAppFromWeb(String appName, String packageName, String scheme) async {
    setState(() => _flowStep = 'upi_open');

    if (kIsWeb) {
      // ✅ WEB: Use Intent URL or window.location
      final intentUrl = _buildIntentUrl(packageName, scheme);
      
      debugPrint("🚀 Opening from web: $intentUrl");
      
      try {
        // Method 1: Try url_launcher
        final uri = Uri.parse(intentUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint("✅ Launched via url_launcher");
          return;
        }
      } catch (e) {
        debugPrint("❌ url_launcher failed: $e");
      }

      // Method 2: Direct window.location (web only)
      try {
        html.window.location.href = intentUrl;
        debugPrint("✅ Redirected via window.location");
        
        // Set timer to check if user returns
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            // If still on page after 3 seconds, app might not have opened
            _showAppNotInstalledDialog(appName);
          }
        });
        return;
      } catch (e) {
        debugPrint("❌ window.location failed: $e");
      }

      // Method 3: Create invisible link and click it
      try {
        final anchor = html.AnchorElement(href: intentUrl);
        anchor.click();
        debugPrint("✅ Triggered via anchor click");
      } catch (e) {
        debugPrint("❌ anchor click failed: $e");
      }

    } else {
      // ✅ MOBILE: Direct app launch
      final upiUrl = _buildUpiUrl(scheme);
      try {
        final uri = Uri.parse(upiUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        _showSnack("Could not open $appName", isError: true);
      }
    }
  }

  void _showAppNotInstalledDialog(String appName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("$appName Not Installed?"),
        content: Text(
          "If $appName didn't open:\n\n"
          "1. Make sure the app is installed\n"
          "2. Try clicking the button again\n"
          "3. Or use 'Copy UPI ID' option below",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _flowStep = 'returned');
            },
            child: const Text("I have paid"),
          ),
        ],
      ),
    );
  }

  // ✅ SHOW UPI APP CHOOSER
  Future<void> _showUpiApps() async {
    final apps = [
      {
        'name': 'Google Pay',
        'package': 'com.google.android.apps.nbu.paisa.user',
        'scheme': 'gpay',
        'icon': Icons.g_mobiledata,
        'color': Colors.blue.shade600,
      },
      {
        'name': 'PhonePe',
        'package': 'com.phonepe.app',
        'scheme': 'phonepe',
        'icon': Icons.phone_android,
        'color': const Color(0xFF5F259F),
      },
      {
        'name': 'Paytm',
        'package': 'net.one97.paytm',
        'scheme': 'paytmmp',
        'icon': Icons.payment,
        'color': Colors.blue.shade800,
      },
      {
        'name': 'BHIM',
        'package': 'in.org.npci.upiapp',
        'scheme': 'upi',
        'icon': Icons.account_balance,
        'color': Colors.orange.shade700,
      },
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              "Select UPI App",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Pay ₹${widget.totalAmount.toStringAsFixed(0)} to ${widget.upiId}",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // App list
            ...apps.map((app) => _buildAppTile(app)),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),

            // ✅ "I have paid" button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _flowStep = 'returned');
                },
                icon: Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade600,
                ),
                label: Text(
                  "I have completed payment",
                  style: GoogleFonts.poppins(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.green.shade400, width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            // ✅ Copy UPI ID option
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showCopyUpiDialog();
                },
                icon: const Icon(Icons.copy),
                label: Text(
                  "Copy UPI ID (Manual Payment)",
                  style: GoogleFonts.poppins(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppTile(Map<String, dynamic> app) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (app['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            app['icon'] as IconData,
            color: app['color'] as Color,
            size: 28,
          ),
        ),
        title: Text(
          app['name'] as String,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: () {
          Navigator.pop(context);
          _openUpiAppFromWeb(
            app['name'] as String,
            app['package'] as String,
            app['scheme'] as String,
          );
        },
      ),
    );
  }

  void _showCopyUpiDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Manual Payment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Copy UPI ID and pay manually:"),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      widget.upiId,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Copy to clipboard
                      Clipboard.setData(ClipboardData(text: widget.upiId));
                      _showSnack("✅ UPI ID copied!");
                    },
                    icon: const Icon(Icons.copy),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Amount: ₹${widget.totalAmount.toStringAsFixed(0)}",
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _flowStep = 'returned');
            },
            child: const Text("I have paid"),
          ),
        ],
      ),
    );
  }

  // ─── PICK IMAGE ───
  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      _showSnack("Error: $e", isError: true);
    }
  }

  // ─── UPLOAD PROOF ───
  Future<void> _uploadProof() async {
    if (_txnIdController.text.trim().isEmpty) {
      _showSnack("Enter UPI Transaction ID", isError: true);
      return;
    }
    if (_selectedImage == null) {
      _showSnack("Select payment screenshot", isError: true);
      return;
    }

    setState(() => _isUploading = true);

    try {
      final result = await ApiService.uploadPaymentProof(
        orderId: widget.orderId,
        userId: widget.userId,
        screenshotFile: _selectedImage!,
        upiTransactionId: _txnIdController.text.trim(),
      );

      setState(() => _isUploading = false);

      if (result != null && result['success'] == true) {
        _showSuccessDialog();
      } else {
        _showSnack("Upload failed", isError: true);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showSnack("Error: $e", isError: true);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Payment Submitted!"),
        content: Text(
          "Order #${widget.orderId}\n\nYour payment is under review.\nAdmin will verify soon.",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("View Orders"),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Complete Payment",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildOrderCard(),
                  const SizedBox(height: 24),
                  _buildStep1(),
                  if (_flowStep == 'returned') ...[
                    const SizedBox(height: 24),
                    _buildStep2(),
                  ],
                  const SizedBox(height: 24),
                  _buildInstructions(),
                ],
              ),
            ),
    );
  }

  Widget _buildOrderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order Details",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _infoRow("Order ID", "#${widget.orderId}"),
          _infoRow("Amount", "₹${widget.totalAmount.toStringAsFixed(0)}"),
          _infoRow("UPI ID", widget.upiId),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Step 1: Pay via UPI",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          if (_flowStep == 'upi_open')
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.pending_outlined, color: Colors.orange.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Waiting for payment... Complete in UPI app and return here.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _showUpiApps,
                icon: const Icon(Icons.account_balance_wallet_rounded, size: 22),
                label: Text(
                  "Pay ₹${widget.totalAmount.toStringAsFixed(0)} via UPI",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3DF5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final canSubmit = _txnIdController.text.trim().isNotEmpty && _selectedImage != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Step 2: Upload Proof",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _txnIdController,
            decoration: InputDecoration(
              labelText: "UPI Transaction ID *",
              hintText: "e.g. 412345678901",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.receipt_long),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedImage != null ? Colors.green : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          "Tap to upload screenshot",
                          style: GoogleFonts.poppins(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: canSubmit ? _uploadProof : null,
              icon: const Icon(Icons.cloud_upload),
              label: const Text("Submit Screenshot"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                "How it works",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...[ 
            "1. Click 'Pay via UPI' button above",
            "2. Select your UPI app (GPay/PhonePe/etc)",
            "3. Complete payment in the app",
            "4. Take screenshot of success message",
            "5. Return here and click 'I have paid'",
            "6. Upload transaction ID and screenshot",
          ].map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• ", style: TextStyle(color: Colors.blue.shade700)),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13)),
          Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}