/* // lib/presentation/screens/Settings/payment_proff.dart
// ✅ PRODUCTION READY: Enhanced Web → UPI App Redirect

import 'dart:io';
import 'package:demo/data/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// Conditional import for web/mobile support
import 'package:universal_html/html.dart' as html;

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
  String _flowStep = 'idle';

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

  String _buildUpiUrl(String scheme) {
    final params =
        'pa=${Uri.encodeComponent(widget.upiId)}'
        '&pn=${Uri.encodeComponent("Shree Nails")}'
        '&am=${1.toInt()}'
        '&cu=INR'
        '&tn=${Uri.encodeComponent("Order #${widget.orderId}")}';
    return '$scheme://upi/pay?$params';
  }

  String _buildIntentUrl(String packageName, String scheme) {
    final params =
        'pa=${Uri.encodeComponent(widget.upiId)}'
        '&pn=${Uri.encodeComponent("Shree Nails")}'
        '&am=${1.toInt()}'
        '&cu=INR'
        '&tn=${Uri.encodeComponent("Order #${widget.orderId}")}';
    return 'intent://upi/pay?$params#Intent;scheme=$scheme;package=$packageName;end';
  }

  // ✅ ENHANCED: Try multiple methods to open UPI app
  Future<void> _openUpiApp(
    String appName,
    String packageName,
    String scheme,
  ) async {
    setState(() => _flowStep = 'upi_open');

    if (kIsWeb) {
      // ✅ WEB: Aggressive multi-method approach
      bool launched = false;

      debugPrint("🚀 Attempting to open $appName from web");

      // Method 1: Direct UPI scheme (works in some mobile browsers)
      if (!launched) {
        try {
          final directUrl = _buildUpiUrl(scheme);
          final uri = Uri.parse(directUrl);

          debugPrint("📱 Method 1: Trying direct URL: $directUrl");

          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            launched = true;
            debugPrint("✅ Method 1 SUCCESS");
          }
        } catch (e) {
          debugPrint("❌ Method 1 failed: $e");
        }
      }

      // Method 2: Intent URL via url_launcher
      if (!launched) {
        try {
          final intentUrl = _buildIntentUrl(packageName, scheme);
          final uri = Uri.parse(intentUrl);

          debugPrint("📱 Method 2: Trying intent URL");

          if (await canLaunchUrl(uri)) {
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
              webOnlyWindowName: '_self',
            );
            launched = true;
            debugPrint("✅ Method 2 SUCCESS");
          }
        } catch (e) {
          debugPrint("❌ Method 2 failed: $e");
        }
      }

      // Method 3: window.location.href (most reliable for Android Chrome)
      if (!launched) {
        try {
          final intentUrl = _buildIntentUrl(packageName, scheme);
          debugPrint("📱 Method 3: Using window.location.href");

          html.window.location.href = intentUrl;
          launched = true;
          debugPrint("✅ Method 3 executed");
        } catch (e) {
          debugPrint("❌ Method 3 failed: $e");
        }
      }

      // Show fallback dialog after short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _showFallbackDialog(appName);
        }
      });
    } else {
      // ✅ MOBILE APP: Standard launch
      final upiUrl = _buildUpiUrl(scheme);

      try {
        final uri = Uri.parse(upiUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception("Cannot launch");
        }
      } catch (e) {
        debugPrint("❌ Mobile launch failed: $e");
        if (mounted) {
          _showSnack("Could not open $appName", isError: true);
        }
      }
    }
  }

  // ✅ Simpler fallback dialog
  void _showFallbackDialog(String appName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade600, size: 24),
            const SizedBox(width: 12),
            const Expanded(child: Text("App not opening?")),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "If $appName didn't open automatically:",
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            _fallbackOption(
              Icons.refresh,
              "Try Again",
              "Click another UPI app button",
            ),
            _fallbackOption(
              Icons.copy,
              "Manual Payment",
              "Copy UPI ID and pay manually",
            ),
            _fallbackOption(
              Icons.check_circle_outline,
              "Already Paid?",
              "Upload your payment screenshot",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Try Another App"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showCopyUpiDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
            ),
            child: const Text("Manual Payment"),
          ),
        ],
      ),
    );
  }

  Widget _fallbackOption(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
            ...apps.map((app) => _buildAppTile(app)),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _flowStep = 'returned');
                },
                icon: Icon(
                  Icons.check_circle_outline,
                  color: Colors.deepPurple.shade600,
                ),
                label: Text(
                  "I have completed payment",
                  style: GoogleFonts.poppins(
                    color: Colors.deepPurple.shade700,
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
                color: Colors.deepPurple.shade700,
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
              backgroundColor: Colors.deepPurple.shade600,
            ),
            child: const Text("I have paid"),
          ),
        ],
      ),
    );
  }

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

  Future<void> _uploadProof() async {
    if (_txnIdController.text.trim().isEmpty) {
      _showSnack("Enter Transaction ID", isError: true);
      return;
    }
    if (_selectedImage == null) {
      _showSnack("Select screenshot", isError: true);
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
                "Order #${widget.orderId}\n\nAdmin will verify your payment soon.",
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
                    Navigator.pop(context);
                    Navigator.pop(context);
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
          _infoRow("Amount", "₹${1.toStringAsFixed(0)}"),
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
                      "Waiting... Complete payment in UPI app.",
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
                  "I have paid",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple.shade700,
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
          Icon(Icons.check_circle_outline, color: Colors.deepPurple.shade700),
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
                  "Enter transaction ID and upload screenshot.",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.deepPurple.shade700,
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
              hintText: "e.g. 412345678901",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: const Icon(Icons.receipt_long),
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),
          Text(
            "Screenshot *",
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
                          "Tap to upload",
                          style: GoogleFonts.poppins(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: canSubmit ? _uploadProof : null,
              icon: const Icon(Icons.cloud_upload_rounded),
              label: Text(
                "Submit",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade600,
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
            "1. Click 'Pay via UPI'",
            "2. Select your UPI app",
            "3. Complete payment",
            "4. Return here",
            "5. Upload screenshot + transaction ID",
          ].map(
            (text) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
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
 */

