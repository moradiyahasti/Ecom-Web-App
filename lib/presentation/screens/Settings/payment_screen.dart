// import 'dart:developer';
// import 'package:demo/data/services/api_service.dart';
// import 'package:demo/data/providers/cart_provider.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:confetti/confetti.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'dart:async';
// import 'package:connectivity_plus/connectivity_plus.dart'; // Add this package

// class PaymentScreen extends StatefulWidget {
//   final double totalAmount;
//   final Map<String, dynamic>? orderDetails;

//   const PaymentScreen({super.key, this.totalAmount = 0, this.orderDetails});

//   @override
//   _PaymentScreenState createState() => _PaymentScreenState();
// }

// class _PaymentScreenState extends State<PaymentScreen>
//     with TickerProviderStateMixin, WidgetsBindingObserver {
//   final _upiAddressController = TextEditingController();
//   final _amountController = TextEditingController();

//   String? _currentTransactionRef;
//   bool _isProcessing = false;
//   bool _isWaitingForPayment = false;
//   bool _paymentConfirmed = false;
//   bool _hasShownDialog = false;

//   final ConfettiController _confettiController = ConfettiController(
//     duration: const Duration(seconds: 3),
//   );

//   late AnimationController _slideController;
//   late AnimationController _fadeController;
//   late Animation<Offset> _slideAnimation;
//   late Animation<double> _fadeAnimation;

//   Timer? _statusCheckTimer;
//   int _statusCheckAttempts = 0;
//   static const int _maxStatusCheckAttempts = 40; // Increased for network delays

//   bool _appWasInBackground = false;
//   int _confirmationRetries = 0;
//   static const int _maxConfirmationRetries = 5; // Increased retries

//   StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
//   bool _hasNetworkConnection = true;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);

//     // Monitor network connectivity
//     _initConnectivity();

//     _amountController.text = "1.00";
//     _upiAddressController.text = "sawan00meena@ucobank";
//     _currentTransactionRef = DateTime.now().millisecondsSinceEpoch.toString();

//     _slideController = AnimationController(
//       duration: const Duration(milliseconds: 800),
//       vsync: this,
//     );
//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 1000),
//       vsync: this,
//     );

//     _slideAnimation =
//         Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
//           CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
//         );

//     _fadeAnimation = Tween<double>(
//       begin: 0.0,
//       end: 1.0,
//     ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

//     _slideController.forward();
//     _fadeController.forward();

//     _createPendingTransaction(_currentTransactionRef!);
//   }

//   Future<void> _initConnectivity() async {
//     _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
//       List<ConnectivityResult> results,
//     ) {
//       final hasConnection = results.any(
//         (result) =>
//             result == ConnectivityResult.mobile ||
//             result == ConnectivityResult.wifi,
//       );

//       setState(() {
//         _hasNetworkConnection = hasConnection;
//       });

//       log('📶 Network connectivity changed: $hasConnection');

//       // If network restored and waiting for payment, check status
//       if (hasConnection &&
//           _isWaitingForPayment &&
//           !_paymentConfirmed &&
//           !_hasShownDialog) {
//         log('✅ Network restored - checking payment status');
//         Future.delayed(const Duration(seconds: 2), () {
//           if (mounted && !_paymentConfirmed && !_hasShownDialog) {
//             _checkPaymentStatus(isAutoCheck: false, isReturningFromUPI: true);
//           }
//         });
//       }
//     });
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);

//     log('══════════════════════════════════════════');
//     log('📱 APP LIFECYCLE: $state');
//     log('   Waiting: $_isWaitingForPayment');
//     log('   Confirmed: $_paymentConfirmed');
//     log('   Has Network: $_hasNetworkConnection');
//     log('══════════════════════════════════════════');

//     if (state == AppLifecycleState.paused ||
//         state == AppLifecycleState.hidden) {
//       _appWasInBackground = true;
//       log('✅ App in background (UPI app)');
//     } else if (state == AppLifecycleState.resumed && _appWasInBackground) {
//       log('✅ App resumed from background');
//       _appWasInBackground = false;

//       if (_isWaitingForPayment && !_paymentConfirmed && !_hasShownDialog) {
//         log('⏳ Waiting 8 seconds for network to stabilize...');

//         // Wait longer for network to stabilize
//         Future.delayed(const Duration(seconds: 8), () async {
//           if (!mounted) return;

//           // Check network status first
//           final connectivityResult = await Connectivity().checkConnectivity();
//           final hasConnection = connectivityResult.any(
//             (result) =>
//                 result == ConnectivityResult.mobile ||
//                 result == ConnectivityResult.wifi,
//           );

//           if (!hasConnection) {
//             log('⚠️ No network after resuming - will ask user');
//             if (!_hasShownDialog) {
//               _hasShownDialog = true;
//               _showNoNetworkDialog();
//             }
//             return;
//           }

