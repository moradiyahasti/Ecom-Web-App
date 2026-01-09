//  import 'dart:developer';
// import 'dart:io';
// // import 'dart:math';
// import 'package:demo/services/api_service.dart';
// import 'package:demo/services/cart_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:upi_pay/upi_pay.dart';
// import 'package:confetti/confetti.dart';
// import 'package:flutter/foundation.dart';

// class PaymentScreen extends StatefulWidget {
//   final double totalAmount;
//   final Map<String, dynamic>? orderDetails;

//   const PaymentScreen({super.key, this.totalAmount = 0, this.orderDetails});

//   @override
//   _PaymentScreenState createState() => _PaymentScreenState();
// }

// class _PaymentScreenState extends State<PaymentScreen>
//     with TickerProviderStateMixin {
//   String? _upiAddrError;
//   final _upiAddressController = TextEditingController();
//   final _amountController = TextEditingController();
//   final _upiPayPlugin = UpiPay();
//   List<ApplicationMeta>? _apps;

//   // ✅ Add this - Store transaction ref
//   String? _currentTransactionRef;

//   late AnimationController _slideController;
//   late AnimationController _fadeController;
//   late AnimationController _pulseController;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _fadeAnimation;
//   late Animation<double> _pulseAnimation;

//   bool _isProcessing = false;
//   final ConfettiController _confettiController = ConfettiController(
//     duration: const Duration(seconds: 3),
//   );

//   @override
//   void initState() {
//     super.initState();
//     // _amountController.text = widget.totalAmount > 0
//     //     ? widget.totalAmount.toStringAsFixed(2)
//     //     : (Random.secure().nextDouble() * 10).toStringAsFixed(2);
//     _amountController.text = widget.totalAmount > 0
//         ? widget.totalAmount.toStringAsFixed(2)
//         : "1.00";

//     _upiAddressController.text = "sawan00meena@ucobank";

//     // Animations setup...
//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );
//     _pulseController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     )..repeat(reverse: true);

//     _slideAnimation =
//         Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
//           CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
//         );

//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

//     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );

//     _slideController.forward();
//     _fadeController.forward();

//     // Future.delayed(Duration.zero, () async {
//     //   _apps = await _upiPayPlugin.getInstalledUpiApplications(
//     //     statusType: UpiApplicationDiscoveryAppStatusType.all,
//     //   );
//     //   setState(() {});
//     // });
//     Future.delayed(Duration.zero, () async {
//       if (!kIsWeb) {
//         _apps = await _upiPayPlugin.getInstalledUpiApplications(
//           statusType: UpiApplicationDiscoveryAppStatusType.all,
//         );
//         setState(() {});
//       }
//     });
//   }

//   Future<void> _createPendingTransaction(String transactionRef) async {
//     final orderId = widget.orderDetails?["order_id"];

//     if (orderId == null) {
//       print("⚠️ Order ID missing");
//       return;
//     }

//     try {
//       final success = await ApiService.createTransaction(
//         orderId: orderId,
//         transactionRef: transactionRef,
//         amount: double.parse(_amountController.text),
//         status: "pending",
//       );

//       if (success) {
//         print("✅ Pending transaction created: $transactionRef");
//       } else {
//         print("❌ Transaction API failed");
//       }
//     } catch (e) {
//       print("❌ Failed to create pending transaction: $e");
//     }
//   }

//   // ✅ Update transaction status
//   Future<void> _updateTransactionStatus(
//     String transactionRef,
//     String status,
//     String upiResponse,
//   ) async {
//     try {
//       await ApiService.updateTransaction(
//         transactionRef: transactionRef,
//         status: status,
//         upiResponse: upiResponse,
//       );
//       print("✅ Transaction status updated: $transactionRef -> $status");
//     } catch (e) {
//       print("❌ Failed to update transaction: $e");
//     }
//   }

//   Future<void> _confirmPaymentToBackend(String transactionRef) async {
//     final orderId = widget.orderDetails?["order_id"];

