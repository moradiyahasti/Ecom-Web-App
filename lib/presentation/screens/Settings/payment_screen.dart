// import 'dart:developer';
// import 'dart:io';
// import 'package:demo/data/services/api_service.dart';
// import 'package:demo/data/providers/cart_provider.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:provider/provider.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:upi_pay/upi_pay.dart';
// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart';

// /// UNIVERSAL PAYMENT SCREEN
// /// Mobile: UPI Pay package (automatic verification)
// /// Web: QR Code + Manual "I Have Paid" button

// class PaymentScreen extends StatefulWidget {
//   final double totalAmount;
//   final Map<String, dynamic>? orderDetails;

//   const PaymentScreen({super.key, this.totalAmount = 0, this.orderDetails});

//   @override
//   _PaymentScreenState createState() => _PaymentScreenState();
// }

// class _PaymentScreenState extends State<PaymentScreen> {
//   final _upiAddressController = TextEditingController();
//   final _amountController = TextEditingController();
//   UpiPay? _upiPayPlugin; // Nullable for web

//   String? _currentTransactionRef;
//   bool _isProcessing = false;
//   bool _transactionCreated = false;
//   // For web manual verification

//   List<ApplicationMeta>? _apps;

//   StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
//   bool _hasNetworkConnection = true;

//   @override
//   void initState() {
//     super.initState();

//     _initConnectivity();

//     // Set amount from widget
//     _amountController.text = /* widget.totalAmount.toString() */ "10";
//     // Set UPI address
//     _upiAddressController.text = "moradiyahasti-2@okhdfcbank";

//     // Generate unique transaction reference
//     _currentTransactionRef = DateTime.now().millisecondsSinceEpoch.toString();

//     // ✅ Initialize UPI Pay ONLY on mobile
//     if (!kIsWeb) {
//       _upiPayPlugin = UpiPay();
//       _discoverUpiApps();
//     } else {
//       log("🌐 Running on WEB - Using QR + Manual verification");
//     }

//     log("📱 Payment Screen Initialized");
//     log("🌐 Platform: ${kIsWeb ? 'WEB' : 'MOBILE'}");
//     log("💰 Amount: ₹${1}");
//     log("📝 Transaction Ref: $_currentTransactionRef");
//   }

//   Future<void> _discoverUpiApps() async {
//     if (kIsWeb || _upiPayPlugin == null) return;

//     try {
//       _apps = await _upiPayPlugin!.getInstalledUpiApplications(
//         statusType: UpiApplicationDiscoveryAppStatusType.all,
//       );

//       if (mounted) {
//         setState(() {});
//       }

//       log("📱 Found ${_apps?.length ?? 0} UPI apps");
//     } catch (e) {
//       log("❌ Error discovering UPI apps: $e");
//     }
//   }

//   Future<void> _initConnectivity() async {
//     try {
//       final result = await Connectivity().checkConnectivity();
//       _hasNetworkConnection = result.any(
//         (r) => r == ConnectivityResult.mobile || r == ConnectivityResult.wifi,
//       );
//     } catch (e) {
//       log('❌ Connectivity check error: $e');
//     }

//     _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
//       results,
//     ) {
//       final hasConnection = results.any(
//         (result) =>
//             result == ConnectivityResult.mobile ||
//             result == ConnectivityResult.wifi,
//       );

//       if (mounted) {
//         setState(() => _hasNetworkConnection = hasConnection);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _connectivitySubscription?.cancel();
//     _amountController.dispose();
//     _upiAddressController.dispose();
//     super.dispose();
//   }

//   String get _upiString =>
//       'upi://pay?pa=${_upiAddressController.text}&pn=ShreeNails&am=${1}&cu=INR&tn=Order%20Payment&tr=$_currentTransactionRef';

//   /// ✅ STEP 1: Create pending transaction in database
//   Future<bool> _createPendingTransaction(String transactionRef) async {
//     if (_transactionCreated) {
//       log("⚠️ Transaction already created");
//       return true;
//     }

//     final orderId = widget.orderDetails?["order_id"];
//     if (orderId == null) {
//       log("❌ Order ID missing");
//       return false;
//     }

//     try {
//       log("══════════════════════════════════════════");
//       log("📝 STEP 1: Creating PENDING transaction");
//       log("   Order ID: $orderId");
//       log("   Transaction Ref: $transactionRef");
//       log("   Amount: ₹${1}");
//       log("══════════════════════════════════════════");