//           log('✅ Network available - checking payment');
//           if (!_paymentConfirmed && !_hasShownDialog) {
//             _checkPaymentStatus(isAutoCheck: false, isReturningFromUPI: true);
//           }
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _statusCheckTimer?.cancel();
//     _connectivitySubscription?.cancel();

//     if (!_paymentConfirmed) {
//       log("⚠️ Payment screen disposed WITHOUT confirmation");
//       log("🛡️ Cart preserved");
//     }

//     _amountController.dispose();
//     _upiAddressController.dispose();
//     _slideController.dispose();
//     _fadeController.dispose();
//     _confettiController.dispose();

//     super.dispose();
//   }

//   String get _upiString {
//     return 'upi://pay?pa=${_upiAddressController.text}'
//         '&pn=ShreeNails'
//         '&am=1'
//         '&cu=INR'
//         '&tn=Order%20Payment'
//         '&tr=$_currentTransactionRef';
//   }

//   String _getUpiDeepLink(String scheme) {
//     return '$scheme?pa=${_upiAddressController.text}'
//         '&pn=ShreeNails'
//         '&am=1'
//         '&cu=INR'
//         '&tn=Order%20Payment'
//         '&tr=$_currentTransactionRef';
//   }

//   Future<void> _createPendingTransaction(String transactionRef) async {
//     final orderId = widget.orderDetails?["order_id"];
//     if (orderId == null) return;

//     try {
//       log("📝 Creating pending transaction: $transactionRef");

//       final success = await ApiService.createTransaction(
//         orderId: orderId,
//         transactionRef: transactionRef,
//         amount: double.parse("1"),
//         status: "pending",
//       );

//       if (success) {
//         log("✅ Transaction created");
//       }
//     } catch (e) {
//       log("❌ Create transaction error: $e");
//     }
//   }

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
//       ).timeout(const Duration(seconds: 15));

//       log("✅ Transaction status updated to: $status");
//     } catch (e) {
//       log("❌ Update transaction error: $e");
//       // Don't rethrow - this is not critical
//     }
//   }

//   Future<void> _confirmPaymentToBackend(String transactionRef) async {
//     final orderId = widget.orderDetails?["order_id"];
//     if (orderId == null) {
//       throw Exception("Order ID missing");
//     }

//     log("═══════════════════════════════════════════");
//     log("📝 Confirming payment (Attempt: $_confirmationRetries)");
//     log("   Order ID: $orderId");
//     log("   Transaction: $transactionRef");
//     log("═══════════════════════════════════════════");

//     try {
//       final success = await ApiService.confirmPayment(
//         orderId: orderId,
//         transactionRef: transactionRef,
//         paymentMethod: "UPI",
//       ).timeout(const Duration(seconds: 20));

//       if (!success) {
//         throw Exception("Backend returned false");
//       }

//       log("✅ Payment confirmed successfully");
//       _paymentConfirmed = true;
//       _confirmationRetries = 0;

//       if (mounted) {
//         final userId = widget.orderDetails?["user_id"];
//         if (userId != null) {
//           log("🗑️ Clearing cart for user: $userId");
//           await context.read<CartProvider>().clearCart(userId);
//           log("✅ Cart cleared");
//         }
//       }
//     } catch (e) {
//       log("❌ Confirmation error: $e");

//       _confirmationRetries++;

//       if (_confirmationRetries <= _maxConfirmationRetries) {
//         final waitTime = _confirmationRetries * 3; // 3, 6, 9, 12, 15 seconds
//         log(
//           "🔄 Retrying in $waitTime sec (${_confirmationRetries}/$_maxConfirmationRetries)",
//         );

//         await Future.delayed(Duration(seconds: waitTime));

//         if (mounted) {
//           return await _confirmPaymentToBackend(transactionRef);
//         }
//       } else {
//         log("❌ Max retries reached");
//         rethrow;
//       }
//     }
//   }

//   void _openUpiApp(String deepLink) async {
//     log('🚀 Opening UPI app: $deepLink');

//     setState(() {
//       _isProcessing = true;
//       _isWaitingForPayment = true;
//       _statusCheckAttempts = 0;
//       _hasShownDialog = false;
//       _confirmationRetries = 0;
//     });

//     try {
//       final uri = Uri.parse(deepLink);
//       final launched = await launchUrl(
//         uri,
//         mode: LaunchMode.externalApplication,
//       );