//     if (orderId == null) {
//       throw Exception("Order ID missing");
//     }

//     final success = await ApiService.confirmPayment(
//       orderId: orderId,
//       transactionRef: transactionRef, // ✅ Pass transaction ref
//       paymentMethod: "UPI",
//     );

//     if (!success) {
//       throw Exception("Backend payment confirmation failed");
//     }

//     // ✅ Payment success થયા પછી cart clear કરો
//     try {
//       if (mounted) {
//         await context.read<CartProvider>().clearCart(
//           1,
//         ); // userId = 1 (તમારા user ID મુજબ બદલો)
//         log("🗑️ Cart cleared after successful payment");
//       }
//     } catch (e) {
//       log("⚠️ Error clearing cart: $e");
//       // Cart clear ન થાય તો પણ આગળ વધો (payment તો successful છે)
//     }
//   }

//   @override
//   void dispose() {
//     _amountController.dispose();
//     _upiAddressController.dispose();
//     _slideController.dispose();
//     _fadeController.dispose();
//     _pulseController.dispose();
//     _confettiController.dispose();
//     super.dispose();
//   }

//   // ✅ Updated _onTap function
//   Future<void> _onTap(ApplicationMeta app) async {
//     final err = _validateUpiAddress(_upiAddressController.text);
//     if (err != null) {
//       setState(() => _upiAddrError = err);
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
//       return;
//     }

//     setState(() => _upiAddrError = null);
//     setState(() => _isProcessing = true);

//     // ✅ Generate transaction ref
//     final transactionRef = DateTime.now().millisecondsSinceEpoch.toString();
//     _currentTransactionRef = transactionRef; // ✅ Store it

//     // ✅ Create pending transaction first
//     await _createPendingTransaction(transactionRef);

//     try {
//       final result = await _upiPayPlugin.initiateTransaction(
//         // amount: _amountController.text,
//         amount: "1",

//         app: app.upiApplication,
//         receiverName: 'Test Merchant',
//         receiverUpiAddress: _upiAddressController.text,
//         transactionRef: transactionRef,
//         transactionNote: 'UPI Payment',
//       );

//       print("UPI Result: $result");

//       final isSuccess = result.toString().toLowerCase().contains('success');

//       // ✅ Pass transaction ref and UPI response
//       _handlePaymentResult(isSuccess, transactionRef, result.toString());
//     } catch (e) {
//       print("UPI Error: $e");
//       setState(() => _isProcessing = false);
//       _handlePaymentResult(false, transactionRef, e.toString());
//     }
//   }

//   // ✅ Updated with transaction ref and UPI response
//   void _handlePaymentResult(
//     bool isSuccess,
//     String transactionRef,
//     String upiResponse,
//   ) async {
//     setState(() => _isProcessing = false);

//     if (!isSuccess) {
//       // ✅ Mark as failed in backend
//       await _updateTransactionStatus(transactionRef, "failed", upiResponse);
//       _showFailureDialog();
//       return;
//     }

//     // ✅ Payment successful - update backend
//     try {
//       await _updateTransactionStatus(transactionRef, "success", upiResponse);
//       await _confirmPaymentToBackend(transactionRef); // ✅ Pass transaction ref

//       _confettiController.play();
//       _showSuccessDialog();
//     } catch (e) {
//       print("Backend Error: $e");
//       _showPaymentSuccessButBackendFailDialog(transactionRef); // ✅ Pass ref
//     }
//   }