// lib/presentation/screens/Settings/payment_proff.dart
//
// FLOW:
// 1. User ne QR + UPI app buttons dekhai
// 2. User UPI app select kare → app khule
// 3. User payment kare → Transaction ID male
// 4. User website par pache aave
// 5. "I Have Paid" button dabave → Transaction ID input dekhai
// 6. Transaction ID enter kare → DB ma save → Success dialog
// 7. Transaction ID na kare (empty) → Failed dialog

import 'dart:convert';
import 'dart:developer';
import 'package:demo/data/providers/cart_provider.dart';
import 'package:demo/data/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:universal_html/html.dart' as html;

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
  final TextEditingController _txnIdController = TextEditingController();

  // Steps:
  // 'idle'       → QR + UPI app buttons show thay
  // 'upi_opened' → UPI app open thai gayu, user return ni raah
  // 'returned'   → User pachi avyo, Transaction ID input show thay
  String _step = 'idle';
  bool _isSubmitting = false;

  // ─── UPI QR String ───────────────────────────
  String get _upiQrString =>
      'upi://pay?pa=${Uri.encodeComponent(widget.upiId)}'
      '&pn=${Uri.encodeComponent("Shree Nails")}'
      '&am=${1}'
      '&cu=INR'
      '&tn=${Uri.encodeComponent("Order #${widget.orderId}")}';

  @override
  void dispose() {
    _txnIdController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // UPI App Open karo
  // ─────────────────────────────────────────────
  Future<void> _openUpiApp(
    String appName,
    String packageName,
    String scheme,
  ) async {
    Navigator.pop(context); // bottom sheet band karo
    setState(() => _step = 'upi_opened');

    // UPI deep link
    final upiUrl =
        '$scheme://upi/pay?pa=${Uri.encodeComponent(widget.upiId)}'
        '&pn=${Uri.encodeComponent("Shree Nails")}'
        '&am=${1}'
        '&cu=INR'
        '&tn=${Uri.encodeComponent("Order #${widget.orderId}")}';

    // Android Chrome mate intent URL
    final intentUrl =
        'intent://upi/pay?pa=${Uri.encodeComponent(widget.upiId)}'
        '&pn=${Uri.encodeComponent("Shree Nails")}'
        '&am=${1}'
        '&cu=INR'
        '&tn=${Uri.encodeComponent("Order #${widget.orderId}")}'
        '#Intent;scheme=$scheme;package=$packageName;end';

    log("🚀 Opening $appName");

    bool launched = false;

    // Method 1: canLaunchUrl
    try {
      final uri = Uri.parse(upiUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        launched = true;
        log("✅ Launched via canLaunchUrl");
      }
    } catch (e) {
      log("❌ Method 1 failed: $e");
    }

    // Method 2: Web par window.location (Android Chrome)
    if (!launched && kIsWeb) {
      try {
        html.window.location.href = intentUrl;
        launched = true;
        log("✅ Launched via window.location");
      } catch (e) {
        log("❌ Method 2 failed: $e");
      }
    }

    if (!launched) {
      _showSnack("$appName open na thayun. QR code scan karo.", isError: true);
      setState(() => _step = 'idle');
    }
  }

  // ─────────────────────────────────────────────
  // UPI App selection bottom sheet
  // ─────────────────────────────────────────────
  void _showUpiApps() {
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

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
              "UPI App Select Karo",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "₹${1} → ${widget.upiId}",
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),

            // App tiles
            ...apps.map(
              (app) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
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
                  subtitle: Text(
                    "${app['name']} app ma payment karo",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                  onTap: () => _openUpiApp(
                    app['name'] as String,
                    app['package'] as String,
                    app['scheme'] as String,
                  ),
                ),
              ),
            ),

            const Divider(height: 24),

            // Already paid
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _step = 'returned');
                },
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                ),
                label: Text(
                  "Mein payment kari lidhu che",
                  style: GoogleFonts.poppins(
                    color: Colors.deepPurple.shade700,
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
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Submit karo:
  //   Transaction ID chhe → SUCCESS → DB ma save
  //   Transaction ID nathi → FAILED dialog
  // ─────────────────────────────────────────────
  Future<void> _submitTransactionId() async {
    final txnId = _txnIdController.text.trim();

    if (txnId.isNotEmpty) {
      if (txnId.length < 8) {
        _showSnack('Transaction ID bahuj nanu chhe. Tpaso.', isError: true);
        return;
      }
      await _processSuccess(txnId);
    } else {
      // Empty = payment nathi thayun
      _showFailureDialog();
    }
  }

  // ─────────────────────────────────────────────
  // SUCCESS: DB ma transaction save karo
  // ─────────────────────────────────────────────
  Future<void> _processSuccess(String txnId) async {
    setState(() => _isSubmitting = true);

    try {
      log("══════════════════════════════════════════");
      log("📤 PAYMENT SUCCESS PROCESSING");
      log("   Order ID : ${widget.orderId}");
      log("   Txn ID   : $txnId");
      log("   Amount   : ₹${widget.totalAmount}");
      log("══════════════════════════════════════════");

      // STEP 1: Transaction create karo (user no actual UPI Txn ID)
      // transactions table ma save thase
      final createRes = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/transactions/create"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "order_id": widget.orderId,
          "transaction_ref": txnId, // ← user no real UPI Transaction ID
          "amount": /* widget.totalAmount */ 10,
          "status": "success",
          "payment_method": "UPI",
        }),
      );
      log("📥 Create: ${createRes.statusCode} | ${createRes.body}");

      // STEP 2: Transaction update karo → backend payments table update karshe
      final updateRes = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/transactions/update"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "transaction_ref": txnId,
          "status": "success",
          "upi_response": "UPI Txn ID entered by user: $txnId",
        }),
      );
      log("📥 Update: ${updateRes.statusCode} | ${updateRes.body}");

      // STEP 3: Payment confirm → orders.status = PAID
      //         payments table ma transaction_id save thase
      final confirmRes = await http.post(
        Uri.parse("${ApiService.baseUrl}/api/transactions/success"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "order_id": widget.orderId,
          "transaction_ref": txnId,
          "payment_method": "UPI",
        }),
      );
      log("📥 Confirm: ${confirmRes.statusCode} | ${confirmRes.body}");

      // STEP 4: Cart clear karo
      if (mounted) {
        await context.read<CartProvider>().clearCart(widget.userId);
        log("🛒 Cart cleared");
      }

      setState(() => _isSubmitting = false);

      // STEP 5: Success dialog show karo
      if (mounted) _showSuccessDialog(txnId);

      log("══════════════════════════════════════════");
      log("✅ PAYMENT COMPLETE");
      log("══════════════════════════════════════════");
    } catch (e) {
      log("❌ ERROR: $e");
      setState(() => _isSubmitting = false);
      _showSnack('Koi error avyo. Fari try karo.', isError: true);
    }
  }

  // ─────────────────────────────────────────────
  // SUCCESS Dialog
  // ─────────────────────────────────────────────
  void _showSuccessDialog(String txnId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Green circle with checkmark
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 64,
                  color: Colors.green.shade600,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "Payment Successful! 🎉",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              Text(
                "Order #${widget.orderId}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),

              // Transaction ID box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      "Transaction ID",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      txnId,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              Text(
                "₹${1}",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // dialog band
                    Navigator.pop(context); // payment screen band
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    "Continue Shopping",
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

  // ─────────────────────────────────────────────
  // FAILED Dialog
  // ─────────────────────────────────────────────
  void _showFailureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Red circle with X
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cancel_rounded,
                  size: 64,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                "Payment Failed ❌",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                "Transaction ID enter nathi karyu.\nPayment complete nathi thayun.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  // Go Back
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context); // dialog band
                        Navigator.pop(context); // payment screen band
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: Colors.grey.shade400),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Pacha Jao",
                        style: GoogleFonts.poppins(color: Colors.grey.shade700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Try Again
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _step = 'idle';
                          _txnIdController.clear();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Fari Try Karo",
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
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
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Payment Karo",
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _isSubmitting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.deepPurple),
                  const SizedBox(height: 20),
                  Text(
                    "Payment verify thai rahu chhe...",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order summary card
                  _buildOrderCard(),
                  const SizedBox(height: 20),

                  // STEP idle/upi_opened → QR + Pay button
                  if (_step == 'idle' || _step == 'upi_opened') ...[
                    _buildQrCard(),
                    const SizedBox(height: 16),
                    _buildPayButtons(),
                  ],

                  // STEP returned → Transaction ID input
                  if (_step == 'returned') ...[_buildReturnedCard()],

                  const SizedBox(height: 20),
                  _buildHowItWorks(),
                ],
              ),
            ),
    );
  }

  // ─── Order Card ──────────────────────────────
  Widget _buildOrderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade500, Colors.deepPurple.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Order #${widget.orderId}",
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                "₹${1}",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // ─── QR Code Card ─────────────────────────────
  Widget _buildQrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        children: [
          Text(
            "QR Code Scan Karo",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.deepPurple.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: _upiQrString,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // UPI ID row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance,
                  size: 18,
                  color: Colors.deepPurple.shade600,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.upiId,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: widget.upiId));
                    _showSnack("UPI ID copy thai gayu!");
                  },
                  child: Icon(
                    Icons.copy,
                    size: 20,
                    color: Colors.deepPurple.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Pay Buttons ─────────────────────────────
  Widget _buildPayButtons() {
    return Column(
      children: [
        // Main Pay button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: _showUpiApps,
            icon: const Icon(Icons.account_balance_wallet_rounded, size: 22),
            label: Text(
              "UPI App Se Pay Karo  ₹${1}",
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
              elevation: 4,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // upi_opened state: waiting banner + I have paid button
        if (_step == 'upi_opened') ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.orange.shade600,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "UPI app ma payment puri karo...",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => setState(() => _step = 'returned'),
              icon: const Icon(Icons.check_circle_outline, color: Colors.green),
              label: Text(
                "Mein payment kari lidhu — Transaction ID enter karo",
                style: GoogleFonts.poppins(
                  color: Colors.deepPurple.shade700,
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
        ] else ...[
          // idle state: already paid link
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _step = 'returned'),
              icon: Icon(
                Icons.check_circle_outline,
                color: Colors.grey.shade600,
                size: 18,
              ),
              label: Text(
                "Pahela thi payment kari lidhu? Transaction ID enter karo",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Returned: Transaction ID Input ──────────
  Widget _buildReturnedCard() {
    final txnEntered = _txnIdController.text.trim().isNotEmpty;

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
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Payment karyu hoy to → Transaction ID enter karo → Confirm karo\n"
                    "Payment na karyu hoy to → Khali raheva do → Button dabavo",
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
          const SizedBox(height: 20),

          Text(
            "UPI Transaction ID",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Tara UPI app ma Payment History joao ne Transaction ID copy karo",
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 12),

          // Input field
          TextField(
            controller: _txnIdController,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
            decoration: InputDecoration(
              hintText: "e.g. 412345678901",
              hintStyle: GoogleFonts.poppins(
                color: Colors.grey.shade400,
                fontWeight: FontWeight.normal,
              ),
              prefixIcon: Icon(
                Icons.receipt_long,
                color: Colors.deepPurple.shade600,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.deepPurple.shade600,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // Submit button — green if txn entered, red if empty
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _submitTransactionId,
              icon: Icon(
                txnEntered ? Icons.verified_rounded : Icons.close,
                size: 22,
              ),
              label: Text(
                txnEntered
                    ? "Payment Confirm Karo ✅"
                    : "Payment Nathi Thayun ❌",
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: txnEntered
                    ? Colors.green.shade600
                    : Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Back to try again
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _step = 'idle';
                _txnIdController.clear();
              }),
              icon: Icon(
                Icons.arrow_back,
                size: 16,
                color: Colors.grey.shade600,
              ),
              label: Text(
                "Fari thi payment karvo chho?",
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── How It Works ────────────────────────────
  Widget _buildHowItWorks() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.amber.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                "Kem karvanu?",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...[
            "1️⃣  'UPI App Se Pay Karo' button dabavo",
            "2️⃣  Taro UPI app select karo (GPay, PhonePe, etc.)",
            "3️⃣  UPI app ma payment puri karo",
            "4️⃣  UPI app ma transaction ID note karo",
            "5️⃣  Website par pachi aavo → 'Mein payment kari lidhu' dabavo",
            "6️⃣  Transaction ID enter karo → 'Payment Confirm Karo' dabavo",
            "✅  Done! Order confirmed thase.",
            "",
            "❌  Payment na thayun hoy to Transaction ID khali raheva do",
            "   → 'Payment Nathi Thayun' button dabavo",
          ].map(
            (text) => text.isEmpty
                ? const SizedBox(height: 4)
                : Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      text,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.amber.shade900,
                        height: 1.4,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