//       if (launched) {
//         log('✅ UPI app launched');

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Row(
//                 children: [
//                   const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation(Colors.white),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       'Complete payment in UPI app...',
//                       style: GoogleFonts.poppins(fontSize: 13),
//                     ),
//                   ),
//                 ],
//               ),
//               backgroundColor: Colors.deepPurple,
//               duration: const Duration(seconds: 3),
//             ),
//           );
//         }

//         _startAutoStatusChecking();
//       } else {
//         throw Exception('Could not launch UPI app');
//       }
//     } catch (e) {
//       log('❌ Error opening UPI: $e');
//       _isWaitingForPayment = false;
//       if (mounted) {
//         setState(() => _isProcessing = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'App not installed. Please scan QR code.',
//               style: GoogleFonts.poppins(fontSize: 13),
//             ),
//             backgroundColor: Colors.orange,
//           ),
//         );
//       }
//     }
//   }

//   void _startAutoStatusChecking() {
//     log('🔄 Starting auto status check (max: $_maxStatusCheckAttempts)');

//     _statusCheckTimer?.cancel();

//     _statusCheckTimer = Timer.periodic(const Duration(seconds: 5), (
//       timer,
//     ) async {
//       _statusCheckAttempts++;
//       log('🔍 Status check: $_statusCheckAttempts/$_maxStatusCheckAttempts');

//       if (_statusCheckAttempts > _maxStatusCheckAttempts) {
//         timer.cancel();
//         log('⏱️ Max attempts reached');
//         if (mounted && _isWaitingForPayment && !_hasShownDialog) {
//           setState(() {
//             _isProcessing = false;
//             _isWaitingForPayment = false;
//           });
//           _showPaymentTimeoutDialog();
//         }
//         return;
//       }

//       await _checkPaymentStatus(isAutoCheck: true);
//     });
//   }

//   Future<void> _checkPaymentStatus({
//     bool isAutoCheck = false,
//     bool isReturningFromUPI = false,
//   }) async {
//     if (_currentTransactionRef == null || _hasShownDialog) return;

//     log('🔍 Checking payment status');

//     try {
//       final status =
//           await ApiService.getTransactionStatus(
//             _currentTransactionRef!,
//           ).timeout(
//             const Duration(seconds: 15),
//             onTimeout: () {
//               log('⏱️ Status check timeout');
//               return 'pending';
//             },
//           );

//       log('📊 Status: "$status"');

//       if (!mounted) return;

//       if (status == 'success') {
//         log('✅ PAYMENT SUCCESS!');

//         _statusCheckTimer?.cancel();
//         _hasShownDialog = true;

//         setState(() {
//           _isProcessing = false;
//           _isWaitingForPayment = false;
//         });

//         try {
//           await _updateTransactionStatus(
//             _currentTransactionRef!,
//             'success',
//             'Payment completed',
//           );
//         } catch (e) {
//           log('⚠️ Update transaction failed: $e');
//         }

//         try {
//           await _confirmPaymentToBackend(_currentTransactionRef!);
//           _confettiController.play();
//           _showSuccessDialog();
//         } catch (e) {
//           log('❌ Confirmation failed: $e');
//           _showErrorDialog(
//             'Payment Successful!\n\n'
//             'However, we could not confirm it in the system.\n\n'
//             'Your payment was received.\n\n'
//             'Transaction ID:\n$_currentTransactionRef\n\n'
//             'Please contact support. Do NOT retry payment.',
//           );
//         }
//       } else if (status == 'failed') {
//         log('❌ PAYMENT FAILED');

//         _statusCheckTimer?.cancel();
//         _hasShownDialog = true;

//         setState(() {
//           _isProcessing = false;
//           _isWaitingForPayment = false;
//         });

//         try {
//           await _updateTransactionStatus(
//             _currentTransactionRef!,
//             'failed',
//             'Payment failed',
//           );
//         } catch (e) {
//           log('⚠️ Update failed: $e');
//         }

//         _showFailureDialog();
//       } else if (status == 'pending') {
//         log('⏳ Still pending...');

//         if (isReturningFromUPI && !isAutoCheck && !_hasShownDialog) {
//           _statusCheckTimer?.cancel();
//           _hasShownDialog = true;

//           setState(() {
//             _isProcessing = false;
//             _isWaitingForPayment = false;
//           });

//           _showPaymentStatusDialog();
//         }
//       }
//     } catch (e) {
//       log('❌ Status check error: $e');

//       // If network error and returning from UPI, show dialog
//       if (isReturningFromUPI && !isAutoCheck && !_hasShownDialog) {
//         _hasShownDialog = true;
//         _showNoNetworkDialog();
//       }
//     }
//   }

//   Future<void> _manuallyConfirmPayment() async {
//     log('🔧 MANUAL CONFIRMATION');

//     setState(() => _isProcessing = true);

//     try {
//       // First update to success
//       await _updateTransactionStatus(
//         _currentTransactionRef!,
//         'success',
//         'Manually confirmed by user',
//       );

//       // Then confirm payment
//       await _confirmPaymentToBackend(_currentTransactionRef!);

//       if (mounted) {
//         setState(() => _isProcessing = false);
//         _confettiController.play();
//         _showSuccessDialog();
//       }
//     } catch (e) {
//       log('❌ Manual confirmation failed: $e');
//       if (mounted) {
//         setState(() => _isProcessing = false);

//         _showErrorDialog(
//           'Failed to confirm payment.\n\n'
//           'Error: ${e.toString()}\n\n'
//           'If you completed payment, please contact support:\n\n'
//           'Transaction ID: $_currentTransactionRef',
//         );
//       }
//     }
//   }

//   void _showNoNetworkDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Row(
//           children: [
//             const Icon(Icons.wifi_off, color: Colors.orange, size: 28),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 'No Network',
//                 style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//               ),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Network connection is not available.',
//               style: GoogleFonts.poppins(fontSize: 14),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'Please:\n'
//               '1. Check your WiFi/Mobile data\n'
//               '2. Make sure you completed the payment\n'
//               '3. Click "I Paid" to confirm',
//               style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               setState(() {
//                 _hasShownDialog = false;
//                 _isProcessing = true;
//               });

//               // Wait and try again
//               Future.delayed(const Duration(seconds: 5), () {
//                 if (mounted) {
//                   _checkPaymentStatus(isAutoCheck: false);
//                 }
//               });
//             },
//             child: Text('Wait & Retry', style: GoogleFonts.poppins()),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               _manuallyConfirmPayment();
//             },
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//             child: Text(
//               'I Paid - Confirm',
//               style: GoogleFonts.poppins(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showPaymentStatusDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(Icons.payment, size: 48, color: Colors.blue),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 'Payment Status',
//                 style: GoogleFonts.poppins(
//                   fontSize: 20,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'Did you complete the payment in your UPI app?',
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _isProcessing
//                       ? null
//                       : () {
//                           Navigator.of(context).pop();
//                           _manuallyConfirmPayment();
//                         },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: _isProcessing
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor: AlwaysStoppedAnimation(Colors.white),
//                           ),
//                         )
//                       : Text(
//                           'Yes, Payment Done',
//                           style: GoogleFonts.poppins(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               SizedBox(
//                 width: double.infinity,
//                 child: OutlinedButton(
//                   onPressed: _isProcessing
//                       ? null
//                       : () async {
//                           Navigator.of(context).pop();

//                           try {
//                             await _updateTransactionStatus(
//                               _currentTransactionRef!,
//                               'failed',
//                               'User cancelled',
//                             );
//                           } catch (e) {
//                             log('Failed to update: $e');
//                           }

//                           _showFailureDialog();
//                         },
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: Colors.red,
//                     side: const BorderSide(color: Colors.red, width: 2),
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: Text(
//                     'No, Cancel Payment',
//                     style: GoogleFonts.poppins(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextButton(
//                 onPressed: _isProcessing
//                     ? null
//                     : () {
//                         Navigator.of(context).pop();
//                         setState(() {
//                           _isProcessing = true;
//                           _hasShownDialog = false;
//                         });

//                         Future.delayed(const Duration(seconds: 5), () {
//                           if (mounted) {
//                             _checkPaymentStatus(isAutoCheck: false);
//                           }
//                         });
//                       },
//                 child: Text(
//                   'Check Again (Wait 5s)',
//                   style: GoogleFonts.poppins(fontSize: 14),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showPaymentTimeoutDialog() {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.orange.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: const Icon(
//                   Icons.access_time,
//                   size: 48,
//                   color: Colors.orange,
//                 ),
//               ),
//               const SizedBox(height: 20),
//               Text(
//                 'Payment Verification Timeout',
//                 style: GoogleFonts.poppins(
//                   fontSize: 18,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 12),
//               Text(
//                 'We couldn\'t verify your payment automatically.\n\n'
//                 'Did you complete the payment?',
//                 style: GoogleFonts.poppins(
//                   fontSize: 14,
//                   color: Colors.grey[600],
//                 ),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 24),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     Navigator.of(context).pop();
//                     _manuallyConfirmPayment();
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green,
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                   ),
//                   child: Text(
//                     'I Paid - Confirm',
//                     style: GoogleFonts.poppins(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.white,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               SizedBox(
//                 width: double.infinity,
//                 child: OutlinedButton(
//                   onPressed: () async {
//                     Navigator.of(context).pop();

//                     try {
//                       await _updateTransactionStatus(
//                         _currentTransactionRef!,
//                         'failed',
//                         'User confirmed not paid',
//                       );
//                     } catch (e) {
//                       log('Failed to update: $e');
//                     }

//                     _showFailureDialog();
//                   },
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: Colors.red,
//                     side: const BorderSide(color: Colors.red, width: 2),
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                   ),
//                   child: Text(
//                     'Not Paid',
//                     style: GoogleFonts.poppins(
//                       fontSize: 15,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         title: Row(
//           children: [
//             const Icon(Icons.error, color: Colors.orange),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Text(
//                 'Important',
//                 style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//               ),
//             ),
//           ],
//         ),
//         content: SingleChildScrollView(
//           child: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               Navigator.of(context).pop();
//             },
//             child: Text('OK', style: GoogleFonts.poppins()),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async {
//         if (_isWaitingForPayment) {
//           final shouldPop = await showDialog<bool>(
//             context: context,
//             builder: (context) => AlertDialog(
//               title: Text(
//                 'Payment in Progress',
//                 style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//               ),
//               content: Text(
//                 'Are you sure you want to go back?',
//                 style: GoogleFonts.poppins(fontSize: 14),
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   child: Text('Stay', style: GoogleFonts.poppins()),
//                 ),
//                 TextButton(
//                   onPressed: () {
//                     _statusCheckTimer?.cancel();
//                     Navigator.pop(context, true);
//                   },
//                   child: Text(
//                     'Go Back',
//                     style: GoogleFonts.poppins(color: Colors.red),
//                   ),
//                 ),
//               ],
//             ),
//           );