//       final success = await ApiService.createTransaction(
//         orderId: orderId,
//         transactionRef: transactionRef,
//         amount: double.parse("1"),
//         status: "pending",
//       );

//       if (success) {
//         _transactionCreated = true;
//         log("✅ Transaction created with PENDING status");
//         return true;
//       } else {
//         log("❌ Failed to create transaction");
//         return false;
//       }
//     } catch (e) {
//       log("❌ Create transaction error: $e");
//       return false;
//     }
//   }

//   /// 📱 MOBILE: Open UPI app and initiate payment
//   Future<void> _initiateUpiPayment(ApplicationMeta app) async {
//     if (_isProcessing || _upiPayPlugin == null) return;

//     setState(() => _isProcessing = true);

//     try {
//       log("══════════════════════════════════════════");
//       log("🚀 Opening UPI app: ${app.upiApplication.getAppName()}");
//       log("══════════════════════════════════════════");

//       final created = await _createPendingTransaction(_currentTransactionRef!);

//       if (!created) {
//         throw Exception("Failed to create transaction");
//       }

//       log("📱 Launching UPI app...");

//       final response = await _upiPayPlugin!.initiateTransaction(
//         amount: "1",
//         app: app.upiApplication,
//         receiverName: 'ShreeNails',
//         receiverUpiAddress: _upiAddressController.text,
//         transactionRef: _currentTransactionRef!,
//         transactionNote: 'Order Payment',
//       );

//       log("══════════════════════════════════════════");
//       log("📥 UPI Response Received");
//       log("   Status: ${response.status}");
//       log("   Transaction ID: ${response.txnId}");
//       log("══════════════════════════════════════════");

//       if (!mounted) return;

//       await _handleUpiResponse(response);
//     } catch (e) {
//       log("❌ UPI Payment Error: $e");

//       if (mounted) {
//         setState(() => _isProcessing = false);

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Payment failed: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   /// 📱 MOBILE: Handle UPI response
//   Future<void> _handleUpiResponse(UpiTransactionResponse response) async {
//     try {
//       String status;
//       String upiResponse;

//       if (response.status == UpiTransactionStatus.success) {
//         status = 'success';
//         upiResponse = 'Payment successful - TxnID: ${response.txnId}';
//         log("✅ UPI Payment SUCCESS");
//       } else if (response.status == UpiTransactionStatus.failure) {
//         status = 'failed';
//         upiResponse = 'Payment failed - ${response.responseCode}';
//         log("❌ UPI Payment FAILED");
//       } else {
//         status = 'pending';
//         upiResponse = 'Payment pending or cancelled';
//         log("⏳ UPI Payment PENDING/CANCELLED");
//       }

//       log("══════════════════════════════════════════");
//       log("📝 STEP 3: Updating transaction status");
//       log("   Status: $status");
//       log("══════════════════════════════════════════");

//       await ApiService.updateTransaction(
//         transactionRef: _currentTransactionRef!,
//         status: status,
//         upiResponse: upiResponse,
//       );

//       if (status == 'success') {
//         log("📝 STEP 4: Confirming payment to backend");

//         await _confirmPaymentToBackend(_currentTransactionRef!);

//         if (mounted) {
//           setState(() => _isProcessing = false);
//           _showSuccessDialog();
//         }
//       } else {
//         if (mounted) {
//           setState(() => _isProcessing = false);
//           _showFailureDialog(upiResponse);
//         }
//       }
//     } catch (e) {
//       log("❌ Handle response error: $e");

//       if (mounted) {
//         setState(() => _isProcessing = false);

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error processing payment: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   /// 🌐 WEB: Manual payment verification
//   Future<void> _checkPaymentManually() async {
//     if (_currentTransactionRef == null || _isProcessing) return;

//     setState(() => _isProcessing = true);

//     try {
//       log('══════════════════════════════════════════');
//       log('🌐 WEB: User clicked "I Have Paid" button');

//       // Create transaction if not created yet
//       if (!_transactionCreated) {
//         log('📝 Creating transaction...');
//         await _createPendingTransaction(_currentTransactionRef!);
//         await Future.delayed(const Duration(milliseconds: 500));
//       }

