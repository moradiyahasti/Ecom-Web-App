// lib/presentation/screens/Settings/payment_proff.dart

import 'dart:io';
import 'package:demo/data/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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

  // ─── FLOW STATE ───────────────────────────────────────────
  // Step 1: idle      → user hasn't clicked Pay yet
  // Step 2: upi_open  → UPI app was launched, waiting for return
  // Step 3: returned  → user came back from UPI app (show upload)
  String _flowStep = 'idle'; // 'idle' | 'upi_open' | 'returned'

  // ─── App lifecycle: detect when user returns from UPI app ──
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _txnIdController.dispose();
    super.dispose();
  }

  /// Called when app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // User returned from UPI app
    if (state == AppLifecycleState.resumed && _flowStep == 'upi_open') {
      debugPrint("📲 Returned from UPI app");
      setState(() => _flowStep = 'returned');
    }
  }

  // ─── 🔥 NEW: SHOW UPI APP CHOOSER DIALOG ─────────────────
  Future<void> _openUpiApp() async {
    // Build UPI payment URL parameters
    final upiParams = 'pa=${Uri.encodeComponent(widget.upiId)}'
        '&pn=${Uri.encodeComponent("Shree Nails")}'
        '&am=${widget.totalAmount.toInt()}'
        '&cu=INR'
        '&tn=${Uri.encodeComponent("Order #${widget.orderId}")}';

    // Set flow state to upi_open BEFORE showing dialog
    setState(() => _flowStep = 'upi_open');

    // Show UPI app chooser dialog
    await _showUpiAppChooser(upiParams);
  }

  // ── 🔥 UPI APP CHOOSER DIALOG ──────────────────────────
  Future<void> _showUpiAppChooser(String upiParams) async {
    final apps = [
      {
        'name': 'Google Pay',
        'icon': Icons.g_mobiledata,
        'color': Colors.blue.shade600,
        'package': 'com.google.android.apps.nbu.paisa.user',
        'schemes': ['gpay', 'tez', 'paytm'], // Multiple schemes to try
      },
      {
        'name': 'PhonePe',
        'icon': Icons.phone_android,
        'color': const Color(0xFF5F259F),
        'package': 'com.phonepe.app',
        'schemes': ['phonepe'],
      },
      {
        'name': 'Paytm',
        'icon': Icons.payment,
        'color': Colors.blue.shade800,
        'package': 'net.one97.paytm',
        'schemes': ['paytmmp'],
      },
      {
        'name': 'BHIM',
        'icon': Icons.account_balance,
        'color': Colors.orange.shade700,
        'package': 'in.org.npci.upiapp',
        'schemes': ['bhim', 'upi'],
      },
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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

            // Title
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

            // UPI App List
            ...apps.map((app) => _buildUpiAppTile(app, upiParams)),

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
          ],
        ),
      ),
    );
  }

  // ── Build UPI App Tile ──
  Widget _buildUpiAppTile(Map<String, dynamic> app, String upiParams) {
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
        onTap: () async {
          Navigator.pop(context); // Close dialog
          await _launchUpiApp(app, upiParams);
        },
      ),
    );
  }

  // ── Launch specific UPI app ──
  Future<void> _launchUpiApp(
    Map<String, dynamic> app,
    String upiParams,
  ) async {
    final schemes = app['schemes'] as List<String>;
    final appName = app['name'] as String;

    // Try each URL scheme
    for (final scheme in schemes) {
      final upiUrl = '$scheme://upi/pay?$upiParams';
      debugPrint("🚀 Trying: $upiUrl");

      try {
        final uri = Uri.parse(upiUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          debugPrint("✅ Launched: $appName via $scheme");
          return;
        }
      } catch (e) {
        debugPrint("❌ Failed to launch $scheme: $e");
      }
    }

    // If all schemes failed, try Android intent
    final packageName = app['package'] as String;
    final intentUrl =
        'intent://upi/pay?$upiParams#Intent;scheme=upi;package=$packageName;end';

    try {
      final uri = Uri.parse(intentUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint("✅ Launched via intent: $appName");
        return;
      }
    } catch (e) {
      debugPrint("❌ Intent failed: $e");
    }

    // If everything failed
    if (mounted) {
      _showSnack(
        "$appName is not installed or couldn't be opened",
        isError: true,
      );
    }
  }

  // ─── PICK IMAGE ───────────────────────────────────────────
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

  // ─── UPLOAD PROOF ─────────────────────────────────────────
  Future<void> _uploadProof() async {
    // ✅ Validate transaction ID is required
    if (_txnIdController.text.trim().isEmpty) {
      _showSnack("Please enter UPI Transaction ID", isError: true);
      return;
    }

    if (_selectedImage == null) {
      _showSnack("Please select the payment screenshot", isError: true);
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

  // ─── SUCCESS DIALOG ───────────────────────────────────────
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

  // ─── BUILD ────────────────────────────────────────────────
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
          ? _buildUploading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderCard(),
                  const SizedBox(height: 24),

                  // ── Step 1: Always visible ──
                  _buildStep1(),

                  // ── Step 2: Only after returning from UPI app ──
                  if (_flowStep == 'returned') ...[
                    const SizedBox(height: 28),
                    _buildReturnedBanner(),
                    const SizedBox(height: 16),
                    _buildStep2(),
                  ],

                  const SizedBox(height: 24),
                  _buildInstructions(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── Order Info Card ──
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
          _infoRow("Amount to Pay", "₹${widget.totalAmount.toStringAsFixed(0)}"),
          _infoRow("UPI ID", widget.upiId),
        ],
      ),
    );
  }

  // ── Step 1: Pay via UPI ──
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
            // Waiting banner
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
                      "Complete payment in your UPI app and return here.",
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
                onPressed: _openUpiApp,
                icon: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 22,
                ),
                label: Text(
                  isDone
                      ? "Pay Again"
                      : "Pay ₹${widget.totalAmount.toStringAsFixed(0)} via UPI",
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

          // ✅ "I have paid" button — only in upi_open state
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

  // ── Green banner shown after returning from UPI ──
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
                  "Enter transaction ID from your UPI app and upload screenshot below.",
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

  // ── Step 2: Transaction ID + Screenshot upload ──
  Widget _buildStep2() {
    // ✅ Check if both fields are filled
    final canSubmit = _txnIdController.text.trim().isNotEmpty &&
        _selectedImage != null;

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

          // ── 🔥 Transaction ID (MANDATORY) ──
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

          // ── Screenshot picker ──
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
                        const SizedBox(height: 4),
                        Text(
                          "from your gallery",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade400,
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

          // ── 🔥 Submit button — enabled only when BOTH fields filled ──
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

          // ✅ Helper text if disabled
          if (!canSubmit) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.orange.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Please enter transaction ID and select screenshot to continue",
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

  // ── Instructions ──
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
            "5. Return to this app",
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

  // ── Uploading indicator ──
  Widget _buildUploading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            "Uploading screenshot...",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text("Please wait", style: GoogleFonts.poppins(color: Colors.grey)),
        ],
      ),
    );
  }

  // ── Helpers ──
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