//           return shouldPop ?? false;
//         }

//         return true;
//       },
//       child: Scaffold(
//         backgroundColor: const Color(0xffF8F9FB),
//         appBar: AppBar(
//           title: Text(
//             'Secure Payment',
//             style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
//           ),
//           backgroundColor: Colors.deepPurple,
//           foregroundColor: Colors.white,
//           centerTitle: true,
//         ),
//         body: SafeArea(
//           child: Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(20),
//               child: Container(
//                 constraints: const BoxConstraints(maxWidth: 500),
//                 child: FadeTransition(
//                   opacity: _fadeAnimation,
//                   child: SlideTransition(
//                     position: _slideAnimation,
//                     child: Column(
//                       children: [
//                         if (!_hasNetworkConnection) ...[
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.orange[50],
//                               borderRadius: BorderRadius.circular(12),
//                               border: Border.all(color: Colors.orange),
//                             ),
//                             child: Row(
//                               children: [
//                                 const Icon(
//                                   Icons.wifi_off,
//                                   color: Colors.orange,
//                                 ),
//                                 const SizedBox(width: 12),
//                                 Expanded(
//                                   child: Text(
//                                     'No network connection',
//                                     style: GoogleFonts.poppins(
//                                       fontSize: 13,
//                                       color: Colors.orange[900],
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                         ],