//       // Check payment status
//       log('🔍 Checking payment status from database...');

//       final status = await ApiService.getTransactionStatus(
//         _currentTransactionRef!,
//       ).timeout(const Duration(seconds: 10), onTimeout: () => 'pending');

//       if (!mounted) return;

//       log('📊 Payment Status: "$status"');

//       if (status == 'success') {
//         log('✅ PAYMENT SUCCESS!');

//         await ApiService.updateTransaction(
//           transactionRef: _currentTransactionRef!,
//           status: 'success',
//           upiResponse: 'Payment completed',
//         );

//         await _confirmPaymentToBackend(_currentTransactionRef!);

//         setState(() => _isProcessing = false);
//         _showSuccessDialog();
//       } else if (status == 'failed') {
//         log('❌ PAYMENT FAILED');
//         setState(() => _isProcessing = false);
//         _showFailureDialog('Payment was declined or failed');
//       } else {
//         log('⏳ Payment still pending');
//         setState(() => _isProcessing = false);

//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text(
//               'Payment is still pending. Complete payment and try again.',
//             ),
//             backgroundColor: Colors.orange,
//             duration: Duration(seconds: 3),
//           ),
//         );
//       }

//       log('══════════════════════════════════════════');
//     } catch (e) {
//       log('❌ Check payment error: $e');

//       if (mounted) {
//         setState(() => _isProcessing = false);

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error checking payment: $e'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   /// ✅ Confirm payment to backend
//   Future<void> _confirmPaymentToBackend(String transactionRef) async {
//     final orderId = widget.orderDetails?["order_id"];
//     if (orderId == null) throw Exception("Order ID missing");

//     log("📝 Confirming payment to backend");

//     final success = await ApiService.confirmPayment(
//       orderId: orderId,
//       transactionRef: transactionRef,
//       paymentMethod: "UPI",
//     ).timeout(const Duration(seconds: 15));

//     if (!success) throw Exception("Backend confirmation failed");

//     log("✅ Payment confirmed successfully");

//     if (mounted) {
//       final userId = widget.orderDetails?["user_id"];
//       if (userId != null) {
//         await context.read<CartProvider>().clearCart(userId);
//       }
//     }
//   }

//   void _showSuccessDialog() {
//     if (!mounted) return;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text('Payment Successful! 🎉'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.check_circle, size: 80, color: Colors.green),
//             const SizedBox(height: 16),
//             const Text(
//               'Your order has been confirmed',
//               style: TextStyle(fontSize: 16),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               '₹ ${1}',
//               style: const TextStyle(
//                 fontSize: 28,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.green,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.pop(context);
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green,
//               minimumSize: const Size(double.infinity, 48),
//             ),
//             child: const Text(
//               'Continue Shopping',
//               style: TextStyle(fontSize: 16, color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showFailureDialog(String reason) {
//     if (!mounted) return;

//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text('Payment Failed'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.error_outline, size: 80, color: Colors.red),
//             const SizedBox(height: 16),
//             Text(
//               reason,
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 14),
//             ),
//           ],
//         ),
//         actions: [
//           OutlinedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.pop(context);
//             },
//             child: const Text('Go Back'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               setState(() {
//                 _currentTransactionRef = DateTime.now().millisecondsSinceEpoch
//                     .toString();
//                 _transactionCreated = false;
//                 _isProcessing = false;
//               });
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
//             child: const Text(
//               'Retry Payment',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         title: Text(kIsWeb ? 'Payment (Web)' : 'Payment'),
//         backgroundColor: Colors.deepPurple,
//         foregroundColor: Colors.white,
//       ),
//       body: SafeArea(
//         child: _isProcessing
//             ? _buildProcessingView()
//             : SingleChildScrollView(
//                 padding: const EdgeInsets.all(16),
//                 child: Column(
//                   children: [
//                     // 🌐 WEB Platform Badge
//                     if (kIsWeb)
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         margin: const EdgeInsets.only(bottom: 16),
//                         decoration: BoxDecoration(
//                           color: Colors.blue[100],
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.blue),
//                         ),
//                         child: const Row(
//                           children: [
//                             Icon(Icons.language, color: Colors.blue),
//                             SizedBox(width: 12),
//                             Expanded(
//                               child: Text(
//                                 '🌐 Web Payment: Scan QR and verify manually',
//                                 style: TextStyle(fontWeight: FontWeight.bold),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),