//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//         child: Stack(
//           children: [
//             Padding(
//               padding: const EdgeInsets.all(32),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   TweenAnimationBuilder<double>(
//                     tween: Tween(begin: 0, end: 1),
//                     duration: const Duration(milliseconds: 600),
//                     builder: (context, double value, child) {
//                       return Transform.scale(
//                         scale: value,
//                         child: Container(
//                           padding: const EdgeInsets.all(20),
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             gradient: LinearGradient(
//                               colors: [
//                                 Colors.green.shade400,
//                                 Colors.green.shade600,
//                               ],
//                             ),
//                           ),
//                           child: const Icon(
//                             Icons.check_circle,
//                             size: 60,
//                             color: Colors.white,
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 24),
//                   Text(
//                     'Payment Successful! 💎',
//                     style: GoogleFonts.poppins(
//                       fontSize: 24,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.green.shade700,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     'Your order has been confirmed',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       color: Colors.grey.shade600,
//                     ),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 8),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 16,
//                       vertical: 8,
//                     ),
//                     decoration: BoxDecoration(
//                       color: Colors.green.shade50,
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: Text(
//                       '₹ ${_amountController.text}',
//                       style: GoogleFonts.poppins(
//                         fontSize: 20,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.green.shade700,
//                       ),
//                     ),
//                   ),
//                   // ✅ Show transaction ref
//                   if (_currentTransactionRef != null) ...[
//                     const SizedBox(height: 12),
//                     Text(
//                       'Transaction ID: $_currentTransactionRef',
//                       style: GoogleFonts.poppins(
//                         fontSize: 11,
//                         color: Colors.grey.shade500,
//                       ),
//                     ),
//                   ],
//                   const SizedBox(height: 24),
//                   ElevatedButton(
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                       Navigator.of(context).pop();
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.green,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 40,
//                         vertical: 16,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                     ),
//                     child: Text(
//                       'Back to Home',
//                       style: GoogleFonts.poppins(
//                         color: Colors.white,
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Positioned.fill(
//               child: IgnorePointer(
//                 child: ConfettiWidget(
//                   confettiController: _confettiController,
//                   blastDirectionality: BlastDirectionality.explosive,
//                   numberOfParticles: 30,
//                   colors: const [
//                     Colors.green,
//                     Colors.blue,
//                     Colors.pink,
//                     Colors.orange,
//                     Colors.purple,
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ✅ New dialog - Payment success but backend failed
//   void _showPaymentSuccessButBackendFailDialog(String transactionRef) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//         child: Padding(
//           padding: const EdgeInsets.all(32),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.orange.shade100,
//                 ),
//                 child: Icon(
//                   Icons.warning_rounded,
//                   size: 60,
//                   color: Colors.orange.shade700,
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 'Payment Done! ⚠️',
//                 style: GoogleFonts.poppins(
//                   fontSize: 24,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.orange.shade700,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'Your payment was successful but we couldn\'t confirm it with our server. Please save this transaction ID:',
//                 style: GoogleFonts.poppins(
//                   fontSize: 13,
//                   color: Colors.grey.shade600,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 16),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.shade50,
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.orange.shade200),
//                 ),
//                 child: Column(
//                   children: [
//                     Text(
//                       'Transaction ID',
//                       style: GoogleFonts.poppins(
//                         fontSize: 11,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     SelectableText(
//                       transactionRef,
//                       style: GoogleFonts.robotoMono(
//                         fontSize: 14,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.orange.shade900,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       'Amount: ₹${_amountController.text}',
//                       style: GoogleFonts.poppins(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w700,
//                         color: Colors.orange.shade700,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton.icon(
//                       onPressed: () {
//                         Navigator.of(context).pop();
//                         Navigator.of(context).pop();
//                       },
//                       icon: const Icon(Icons.home, size: 18),
//                       label: Text(
//                         'View History',
//                         style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//                       ),
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         side: BorderSide(color: Colors.grey.shade300),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton.icon(
//                       onPressed: () async {
//                         // ✅ Retry backend save
//                         try {
//                           await _confirmPaymentToBackend(transactionRef);
//                           Navigator.of(context).pop();
//                           _confettiController.play();
//                           _showSuccessDialog();
//                         } catch (e) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text(
//                                 'Still failed. Please contact support.',
//                               ),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                         }
//                       },
//                       icon: const Icon(Icons.refresh, size: 18),
//                       label: Text(
//                         'Retry',
//                         style: GoogleFonts.poppins(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.orange,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showFailureDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
//         child: Padding(
//           padding: const EdgeInsets.all(32),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TweenAnimationBuilder<double>(
//                 tween: Tween(begin: 0, end: 1),
//                 duration: const Duration(milliseconds: 600),
//                 builder: (context, double value, child) {
//                   return Transform.scale(
//                     scale: value,
//                     child: Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         gradient: LinearGradient(
//                           colors: [Colors.red.shade400, Colors.red.shade600],
//                         ),
//                       ),
//                       child: const Icon(
//                         Icons.close,
//                         size: 60,
//                         color: Colors.white,
//                       ),
//                     ),
//                   );
//                 },
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 'Payment Failed',
//                 style: GoogleFonts.poppins(
//                   fontSize: 24,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.red.shade700,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'Something went wrong. Please try again.',
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: Colors.grey.shade600,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 children: [
//                   Expanded(
//                     child: OutlinedButton(
//                       onPressed: () => Navigator.of(context).pop(),
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         side: BorderSide(color: Colors.grey.shade300),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: Text(
//                         'Cancel',
//                         style: GoogleFonts.poppins(
//                           color: Colors.grey.shade700,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.of(context).pop();
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.deepPurple,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: Text(
//                         'Retry',
//                         style: GoogleFonts.poppins(
//                           color: Colors.white,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xffF8F9FB),
//       appBar: AnimatedPaymentAppBar(),
//       body: SafeArea(
//         child: FadeTransition(
//           opacity: _fadeAnimation,
//           child: SlideTransition(
//             position: _slideAnimation,
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 children: [
//                   _buildAmountCard(),
//                   const SizedBox(height: 20),
//                   _buildUpiSection(),
//                   const SizedBox(height: 100),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//       bottomSheet: _buildPaymentButton(),
//     );
//   }

//   Widget _buildAmountCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Color(0xff6366F1), Color(0xff8B5CF6)],
//         ),
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.deepPurple.withOpacity(0.3),
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Text(
//                 'Total Amount',
//                 style: GoogleFonts.poppins(
//                   color: Colors.white.withOpacity(0.9),
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 5,
//                 ),
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.2),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(
//                       Icons.verified_user,
//                       size: 12,
//                       color: Colors.white,
//                     ),
//                     const SizedBox(width: 4),
//                     Text(
//                       'Secured',
//                       style: GoogleFonts.poppins(
//                         color: Colors.white,
//                         fontSize: 10,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 '₹',
//                 style: GoogleFonts.poppins(
//                   color: Colors.white,
//                   fontSize: 24,
//                   fontWeight: FontWeight.w700,
//                 ),
//               ),
//               const SizedBox(width: 4),
//               Text(
//                 _amountController.text,
//                 style: GoogleFonts.poppins(
//                   color: Colors.white,
//                   fontSize: 40,
//                   fontWeight: FontWeight.w800,
//                   height: 1.0,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Container(
//             padding: const EdgeInsets.all(10),
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(10),
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.info_outline, size: 14, color: Colors.white),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     'Complete payment to confirm order',
//                     style: GoogleFonts.poppins(
//                       color: Colors.white,
//                       fontSize: 11,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUpiSection() {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(18),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 15,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: Colors.deepPurple.shade50,
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(
//                   Icons.account_balance,
//                   color: Colors.deepPurple,
//                   size: 20,
//                 ),
//               ),
//               const SizedBox(width: 10),
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'UPI Payment',
//                     style: GoogleFonts.poppins(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   Text(
//                     'Pay using any UPI app',
//                     style: GoogleFonts.poppins(
//                       fontSize: 11,
//                       color: Colors.grey,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//           if (_upiAddrError != null)
//             Padding(
//               padding: const EdgeInsets.only(top: 12, left: 4),
//               child: Text(
//                 _upiAddrError!,
//                 style: GoogleFonts.poppins(color: Colors.red, fontSize: 11),
//               ),
//             ),
//           if (_apps != null && Platform.isAndroid) ...[
//             const SizedBox(height: 20),
//             Text(
//               'Choose Payment App',
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 12),
//             SizedBox(
//               height: 80,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: _apps!.length,
//                 itemBuilder: (context, index) {
//                   final app = _apps![index];
//                   return InkWell(
//                     onTap: () => _onTap(app),
//                     child: Container(
//                       width: 70,
//                       margin: const EdgeInsets.only(right: 12),
//                       child: Column(
//                         children: [
//                           Container(
//                             padding: const EdgeInsets.all(10),
//                             decoration: BoxDecoration(
//                               color: Colors.grey.shade50,
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(color: Colors.grey.shade200),
//                             ),
//                             child: app.iconImage(32),
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             app.upiApplication.getAppName(),
//                             textAlign: TextAlign.center,
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                             style: GoogleFonts.poppins(fontSize: 10),
//                           ),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildPaymentButton() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 20,
//             offset: const Offset(0, -5),
//           ),
//         ],
//       ),
//       child: SafeArea(
//         child: ScaleTransition(
//           scale: _pulseAnimation,
//           child: SizedBox(
//             width: double.infinity,
//             child: ElevatedButton(
//               onPressed: _isProcessing
//                   ? null
//                   : () {
//                       if (_apps == null || _apps!.isEmpty) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(
//                             content: Text(
//                               'No UPI apps found. Please install a UPI app.',
//                             ),
//                             backgroundColor: Colors.red,
//                           ),
//                         );
//                       } else {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               'Please select a UPI app to continue',
//                             ),
//                             backgroundColor: Colors.deepPurple,
//                           ),
//                         );
//                       }
//                     },
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.deepPurple,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(14),
//                 ),
//                 elevation: 0,
//               ),
//               child: _isProcessing
//                   ? Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation(Colors.white),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Text(
//                           'Processing...',
//                           style: GoogleFonts.poppins(
//                             color: Colors.white,
//                             fontSize: 15,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     )
//                   : Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Icon(Icons.lock, color: Colors.white, size: 18),
//                         const SizedBox(width: 10),
//                         Text(
//                           'Pay ₹${_amountController.text}',
//                           style: GoogleFonts.poppins(
//                             color: Colors.white,
//                             fontSize: 15,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   String? _validateUpiAddress(String value) {
//     if (value.isEmpty) return 'UPI VPA is required.';
//     if (value.split('@').length != 2) return 'Invalid UPI VPA';
//     return null;
//   }
// }

// class AnimatedPaymentAppBar extends StatefulWidget
//     implements PreferredSizeWidget {
//   const AnimatedPaymentAppBar({super.key});

//   @override
//   Size get preferredSize => const Size.fromHeight(100);

//   @override
//   State<AnimatedPaymentAppBar> createState() => _AnimatedPaymentAppBarState();
// }

// class _AnimatedPaymentAppBarState extends State<AnimatedPaymentAppBar>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _fade;
//   late Animation<Offset> _slide;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 700),
//     );
//     _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
//     _slide = Tween<Offset>(
//       begin: const Offset(0, -0.3),
//       end: Offset.zero,
//     ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
//     _controller.forward();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       elevation: 0,
//       color: Colors.white,
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [Colors.deepPurple.shade50, Colors.white],
//           ),
//         ),
//         child: SafeArea(
//           bottom: false,
//           child: FadeTransition(
//             opacity: _fade,
//             child: SlideTransition(
//               position: _slide,
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 12),
//                 child: Row(
//                   children: [
//                     IconButton(
//                       icon: Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade100,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: const Icon(Icons.arrow_back_ios_new, size: 18),
//                       ),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                     const Spacer(),
//                     Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const SizedBox(height: 8),
//                         Icon(
//                           Icons.payment_rounded,
//                           size: 32,
//                           color: Colors.deepPurple,
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Secure Payment',
//                           style: GoogleFonts.poppins(
//                             fontSize: 20,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.deepPurple,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const Spacer(),
//                     const SizedBox(width: 48),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:developer';
import 'dart:io';
import 'package:demo/screens/Auth/dashboard_screen.dart';
import 'package:demo/services/api_service.dart';
import 'package:demo/services/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:upi_pay/upi_pay.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:confetti/confetti.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final Map<String, dynamic>? orderDetails;

  const PaymentScreen({super.key, this.totalAmount = 0, this.orderDetails});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  String? _upiAddrError;
  final _upiAddressController = TextEditingController();
  final _amountController = TextEditingController();
  final _upiPayPlugin = UpiPay();
  List<ApplicationMeta>? _apps;

  String? _currentTransactionRef;
  bool _isProcessing = false;
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.totalAmount > 0
        ? widget.totalAmount.toStringAsFixed(2)
        : "1.00";

    _upiAddressController.text = "sawan00meena@ucobank";

    // Animations setup
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideController.forward();
    _fadeController.forward();

    // 🔥 Load UPI apps only on mobile (not web)
    if (!kIsWeb && Platform.isAndroid) {
      Future.delayed(Duration.zero, () async {
        _apps = await _upiPayPlugin.getInstalledUpiApplications(
          statusType: UpiApplicationDiscoveryAppStatusType.all,
        );
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _upiAddressController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // Generate UPI String
  String get _upiString {
    _currentTransactionRef ??= DateTime.now().millisecondsSinceEpoch.toString();
    return 'upi://pay?pa=${_upiAddressController.text}'
        '&pn=Test%20Merchant'
        '&am=${_amountController.text}'
        '&cu=INR'
        '&tn=Order%20Payment'
        '&tr=$_currentTransactionRef';
  }

  // ✅ Create pending transaction
  Future<void> _createPendingTransaction(String transactionRef) async {
    final orderId = widget.orderDetails?["order_id"];

    if (orderId == null) {
      print("⚠️ Order ID missing");
      return;
    }

    try {
      final success = await ApiService.createTransaction(
        orderId: orderId,
        transactionRef: transactionRef,
        amount: double.parse(_amountController.text),
        status: "pending",
      );

      if (success) {
        print("✅ Pending transaction created: $transactionRef");
      } else {
        print("❌ Transaction API failed");
      }
    } catch (e) {
      print("❌ Failed to create pending transaction: $e");
    }
  }

  // ✅ Update transaction status
  Future<void> _updateTransactionStatus(
    String transactionRef,
    String status,
    String upiResponse,
  ) async {
    try {
      await ApiService.updateTransaction(
        transactionRef: transactionRef,
        status: status,
        upiResponse: upiResponse,
      );
      print("✅ Transaction status updated: $transactionRef -> $status");
    } catch (e) {
      print("❌ Failed to update transaction: $e");
    }
  }

  // ✅ Confirm payment to backend
  Future<void> _confirmPaymentToBackend(String transactionRef) async {
    final orderId = widget.orderDetails?["order_id"];

    if (orderId == null) {
      throw Exception("Order ID missing");
    }

    final success = await ApiService.confirmPayment(
      orderId: orderId,
      transactionRef: transactionRef,
      paymentMethod: "UPI",
    );

    if (!success) {
      throw Exception("Backend payment confirmation failed");
    }

    // ✅ Payment success થયા પછી cart clear કરો
    try {
      if (mounted) {
        await context.read<CartProvider>().clearCart(1);
        log("🗑️ Cart cleared after successful payment");
      }
    } catch (e) {
      log("⚠️ Error clearing cart: $e");
    }
  }

  // ✅ Mobile UPI Payment
  Future<void> _onTap(ApplicationMeta app) async {
    final err = _validateUpiAddress(_upiAddressController.text);
    if (err != null) {
      setState(() => _upiAddrError = err);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(err), backgroundColor: Colors.red));
      return;
    }

    setState(() => _upiAddrError = null);
    setState(() => _isProcessing = true);

    final transactionRef = DateTime.now().millisecondsSinceEpoch.toString();
    _currentTransactionRef = transactionRef;

    await _createPendingTransaction(transactionRef);

    try {
      final result = await _upiPayPlugin.initiateTransaction(
        amount: "1",
        app: app.upiApplication,
        receiverName: 'Test Merchant',
        receiverUpiAddress: _upiAddressController.text,
        transactionRef: transactionRef,
        transactionNote: 'UPI Payment',
      );

      print("UPI Result: $result");

      final isSuccess = result.toString().toLowerCase().contains('success');
      _handlePaymentResult(isSuccess, transactionRef, result.toString());
    } catch (e) {
      print("UPI Error: $e");
      setState(() => _isProcessing = false);
      _handlePaymentResult(false, transactionRef, e.toString());
    }
  }

  // ✅ Handle payment result
  void _handlePaymentResult(
    bool isSuccess,
    String transactionRef,
    String upiResponse,
  ) async {
    setState(() => _isProcessing = false);

    if (!isSuccess) {
      await _updateTransactionStatus(transactionRef, "failed", upiResponse);
      _showFailureDialog();
      return;
    }

    try {
      await _updateTransactionStatus(transactionRef, "success", upiResponse);
      await _confirmPaymentToBackend(transactionRef);

      _confettiController.play();
      _showSuccessDialog();
    } catch (e) {
      print("Backend Error: $e");
      _showPaymentSuccessButBackendFailDialog(transactionRef);
    }
  }

  // ✅ Web payment verification
  void _verifyWebPayment() async {
    setState(() => _isProcessing = true);

    try {
      await _updateTransactionStatus(
        _currentTransactionRef!,
        'success',
        'Web QR Payment',
      );

      await _confirmPaymentToBackend(_currentTransactionRef!);

      _confettiController.play();
      _showSuccessDialog();
    } catch (e) {
      log('Payment verification error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment verification failed'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebPaymentUI();
    } else {
      return _buildMobilePaymentUI();
    }
  }

  // 🌐 WEB UI - QR Code Payment
  Widget _buildWebPaymentUI() {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      appBar: AppBar(
        title: Text('Secure Payment', style: GoogleFonts.poppins()),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                children: [
                  _buildAmountCard(),
                  const SizedBox(height: 24),

                  // QR Code Container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Scan QR Code',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // QR Code
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.deepPurple,
                              width: 3,
                            ),
                          ),
                          child: QrImageView(
                            data: _upiString,
                            version: QrVersions.auto,
                            size: 200,
                            backgroundColor: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 16),

                        Text(
                          'Scan with any UPI app',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _upiAppIcon('GPay'),
                            _upiAppIcon('PhonePe'),
                            _upiAppIcon('Paytm'),
                            _upiAppIcon('BHIM'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Manual UPI ID
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Or pay manually to UPI ID:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _upiAddressController.text,
                                style: GoogleFonts.robotoMono(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, size: 20),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('UPI ID Copied!'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Steps:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[900],
                          ),
                        ),
                        const SizedBox(height: 8),
                        _instructionStep('1', 'Open any UPI app'),
                        _instructionStep('2', 'Scan QR or enter UPI ID'),
                        _instructionStep('3', 'Complete payment'),
                        _instructionStep('4', 'Click "I Have Paid" below'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Payment Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _verifyWebPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'I Have Paid',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    '⚠️ Do not close this page',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _upiAppIcon(String name) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(name, style: GoogleFonts.poppins(fontSize: 10)),
    );
  }

  Widget _instructionStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$num.',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 13))),
        ],
      ),
    );
  }

  // 📱 MOBILE UI
  Widget _buildMobilePaymentUI() {
    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      appBar: AnimatedPaymentAppBar(),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildAmountCard(),
                  const SizedBox(height: 20),
                  _buildUpiSection(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomSheet: _buildPaymentButton(),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff6366F1), Color(0xff8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: GoogleFonts.poppins(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Secured',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '₹',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _amountController.text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 14, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Complete payment to confirm order',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.account_balance,
                  color: Colors.deepPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UPI Payment',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Pay using any UPI app',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_upiAddrError != null)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 4),
              child: Text(
                _upiAddrError!,
                style: GoogleFonts.poppins(color: Colors.red, fontSize: 11),
              ),
            ),
          if (_apps != null && Platform.isAndroid) ...[
            const SizedBox(height: 20),
            Text(
              'Choose Payment App',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _apps!.length,
                itemBuilder: (context, index) {
                  final app = _apps![index];
                  return InkWell(
                    onTap: () => _onTap(app),
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: app.iconImage(32),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            app.upiApplication.getAppName(),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: ScaleTransition(
          scale: _pulseAnimation,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () {
                      if (_apps == null || _apps!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'No UPI apps found. Please install a UPI app.',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please select a UPI app to continue',
                            ),
                            backgroundColor: Colors.deepPurple,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Processing...',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, color: Colors.white, size: 18),
                        const SizedBox(width: 10),
                        Text(
                          'Pay ₹${_amountController.text}',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  String? _validateUpiAddress(String value) {
    if (value.isEmpty) return 'UPI VPA is required.';
    if (value.split('@').length != 2) return 'Invalid UPI VPA';
    return null;
  }

  // ================= DIALOGS =================

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.green.shade400,
                                Colors.green.shade600,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Payment Successful! 💎',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.green.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your order has been confirmed',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₹ ${_amountController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                  if (_currentTransactionRef != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Transaction ID: $_currentTransactionRef',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                      //                  Navigator.pushReplacement(
                      //   context,
                      //   MaterialPageRoute(builder: (_) => MainLayout()),
                      // );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Back to Home',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  numberOfParticles: 30,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ New dialog - Payment success but backend failed
  void _showPaymentSuccessButBackendFailDialog(String transactionRef) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.shade100,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  size: 60,
                  color: Colors.orange.shade700,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Payment Done! ⚠️',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Your payment was successful but we couldn\'t confirm it with our server. Please save this transaction ID:',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      'Transaction ID',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      transactionRef,
                      style: GoogleFonts.robotoMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Amount: ₹${_amountController.text}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.home, size: 18),
                      label: Text(
                        'View History',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // ✅ Retry backend save
                        try {
                          await _confirmPaymentToBackend(transactionRef);
                          Navigator.of(context).pop();
                          _confettiController.play();
                          _showSuccessDialog();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Still failed. Please contact support.',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(
                        'Retry',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
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

  void _showFailureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Colors.red.shade400, Colors.red.shade600],
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Payment Failed',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Something went wrong. Please try again.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Retry',
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

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     backgroundColor: const Color(0xffF8F9FB),
  //     appBar: AnimatedPaymentAppBar(),
  //     body: SafeArea(
  //       child: FadeTransition(
  //         opacity: _fadeAnimation,
  //         child: SlideTransition(
  //           position: _slideAnimation,
  //           child: SingleChildScrollView(
  //             padding: const EdgeInsets.all(20),
  //             child: Column(
  //               children: [
  //                 _buildAmountCard(),
  //                 const SizedBox(height: 20),
  //                 _buildUpiSection(),
  //                 const SizedBox(height: 100),
  //               ],
  //             ),
  //           ),
  //         ),
  //       ),
  //     ),
  //     bottomSheet: _buildPaymentButton(),
  //   );
  // }
}

class AnimatedPaymentAppBar extends StatefulWidget
    implements PreferredSizeWidget {
  const AnimatedPaymentAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(100);

  @override
  State<AnimatedPaymentAppBar> createState() => _AnimatedPaymentAppBarState();
}

class _AnimatedPaymentAppBarState extends State<AnimatedPaymentAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.deepPurple.shade50, Colors.white],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 18),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        Icon(
                          Icons.payment_rounded,
                          size: 32,
                          color: Colors.deepPurple,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Secure Payment',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.deepPurple,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