//                         _buildAmountCard(),
//                         const SizedBox(height: 24),
//                         _buildPaymentCard(),
//                         const SizedBox(height: 24),
//                         _buildTransactionIdCard(),
//                         const SizedBox(height: 24),
//                         _buildInstructionsCard(),

//                         if (_isWaitingForPayment) ...[
//                           const SizedBox(height: 24),
//                           _buildWaitingCard(),
//                         ],
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   // All other build methods remain the same as before...
//   // [Copy _buildAmountCard, _buildPaymentCard, etc. from previous code]

//   Widget _buildAmountCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Colors.deepPurple, Color(0xff8B5CF6)],
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

//   Widget _buildPaymentCard() {
//     return Container(
//       padding: const EdgeInsets.all(24),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             blurRadius: 20,
//             offset: const Offset(0, 10),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Text(
//             'Pay Using UPI App',
//             style: GoogleFonts.poppins(
//               fontSize: 20,
//               fontWeight: FontWeight.w600,
//               color: Colors.deepPurple,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Click on your preferred app',
//             style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
//           ),
//           const SizedBox(height: 24),

//           _buildUpiAppsGrid(),

//           const SizedBox(height: 24),
//           const Divider(),
//           const SizedBox(height: 16),

//           Text(
//             'Or Scan QR Code',
//             style: GoogleFonts.poppins(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: Colors.deepPurple,
//             ),
//           ),
//           const SizedBox(height: 12),

//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: Colors.deepPurple, width: 2),
//             ),
//             child: QrImageView(
//               data: _upiString,
//               version: QrVersions.auto,
//               size: 150,
//               backgroundColor: Colors.white,
//             ),
//           ),

//           const SizedBox(height: 16),