//                     // Network Status
//                     if (!_hasNetworkConnection)
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         margin: const EdgeInsets.only(bottom: 16),
//                         decoration: BoxDecoration(
//                           color: Colors.orange[100],
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.orange),
//                         ),
//                         child: const Row(
//                           children: [
//                             Icon(Icons.wifi_off, color: Colors.orange),
//                             SizedBox(width: 12),
//                             Expanded(child: Text('No network connection')),
//                           ],
//                         ),
//                       ),

//                     // Amount Card
//                     Container(
//                       padding: const EdgeInsets.all(24),
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           colors: [Colors.deepPurple, Colors.purpleAccent],
//                         ),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Column(
//                         children: [
//                           const Text(
//                             'Total Amount',
//                             style: TextStyle(
//                               color: Colors.white70,
//                               fontSize: 16,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             '₹ ${1}',
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontSize: 40,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 24),

//                     // Payment Options
//                     Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 10,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         children: [
//                           const Text(
//                             'Pay Using UPI',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 20),

//                           // 📱 MOBILE: UPI Apps Grid
//                           if (!kIsWeb &&
//                               _apps != null &&
//                               _apps!.isNotEmpty) ...[
//                             const Text(
//                               'Select Your UPI App:',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.grey,
//                               ),
//                             ),
//                             const SizedBox(height: 12),
//                             _buildUpiAppsGrid(),
//                             const SizedBox(height: 24),
//                             const Row(
//                               children: [
//                                 Expanded(child: Divider()),
//                                 Padding(
//                                   padding: EdgeInsets.symmetric(horizontal: 16),
//                                   child: Text(
//                                     'OR',
//                                     style: TextStyle(color: Colors.grey),
//                                   ),
//                                 ),
//                                 Expanded(child: Divider()),
//                               ],
//                             ),
//                             const SizedBox(height: 24),
//                           ],

//                           // 📱 MOBILE: Loading
//                           if (!kIsWeb && (_apps == null || _apps!.isEmpty)) ...[
//                             const CircularProgressIndicator(),
//                             const SizedBox(height: 12),
//                             const Text('Discovering UPI apps...'),
//                             const SizedBox(height: 24),
//                           ],

//                           // QR Code (Both)
//                           const Text(
//                             'Scan QR Code',
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                           const SizedBox(height: 16),

