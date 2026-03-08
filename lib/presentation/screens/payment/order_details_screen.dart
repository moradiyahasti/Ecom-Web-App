import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderDetailsScreen extends StatelessWidget {
  final String orderId;
  final String transactionId;
  final String productName;
  final int quantity;
  final double price;
  final double deliveryCharge;
  final double totalAmount;
  final String paymentStatus;

  const OrderDetailsScreen({
    Key? key,
    required this.orderId,
    required this.transactionId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.deliveryCharge,
    required this.totalAmount,
    required this.paymentStatus,
  }) : super(key: key);

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'failed':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(paymentStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "Order Details",
          style: GoogleFonts.poppins(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildStatusHeader(statusColor),
              const SizedBox(height: 24),
              _buildOrderCard(),
              if (paymentStatus.toLowerCase() == 'failed' || paymentStatus.toLowerCase() == 'pending') ...[
                const SizedBox(height: 24),
                _buildRetryPaymentButton(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Color statusColor) {
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              paymentStatus.toLowerCase() == 'success'
                  ? Icons.check_circle
                  : paymentStatus.toLowerCase() == 'failed'
                      ? Icons.cancel
                      : Icons.hourglass_top,
              color: statusColor,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order $paymentStatus",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Order ID: $orderId",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
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

  Widget _buildOrderCard() {
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
          _buildDetailRow("Product", "$productName (x$quantity)"),
          const SizedBox(height: 12),
          _buildDetailRow("Price", "₹${(price * quantity).toStringAsFixed(2)}"),
          const SizedBox(height: 12),
          _buildDetailRow("Delivery Charge", "₹${deliveryCharge.toStringAsFixed(2)}"),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
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
          const SizedBox(height: 24),
          Text(
            "Payment Information",
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          _buildDetailRow("Payment Method", "UPI", isSubtext: true),
          const SizedBox(height: 8),
          _buildDetailRow("Transaction ID", transactionId.isNotEmpty ? transactionId : "N/A", isSubtext: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {bool isSubtext = false}) {
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

  Widget _buildRetryPaymentButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 2,
        ),
        onPressed: () {
          // Send user back to Retry Payment
          Navigator.pop(context);
        },
        child: Text(
          "Pay Now",
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