//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.grey[100],
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Or pay manually to UPI ID:',
//                   style: GoogleFonts.poppins(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Text(
//                         _upiAddressController.text,
//                         style: GoogleFonts.robotoMono(
//                           fontSize: 14,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.copy, size: 20),
//                       onPressed: () {
//                         Clipboard.setData(
//                           ClipboardData(text: _upiAddressController.text),
//                         );
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(
//                             content: Text(
//                               'UPI ID Copied!',
//                               style: GoogleFonts.poppins(fontSize: 13),
//                             ),
//                             duration: const Duration(seconds: 2),
//                           ),
//                         );
//                       },
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUpiAppsGrid() {
//     final upiApps = [
//       {
//         'name': 'Google Pay',
//         'scheme': _getUpiDeepLink('tez://upi/pay'),
//         'color': const Color(0xff4285F4),
//         'icon': Icons.payment,
//       },
//       {
//         'name': 'PhonePe',
//         'scheme': _getUpiDeepLink('phonepe://pay'),
//         'color': const Color(0xff5F259F),
//         'icon': Icons.phone_android,
//       },
//       {
//         'name': 'Paytm',
//         'scheme': _getUpiDeepLink('paytmmp://pay'),
//         'color': const Color(0xff00BAF2),
//         'icon': Icons.account_balance_wallet,
//       },
//       {
//         'name': 'BHIM',
//         'scheme': _getUpiDeepLink('upi://pay'),
//         'color': const Color(0xffED1C24),
//         'icon': Icons.account_balance,
//       },
//     ];

//     return GridView.builder(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 2,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//         childAspectRatio: 1.2,
//       ),
//       itemCount: upiApps.length,
//       itemBuilder: (context, index) {
//         final app = upiApps[index];
//         return _buildUpiAppCard(
//           name: app['name'] as String,
//           deepLink: app['scheme'] as String,
//           color: app['color'] as Color,
//           icon: app['icon'] as IconData,
//         );
//       },
//     );
//   }

//   Widget _buildUpiAppCard({
//     required String name,
//     required String deepLink,
//     required Color color,
//     required IconData icon,
//   }) {
//     return InkWell(
//       onTap: _isProcessing ? null : () => _openUpiApp(deepLink),
//       borderRadius: BorderRadius.circular(16),
//       child: Container(
//         decoration: BoxDecoration(
//           color: color.withOpacity(0.1),
//           borderRadius: BorderRadius.circular(16),
//           border: Border.all(color: color.withOpacity(0.3), width: 2),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//               child: Icon(icon, size: 32, color: Colors.white),
//             ),
//             const SizedBox(height: 12),
//             Text(
//               name,
//               style: GoogleFonts.poppins(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: color,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 4),
//             Text(
//               'Tap to Pay',
//               style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTransactionIdCard() {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: Colors.purple[50],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.purple[200]!),
//       ),
//       child: Column(
//         children: [
//           Text(
//             'Transaction ID',
//             style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             _currentTransactionRef ?? '',
//             style: GoogleFonts.robotoMono(
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//               color: Colors.deepPurple,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInstructionsCard() {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.blue[50],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.blue[200]!),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Icon(Icons.info, color: Colors.blue, size: 20),
//               const SizedBox(width: 8),
//               Text(
//                 'How to Pay:',
//                 style: GoogleFonts.poppins(
//                   fontWeight: FontWeight.w600,
//                   color: Colors.blue[900],
//                   fontSize: 15,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           _instructionStep('1', 'Click on your UPI app'),
//           _instructionStep('2', 'Complete payment'),
//           _instructionStep('3', 'Return to this screen'),
//           _instructionStep('4', 'We\'ll verify automatically'),
//         ],
//       ),
//     );
//   }

//   Widget _buildWaitingCard() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.deepPurple[50],
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.deepPurple[200]!),
//       ),
//       child: Column(
//         children: [
//           const CircularProgressIndicator(),
//           const SizedBox(height: 16),
//           Text(
//             'Waiting for payment...',
//             style: GoogleFonts.poppins(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: Colors.deepPurple,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Complete payment in UPI app.\nWe\'ll verify automatically.',
//             style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 12),
//           Text(
//             'Check: $_statusCheckAttempts/$_maxStatusCheckAttempts',
//             style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _instructionStep(String num, String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             '$num.',
//             style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(width: 8),
//           Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 13))),
//         ],
//       ),
//     );
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
//                     'Payment Successful! 🎉',
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
//                 'Payment was not completed. Please try again.',
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
//                       onPressed: () {
//                         Navigator.of(context).pop();
//                         Navigator.of(context).pop();
//                       },
//                       style: OutlinedButton.styleFrom(
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         side: BorderSide(color: Colors.grey.shade300),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: Text(
//                         'Go Back',
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

//                         setState(() {
//                           _currentTransactionRef = DateTime.now()
//                               .millisecondsSinceEpoch
//                               .toString();
//                           _isProcessing = false;
//                           _isWaitingForPayment = false;
//                           _statusCheckAttempts = 0;
//                           _hasShownDialog = false;
//                           _confirmationRetries = 0;
//                         });
//                         _createPendingTransaction(_currentTransactionRef!);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.deepPurple,
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                       ),
//                       child: Text(
//                         'Retry Payment',
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
// }

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:demo/data/services/api_service.dart';
import 'dart:js' as js; // ✅ Import dart:js for web

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final double totalAmount;
  final Map<String, dynamic>? orderDetails;

  const PaymentScreen({
    super.key,
    required this.orderId,
    this.totalAmount = 0,
    this.orderDetails,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  Razorpay? _razorpay;
  String? _txnRef;
  String? _razorpayOrderId;
  String? _razorpayKey;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _razorpay = Razorpay();
      _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    } else {
      // ✅ Setup web message listener
      _setupWebMessageListener();
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    super.dispose();
  }

  // ✅ NEW: Setup message listener for web
  void _setupWebMessageListener() {
    if (kIsWeb) {
      js.context['handleRazorpayResponse'] = (String type, String data) {
        debugPrint("🌐 Received message from Razorpay: $type");

        if (type == 'success') {
          final Map<String, dynamic> response = jsonDecode(data);
          _handleWebPaymentSuccess(response);
        } else if (type == 'error') {
          final Map<String, dynamic> error = jsonDecode(data);
          _handleWebPaymentError(error);
        }
      };
    }
  }

  // ================= CREATE RAZORPAY ORDER =================
  Future<Map<String, dynamic>?> _createRazorpayOrder() async {
    try {
      _txnRef =
          "TXN-${widget.orderId}-${DateTime.now().millisecondsSinceEpoch}";

      debugPrint("📤 Creating Razorpay order...");
      debugPrint("📤 Order ID: ${widget.orderId}");
      debugPrint("📤 Transaction Ref: $_txnRef");
      debugPrint("📤 Amount: ${1}");

      final data = await ApiService.createRazorpayOrder(
        orderId: int.parse(widget.orderId),
        transactionRef: _txnRef!,
        amount: 1,
      );

      if (data != null && data['success'] == true) {
        _razorpayOrderId = data['razorpay_order_id'];
        _razorpayKey = data['razorpay_key'];

        debugPrint("✅ Razorpay order created!");
        debugPrint("✅ Order ID: $_razorpayOrderId");
        debugPrint("✅ Key: $_razorpayKey");

        return data;
      } else {
        throw Exception(data?['error'] ?? 'Failed to create Razorpay order');
      }
    } catch (e) {
      debugPrint("❌ Create Razorpay Order Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return null;
    }
  }

  // ================= UPDATE PAYMENT STATUS =================
  Future<void> _updatePaymentStatus(String status, String? paymentId) async {
    try {
      debugPrint("📤 Updating payment status: $status");

      await ApiService.updateRazorpayPayment(
        transactionRef: _txnRef!,
        status: status,
        razorpayPaymentId: paymentId,
        orderId: int.parse(widget.orderId),
      );

      debugPrint("✅ Payment status updated");
    } catch (e) {
      debugPrint("❌ Update Status Error: $e");
    }
  }

  // ================= PAY NOW =================
  Future<void> payNow() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final razorpayData = await _createRazorpayOrder();

      if (razorpayData == null) {
        setState(() => _isLoading = false);
        return;
      }

      if (kIsWeb) {
        _launchWebPayment();
      } else {
        _launchMobilePayment();
      }
    } catch (e) {
      debugPrint("❌ Pay Now Error: $e");
      _showErrorMessage("Payment initialization failed: $e");
      setState(() => _isLoading = false);
    }
  }

  // ✅ FIXED: Web payment implementation
  void _launchWebPayment() {
    if (_razorpayKey == null || _razorpayOrderId == null) {
      _showErrorMessage("Payment configuration error");
      setState(() => _isLoading = false);
      return;
    }

    try {
      debugPrint("🚀 Launching Razorpay Web Checkout...");

      // ✅ Create options object
      final options = js.JsObject.jsify({
        'key': _razorpayKey,
        'amount': (1 * 100).toInt(),
        'currency': 'INR',
        'name': 'Shree Nails',
        'description': 'Order #${widget.orderId}',
        'order_id': _razorpayOrderId,
        'prefill': {
          'contact': '9999999999',
          'email': 'customer@shreenails.com',
        },
        'notes': {'order_id': widget.orderId, 'transaction_ref': _txnRef},
        'theme': {'color': '#F37254'},
        'handler': js.allowInterop((response) {
          debugPrint("✅ Payment Success on Web");
          js.context.callMethod('handleRazorpayResponse', [
            'success',
            jsonEncode({
              'razorpay_payment_id': response['razorpay_payment_id'],
              'razorpay_order_id': response['razorpay_order_id'],
              'razorpay_signature': response['razorpay_signature'],
            }),
          ]);
        }),
        'modal': js.JsObject.jsify({
          'ondismiss': js.allowInterop(() {
            debugPrint("❌ Payment cancelled by user");
            setState(() => _isLoading = false);
          }),
        }),
      });

      // ✅ Add error handler
      final razorpay = js.JsObject(js.context['Razorpay'], [options]);

      razorpay.callMethod('on', [
        'payment.failed',
        js.allowInterop((response) {
          debugPrint("❌ Payment Failed on Web");
          js.context.callMethod('handleRazorpayResponse', [
            'error',
            jsonEncode({
              'code': response['error']['code'],
              'description': response['error']['description'],
            }),
          ]);
        }),
      ]);

      // ✅ Open Razorpay checkout
      razorpay.callMethod('open');
    } catch (e) {
      debugPrint("❌ Web Payment Error: $e");
      _showErrorMessage("Failed to open payment gateway: $e");
      setState(() => _isLoading = false);
    }
  }

  // ================= WEB SUCCESS HANDLER =================
  void _handleWebPaymentSuccess(Map<String, dynamic> response) async {
    debugPrint("✅ Web Payment Success!");
    debugPrint("✅ Payment ID: ${response['razorpay_payment_id']}");
    debugPrint("✅ Order ID: ${response['razorpay_order_id']}");

    await _updatePaymentStatus('captured', response['razorpay_payment_id']);
    _showSuccessMessage();
  }

  // ================= WEB ERROR HANDLER =================
  void _handleWebPaymentError(Map<String, dynamic> error) async {
    debugPrint("❌ Web Payment Error: ${error['code']}");
    debugPrint("❌ Message: ${error['description']}");

    await _updatePaymentStatus('failed', null);
    _showErrorMessage(error['description'] ?? 'Payment failed');
  }

  // ================= MOBILE PAYMENT =================
  void _launchMobilePayment() {
    if (_razorpayKey == null || _razorpayOrderId == null) {
      _showErrorMessage("Payment configuration error");
      setState(() => _isLoading = false);
      return;
    }

    final options = {
      'key': _razorpayKey,
      'amount': (1 * 100).toInt(),
      'currency': 'INR',
      'name': 'Shree Nails',
      'description': 'Order #${widget.orderId}',
      'order_id': _razorpayOrderId,
      'prefill': {'contact': '9999999999', 'email': 'customer@shreenails.com'},
      'notes': {'order_id': widget.orderId, 'transaction_ref': _txnRef},
      'theme': {'color': '#F37254'},
    };

    try {
      debugPrint("🚀 Launching Razorpay...");
      debugPrint("Options: $options");
      _razorpay!.open(options);
    } catch (e) {
      debugPrint("❌ Razorpay Error: $e");
      _showErrorMessage("Failed to open payment gateway: $e");
      setState(() => _isLoading = false);
    }
  }

  // ================= MOBILE SUCCESS HANDLER =================
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    debugPrint("✅ Payment Success!");
    debugPrint("✅ Payment ID: ${response.paymentId}");
    debugPrint("✅ Order ID: ${response.orderId}");
    debugPrint("✅ Signature: ${response.signature}");

    await _updatePaymentStatus('captured', response.paymentId);
    _showSuccessMessage();
  }

  // ================= MOBILE ERROR HANDLER =================
  void _handlePaymentError(PaymentFailureResponse response) async {
    debugPrint("❌ Payment Error: ${response.code}");
    debugPrint("❌ Message: ${response.message}");

    await _updatePaymentStatus('failed', null);
    _showErrorMessage(response.message ?? 'Payment failed');
  }

  // ================= UI HELPERS =================
  void _showSuccessMessage() {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Payment Successful!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, true);
      }
    });
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("❌ $message"),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Secure Payment"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Order Details",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow("Order ID", widget.orderId),
                      const Divider(height: 24),
                      _buildDetailRow(
                        "Total Amount",
                        "₹${1.toStringAsFixed(2)}",
                        isAmount: true,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : payNow,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFFF37254),
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Pay ₹${1.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    "100% Secure • Powered by Razorpay",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              if (kDebugMode)
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Debug Info:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Order: ${widget.orderId}",
                        style: TextStyle(fontSize: 11, color: Colors.blue[800]),
                      ),
                      Text(
                        "Amount: ₹${1}",
                        style: TextStyle(fontSize: 11, color: Colors.blue[800]),
                      ),
                      if (_txnRef != null)
                        Text(
                          "Txn: $_txnRef",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue[800],
                          ),
                        ),
                      Text(
                        "Platform: ${kIsWeb ? 'WEB' : 'MOBILE'}",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAmount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
              fontSize: isAmount ? 20 : 14,
              color: isAmount ? const Color(0xFFF37254) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