//                           Container(
//                             padding: const EdgeInsets.all(16),
//                             decoration: BoxDecoration(
//                               color: Colors.white,
//                               border: Border.all(
//                                 color: Colors.deepPurple,
//                                 width: 3,
//                               ),
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: QrImageView(
//                               data: _upiString,
//                               version: QrVersions.auto,
//                               size: 220,
//                               backgroundColor: Colors.white,
//                             ),
//                           ),

//                           const SizedBox(height: 20),

//                           // UPI ID
//                           Container(
//                             padding: const EdgeInsets.all(16),
//                             decoration: BoxDecoration(
//                               color: Colors.grey[100],
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             child: Row(
//                               children: [
//                                 Expanded(
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       const Text(
//                                         'UPI ID:',
//                                         style: TextStyle(
//                                           fontSize: 12,
//                                           color: Colors.grey,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 4),
//                                       Text(
//                                         _upiAddressController.text,
//                                         style: const TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           fontSize: 16,
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 IconButton(
//                                   icon: const Icon(
//                                     Icons.copy,
//                                     color: Colors.deepPurple,
//                                   ),
//                                   onPressed: () {
//                                     Clipboard.setData(
//                                       ClipboardData(
//                                         text: _upiAddressController.text,
//                                       ),
//                                     );
//                                     ScaffoldMessenger.of(context).showSnackBar(
//                                       const SnackBar(
//                                         content: Text('UPI ID Copied!'),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                               ],
//                             ),
//                           ),

//                           // 🌐 WEB: Manual Check Button
//                           if (kIsWeb) ...[
//                             const SizedBox(height: 24),
//                             Container(
//                               padding: const EdgeInsets.all(16),
//                               decoration: BoxDecoration(
//                                 color: Colors.green[50],
//                                 borderRadius: BorderRadius.circular(12),
//                                 border: Border.all(
//                                   color: Colors.green,
//                                   width: 2,
//                                 ),
//                               ),
//                               child: Column(
//                                 children: [
//                                   const Icon(
//                                     Icons.check_circle_outline,
//                                     size: 48,
//                                     color: Colors.green,
//                                   ),
//                                   const SizedBox(height: 12),
//                                   const Text(
//                                     'Completed Payment?',
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.bold,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 8),
//                                   const Text(
//                                     'After payment via QR, click below to verify',
//                                     style: TextStyle(color: Colors.grey),
//                                     textAlign: TextAlign.center,
//                                   ),
//                                   const SizedBox(height: 16),
//                                   ElevatedButton.icon(
//                                     onPressed: _isProcessing
//                                         ? null
//                                         : _checkPaymentManually,
//                                     icon: _isProcessing
//                                         ? const SizedBox(
//                                             width: 20,
//                                             height: 20,
//                                             child: CircularProgressIndicator(
//                                               strokeWidth: 2,
//                                               color: Colors.white,
//                                             ),
//                                           )
//                                         : const Icon(Icons.verified),
//                                     label: Text(
//                                       _isProcessing
//                                           ? 'Checking...'
//                                           : 'I Have Paid',
//                                     ),
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.green,
//                                       minimumSize: const Size(
//                                         double.infinity,
//                                         50,
//                                       ),
//                                       textStyle: const TextStyle(
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     // Transaction ID
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.purple[50],
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Column(
//                         children: [
//                           const Text(
//                             'Transaction ID',
//                             style: TextStyle(fontSize: 11, color: Colors.grey),
//                           ),
//                           const SizedBox(height: 4),
//                           SelectableText(
//                             _currentTransactionRef ?? '',
//                             style: const TextStyle(
//                               fontSize: 13,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 16),

//                     // Instructions
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.blue[50],
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Row(
//                             children: [
//                               Icon(Icons.info_outline, color: Colors.blue),
//                               SizedBox(width: 8),
//                               Text(
//                                 'How to Pay:',
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 16,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 12),
//                           if (kIsWeb) ...[
//                             _buildInstruction(
//                               '1',
//                               'Scan QR code with your UPI app',
//                             ),
//                             _buildInstruction(
//                               '2',
//                               'Complete payment in UPI app',
//                             ),
//                             _buildInstruction(
//                               '3',
//                               'Click "I Have Paid" button above',
//                             ),
//                           ] else ...[
//                             _buildInstruction('1', 'Click UPI app OR scan QR'),
//                             _buildInstruction('2', 'Complete payment'),
//                             _buildInstruction('3', 'Auto-verified ✅'),
//                           ],
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }

//   Widget _buildProcessingView() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           const CircularProgressIndicator(
//             valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
//           ),
//           const SizedBox(height: 24),
//           Text(
//             'Processing Payment...',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[700],
//             ),
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'Please wait while we confirm your payment',
//             style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUpiAppsGrid() {
//     if (_apps == null || _apps!.isEmpty) return const SizedBox.shrink();

//     final sortedApps = List<ApplicationMeta>.from(_apps!);
//     sortedApps.sort(
//       (a, b) => a.upiApplication.getAppName().toLowerCase().compareTo(
//         b.upiApplication.getAppName().toLowerCase(),
//       ),
//     );

//     return GridView.count(
//       crossAxisCount: 4,
//       shrinkWrap: true,
//       mainAxisSpacing: 12,
//       crossAxisSpacing: 12,
//       childAspectRatio: 0.85,
//       physics: const NeverScrollableScrollPhysics(),
//       children: sortedApps.map((app) {
//         return InkWell(
//           onTap: Platform.isAndroid ? () => _initiateUpiPayment(app) : null,
//           child: Container(
//             decoration: BoxDecoration(
//               color: Colors.grey[50],
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.grey[300]!),
//             ),
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 app.iconImage(48),
//                 const SizedBox(height: 8),
//                 Text(
//                   app.upiApplication.getAppName(),
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w500,
//                   ),
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ],
//             ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _buildInstruction(String number, String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 24,
//             height: 24,
//             decoration: const BoxDecoration(
//               color: Colors.blue,
//               shape: BoxShape.circle,
//             ),
//             child: Center(
//               child: Text(
//                 number,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12,
//                 ),
//               ),
//             ),
//           ),
//           const SizedBox(width: 12),
//           Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
//         ],
//       ),
//     );
//   }
// }
