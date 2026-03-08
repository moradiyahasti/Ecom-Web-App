import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

import 'order_details_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String productName;
  final int quantity;
  final double price;
  final double deliveryCharge;

  const PaymentScreen({
    Key? key,
    this.productName = "Premium Nail Art Kit",
    this.quantity = 1,
    this.price = 999.0,
    this.deliveryCharge = 50.0,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> with SingleTickerProviderStateMixin {
  late double subtotal;
  late double totalAmount;

  final String upiId = "merchant@upi";
  final String merchantName = "Shree Nails";

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    subtotal = widget.price * widget.quantity;
    totalAmount = subtotal + widget.deliveryCharge;

    _animController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _initiateUPIPayment(String app) async {
    // Generate UPI URI
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
        // Simulate waiting for payment gateway return
        await Future.delayed(const Duration(seconds: 3));
        _handlePaymentResult(isSuccess: true); 
      } else {
        // For Web or Devices without UPI, simulate success/failure randomly after delay
        _showSimulatingPaymentDialog(app);
      }
    } catch (e) {
      _showSimulatingPaymentDialog(app);
    }
  }

  void _showSimulatingPaymentDialog(String app) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.deepPurple),
            SizedBox(height: 16),
            Text("Awaiting Payment Confirmation..."),
          ],
        ),
      ),
    );

    // Simulate network call
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      final bool isSuccess = Random().nextBool(); // Randomly succeed or fail for demo
      _handlePaymentResult(isSuccess: isSuccess);
    });
  }

  void _handlePaymentResult({required bool isSuccess}) {
    if (isSuccess) {
      _showSuccessDialog();
    } else {
      _showFailureDialog();
    }
  }

  void _showSuccessDialog() {
    final transactionId = "TXN${Random().nextInt(100000000)}";
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
                const SizedBox(height: 16),
                Text(
                  "Payment Successful",
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Transaction ID: $transactionId",
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                ),
                Text(
                  "Amount Paid: ₹${totalAmount.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailsScreen(
                            orderId: "ORD${Random().nextInt(10000000)}",
                            transactionId: transactionId,
                            productName: widget.productName,
                            quantity: widget.quantity,
                            price: widget.price,
                            deliveryCharge: widget.deliveryCharge,
                            totalAmount: totalAmount,
                            paymentStatus: "Success",
                          ),
                        ),
                      );
                    },
                    child: Text(
                      "View Order Details",
                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  "Payment Failed",
                  style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Payment was not completed.",
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // close dialog
                    },
                    child: Text(
                      "Try Again",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Payment",
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildOrderSummaryCard(),
                const SizedBox(height: 24),
                _buildUPISection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order Summary",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(widget.productName, "x${widget.quantity}"),
          const SizedBox(height: 12),
          _buildSummaryRow("Price", "₹${subtotal.toStringAsFixed(2)}"),
          const SizedBox(height: 12),
          _buildSummaryRow("Delivery Charge", "₹${widget.deliveryCharge.toStringAsFixed(2)}", isSubtext: true),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Amount",
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "₹${totalAmount.toStringAsFixed(2)}",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isSubtext = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
           child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isSubtext ? Colors.grey.shade600 : Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSubtext ? FontWeight.normal : FontWeight.w500,
            color: isSubtext ? Colors.grey.shade600 : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildUPISection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            "Pay using UPI",
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 400 ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildUPIAppCard("GPay", "assets/gpay_icon.png", Colors.white),
            _buildUPIAppCard("PhonePe", "assets/phonepe_icon.png", Colors.white),
            _buildUPIAppCard("Paytm", "assets/paytm_icon.png", Colors.white),
            _buildUPIAppCard("BHIM", "assets/bhim_icon.png", Colors.white),
          ],
        ),
      ],
    );
  }

  Widget _buildUPIAppCard(String name, String iconPath, Color bgColor) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _initiateUPIPayment(name),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Use a generic icon if asset doesn't exist to prevent crashes
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.deepPurple), // Placeholder for actual icon image
              ),
              const SizedBox(height: 10),
              Text(
                name,
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
