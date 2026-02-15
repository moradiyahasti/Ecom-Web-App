// lib/presentation/screens/Settings/payment_proff.dart
// ✅ PRODUCTION READY: Web → UPI App Redirect Solution

import 'dart:io';
import 'package:demo/data/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// ✅ Conditional import for web
import 'dart:html' as html show window;

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

class _PaymentProofScreenState extends State<PaymentProofScreen>
    with WidgetsBindingObserver {
  File? _selectedImage;
  final TextEditingController _txnIdController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  String _flowStep = 'idle'; // 'idle' | 'upi_open' | 'returned'

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      WidgetsBinding.instance.addObserver(this);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _txnIdController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _flowStep == 'upi_open') {
      debugPrint("📲 User returned from UPI app");
      setState(() => _flowStep = 'returned');
    }
  }

  // ─── BUILD UPI PAYMENT URL ───────────────────────────────
  String _buildUpiUrl(String scheme) {
    final params =
        'pa=${Uri.encodeComponent(widget.upiId)}'
        '&pn=${Uri.encodeComponent("Shree Nails")}'
        '&am=${1.toInt()}'
        '&cu=INR'
        '&tn=${Uri.encodeComponent("Order #${widget.orderId}")}';

    return '$scheme://upi/pay?$params';
  }

  // ─── BUILD ANDROID INTENT URL ───────────────────────────
  String _buildIntentUrl(String packageName, String scheme) {
    final params =
        'pa=${Uri.encodeComponent(widget.upiId)}'
        '&pn=${Uri.encodeComponent("Shree Nails")}'
        '&am=${1.toInt()}'
        '&cu=INR'
        '&tn=${Uri.encodeComponent("Order #${widget.orderId}")}';

    return 'intent://upi/pay?$params#Intent;scheme=$scheme;package=$packageName;end';
  }

  // ─── OPEN UPI APP (WEB + MOBILE) ─────────────────────────
  Future<void> _openUpiApp(
    String appName,
    String packageName,
    String scheme,
  ) async {
    setState(() => _flowStep = 'upi_open');

    if (kIsWeb) {
      // ✅ WEB: Use Intent URL with window.location.href
      final intentUrl = _buildIntentUrl(packageName, scheme);

      debugPrint("🚀 WEB REDIRECT: $intentUrl");

      try {
        // Method 1: Direct window.location redirect
        html.window.location.href = intentUrl;

        debugPrint("✅ Redirected to $appName via window.location");

        // Wait 3 seconds to check if user left
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            // User might still be here - show fallback option
            _showAppNotOpenedDialog(appName);
          }
        });
      } catch (e) {
        debugPrint("❌ window.location failed: $e");

        // Fallback: Try url_launcher
        try {
          final uri = Uri.parse(intentUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            debugPrint("✅ Launched via url_launcher");
          }
        } catch (e2) {
          debugPrint("❌ url_launcher also failed: $e2");
          if (mounted) _showCopyUpiDialog();
        }
      }
    } else {
      // ✅ MOBILE: Direct UPI app launch
      final upiUrl = _buildUpiUrl(scheme);

      debugPrint("🚀 MOBILE LAUNCH: $upiUrl");

      try {
        final uri = Uri.parse(upiUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint("✅ Launched $appName");
        } else {
          throw Exception("Cannot launch UPI app");
        }
      } catch (e) {
        debugPrint("❌ Failed to launch $appName: $e");
        if (mounted) {
          _showSnack(
            "Could not open $appName. Please try another app.",
            isError: true,
          );
        }
      }
    }
  }

  // ─── APP NOT OPENED DIALOG (WEB ONLY) ────────────────────
  void _showAppNotOpenedDialog(String appName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            const Text("Still here?"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "If $appName didn't open:",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ...[
              "• Make sure the app is installed",
              "• Try clicking the button again",
              "• Or use 'Copy UPI ID' option",
            ].map(
              (text) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(text, style: GoogleFonts.poppins(fontSize: 13)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Try Again"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCopyUpiDialog();
            },
            child: const Text("Copy UPI ID"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _flowStep = 'returned');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            child: const Text("I have paid"),
          ),
        ],
      ),
    );
  }

  // ─── SHOW UPI APP CHOOSER ────────────────────────────────
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
              "Pay ₹${1.toStringAsFixed(0)} to ${widget.upiId}",
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

            // "I have paid" button
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

            // Copy UPI ID option
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
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: () {
          Navigator.pop(context);
          _openUpiApp(
            app['name'] as String,
            app['package'] as String,
            app['scheme'] as String,
          );
        },
      ),
    );
  }

  // ─── COPY UPI ID DIALOG ──────────────────────────────────
  void _showCopyUpiDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Manual Payment"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pay manually in any UPI app:",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "UPI ID:",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        SelectableText(
                          widget.upiId,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: widget.upiId));
                      _showSnack("✅ UPI ID copied!");
                    },
                    icon: const Icon(Icons.copy),
                    tooltip: "Copy UPI ID",
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Amount: ₹${1.toStringAsFixed(0)}",
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            child: const Text("I have paid"),
          ),
        ],
      ),
    );
  }

  // ─── PICK IMAGE ──────────────────────────────────────────
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
      _showSnack("Error selecting image: $e", isError: true);
    }
  }

  // ─── UPLOAD PROOF ────────────────────────────────────────
  Future<void> _uploadProof() async {
    if (_txnIdController.text.trim().isEmpty) {
      _showSnack("Please enter UPI Transaction ID", isError: true);
      return;
    }
    if (_selectedImage == null) {
      _showSnack("Please select payment screenshot", isError: true);
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
        _showSnack("Upload failed. Please try again.", isError: true);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      _showSnack("Error: $e", isError: true);
    }
  }

  // ─── SUCCESS DIALOG ──────────────────────────────────────
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_bottom_rounded,
                  size: 56,
                  color: Colors.orange.shade600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Screenshot Uploaded!",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Order #${widget.orderId}\n\nYour payment is under review.\nAdmin will verify and confirm your order soon.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pop(context); // back to previous screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "View My Orders",
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ─── BUILD UI ────────────────────────────────────────────
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
        elevation: 0,
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
                    _buildReturnedBanner(),
                    const SizedBox(height: 16),
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
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _infoRow("Order ID", "#${widget.orderId}"),
          _infoRow("Amount to Pay", "₹${1.toStringAsFixed(0)}"),
          _infoRow("UPI ID", widget.upiId),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    final isDone = _flowStep == 'returned';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDone ? Colors.green.shade300 : Colors.grey.shade200,
          width: isDone ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stepBadge("1", done: isDone),
              const SizedBox(width: 10),
              Text(
                "Pay via UPI",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isDone) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: Colors.green, size: 20),
              ],
              if (_flowStep == 'upi_open') ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange.shade600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

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
                icon: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 22,
                ),
                label: Text(
                  isDone ? "Pay Again" : "Pay ₹${1.toStringAsFixed(0)} via UPI",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDone
                      ? Colors.grey.shade400
                      : const Color(0xFF5B3DF5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

          if (_flowStep == 'upi_open') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _flowStep = 'returned'),
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
                label: Text(
                  "I have paid — Upload Screenshot",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade700,
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
          ],
        ],
      ),
    );
  }

  Widget _buildReturnedBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green.shade700),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Payment completed?",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                Text(
                  "Enter transaction ID and upload screenshot below.",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final canSubmit =
        _txnIdController.text.trim().isNotEmpty && _selectedImage != null;

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
          Row(
            children: [
              _stepBadge("2"),
              const SizedBox(width: 10),
              Text(
                "Upload Payment Proof",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Text(
            "UPI Transaction ID *",
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _txnIdController,
            decoration: InputDecoration(
              hintText: "e.g. 412345678901 (check UPI app history)",
              hintStyle: GoogleFonts.poppins(fontSize: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: const Icon(Icons.receipt_long),
              suffixIcon: _txnIdController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _txnIdController.clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),

          const SizedBox(height: 20),

          Text(
            "Payment Screenshot *",
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedImage != null
                      ? Colors.green
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 60,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Tap to choose screenshot",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          if (_selectedImage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 6),
                Text(
                  "Screenshot selected",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.green),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _pickImage,
                  child: Text(
                    "Change",
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: canSubmit ? _uploadProof : null,
              icon: const Icon(Icons.cloud_upload_rounded),
              label: Text(
                "Submit Screenshot",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          if (!canSubmit) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.orange.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Please enter transaction ID and select screenshot",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
            "1. Click 'Pay via UPI' button",
            "2. Select your UPI app (GPay, PhonePe, etc.)",
            "3. Complete payment in the UPI app",
            "4. Take screenshot of success screen",
            "5. Return to this page",
            "6. Enter Transaction ID and upload screenshot",
            "7. Admin will verify and confirm your order",
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
                        height: 1.5,
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
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBadge(String number, {bool done = false}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: done ? Colors.green : const Color(0xFF5B3DF5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: done
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}
