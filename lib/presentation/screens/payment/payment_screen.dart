import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'order_details_screen.dart';

enum PaymentState {
  orderSummary, // SCREEN 1
  paymentVerification, // SCREEN 2
  orderConfirmation, // SCREEN 3
}

class PaymentScreen extends StatefulWidget {
  final String productName;
  final int quantity;
  final double price;
  final double deliveryCharge;

  const PaymentScreen({
    Key? key,
    this.productName = "Premium Nail Art Kit",
    this.quantity = 1,
    this.price = 100.0,
    this.deliveryCharge = 50.0,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  late double subtotal;
  late double totalAmount;

  final String upiId = "9925503530@kotak";
  final String merchantName = "Shree Nails";

  PaymentState _currentState = PaymentState.orderSummary;

  // Animations
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Verification Input
  final TextEditingController _transactionIdController =
      TextEditingController();
  bool _isTransactionIdValid = false;
  bool _isConfirming = false;

  String _generatedOrderId = "";

  @override
  void initState() {
    super.initState();
    subtotal = widget.price * widget.quantity;
    totalAmount = subtotal + widget.deliveryCharge;

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();

    _transactionIdController.addListener(_validateTransactionId);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _transactionIdController.dispose();
    super.dispose();
  }

  void _validateTransactionId() {
    setState(() {
      _isTransactionIdValid =
          _transactionIdController.text.trim().length >=
          8; // Basic length validation
    });
  }

  void _switchState(PaymentState newState) {
    if (!mounted) return;
    _fadeController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _currentState = newState;
      });
      _fadeController.forward();
    });
  }

  // ============== LOGIC =================

  Future<void> _handlePayNow() async {
    final Uri upiUri = Uri(
      scheme: 'upi',
      host: 'pay',
      queryParameters: {
        'pa': upiId,
        'pn': merchantName,
        'am': totalAmount.toStringAsFixed(2),
        'cu': 'INR',
      },
    );

    try {
      if (await canLaunchUrl(upiUri)) {
        await launchUrl(upiUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Ignore if cannot launch, user can still scan QR.
    }

    _switchState(PaymentState.paymentVerification);
  }

  Future<void> _handleConfirmOrder() async {
    if (!_isTransactionIdValid) return;

    setState(() {
      _isConfirming = true;
    });

    // Simulate API delay for verification submission
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _isConfirming = false;
      _generatedOrderId = "ORD${Random().nextInt(10000000)}";
    });

    _switchState(PaymentState.orderConfirmation);
  }

  // ============== UI BUILDERS =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Soft modern background
      appBar: AppBar(
        title: Text(
          "Payment",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
        leading: _currentState != PaymentState.orderSummary
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_currentState == PaymentState.paymentVerification) {
                    _switchState(PaymentState.orderSummary);
                  } else {
                    Navigator.pop(context);
                  }
                },
              )
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: _buildCurrentState(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentState() {
    switch (_currentState) {
      case PaymentState.orderSummary:
        return _buildOrderSummaryScreen();
      case PaymentState.paymentVerification:
        return _buildPaymentVerificationScreen();
      case PaymentState.orderConfirmation:
        return _buildOrderConfirmationScreen();
    }
  }

  // --- SCREEN 1: Order Summary ---
  Widget _buildOrderSummaryScreen() {
    String upiData =
        'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(merchantName)}&am=${totalAmount.toStringAsFixed(2)}&cu=INR';

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        // Order Summary Details
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Order Summary",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.deepPurple.shade100),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.deepPurple,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.productName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Quantity: ${widget.quantity}",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "₹${widget.price.toStringAsFixed(2)}",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Divider(height: 1),
              ),
              _buildSummaryRow("Subtotal", "₹${subtotal.toStringAsFixed(2)}"),
              const SizedBox(height: 12),
              _buildSummaryRow(
                "Delivery Charge",
                "₹${widget.deliveryCharge.toStringAsFixed(2)}",
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.deepPurple.shade100),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Amount",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade900,
                      ),
                    ),
                    Text(
                      "₹${totalAmount.toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Pay using UPI Section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Pay using UPI",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.deepPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "UPI ID: $upiId",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: upiData,
                  version: QrVersions.auto,
                  size: 200.0,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black87,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildGradientButton(text: "Pay Now", onPressed: _handlePayNow),
              const SizedBox(height: 16),
              Text(
                "Scan the QR code or click 'Pay Now' to complete the payment in your UPI app.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SCREEN 2: Payment Verification ---
  Widget _buildPaymentVerificationScreen() {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.verified_user_outlined,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Verify Your Payment",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "After completing the payment, please enter your UPI Transaction ID to confirm your order.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Transaction ID",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _transactionIdController,
                style: GoogleFonts.poppins(fontSize: 15),
                decoration: InputDecoration(
                  hintText: "Enter 12-digit UPI Txn ID",
                  hintStyle: GoogleFonts.poppins(
                    color: Colors.grey.shade400,
                    fontSize: 14,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Colors.deepPurple,
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(
                    Icons.receipt_long,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: _isTransactionIdValid
                      ? LinearGradient(
                          colors: [
                            Colors.deepPurple.shade700,
                            Colors.deepPurple.shade500,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _isTransactionIdValid ? null : Colors.grey.shade300,
                  boxShadow: _isTransactionIdValid
                      ? [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: (_isTransactionIdValid && !_isConfirming)
                        ? _handleConfirmOrder
                        : null,
                    child: Center(
                      child: _isConfirming
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "Confirm Order",
                              style: GoogleFonts.poppins(
                                color: _isTransactionIdValid
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => _switchState(PaymentState.orderSummary),
                  child: Text(
                    "Back to Order Summary",
                    style: GoogleFonts.poppins(
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- SCREEN 3: Order Confirmation ---
  Widget _buildOrderConfirmationScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.15),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    color: Colors.orange.shade600,
                    size: 72,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Order Confirmed",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Our team will verify your transaction and confirm the order shortly.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                _buildReceiptRow("Order ID", _generatedOrderId),
                _buildReceiptRow("Product", widget.productName),
                _buildReceiptRow("Payment Method", "UPI"),
                _buildReceiptRow(
                  "Txn ID",
                  _transactionIdController.text.trim(),
                ),
                _buildReceiptRow(
                  "Status",
                  "Verification Pending",
                  isHighlight: true,
                  highlightColor: Colors.orange.shade700,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Divider(height: 1),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Amount",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      "₹${totalAmount.toStringAsFixed(2)}",
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          _buildGradientButton(
            text: "View Order Details",
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => OrderDetailsScreen(
                    orderId: _generatedOrderId,
                    transactionId: _transactionIdController.text.trim(),
                    productName: widget.productName,
                    quantity: widget.quantity,
                    price: widget.price,
                    deliveryCharge: widget.deliveryCharge,
                    totalAmount: totalAmount,
                    paymentStatus: "Verification Pending",
                  ),
                ),
              );
            },
            colors: [Colors.orange.shade600, Colors.orange.shade400],
          ),
        ],
      ),
    );
  }

  // ============== HELPER WIDGETS =================

  Widget _buildSummaryRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(fontSize: 15, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(
    String title,
    String value, {
    bool isHighlight = false,
    Color? highlightColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isHighlight
                    ? (highlightColor ?? Colors.green.shade700)
                    : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientButton({
    required String text,
    required VoidCallback onPressed,
    List<Color>? colors,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors:
              colors ??
              [Colors.deepPurple.shade700, Colors.deepPurple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (colors?.first ?? Colors.deepPurple).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
