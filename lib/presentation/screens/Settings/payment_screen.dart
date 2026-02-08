import 'dart:developer';
import 'package:demo/data/services/api_service.dart';
import 'package:demo/data/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:confetti/confetti.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;
  final Map<String, dynamic>? orderDetails;

  const PaymentScreen({super.key, this.totalAmount = 0, this.orderDetails});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with TickerProviderStateMixin {
  final _upiAddressController = TextEditingController();
  final _amountController = TextEditingController();

  String? _currentTransactionRef;
  bool _isProcessing = false;
  bool _isWaitingForPayment = false;

  // ✅ CRITICAL: Track if payment was actually confirmed
  bool _paymentConfirmed = false;

  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  Timer? _statusCheckTimer;
  int _statusCheckAttempts = 0;
  static const int _maxStatusCheckAttempts = 20;

  @override
  void initState() {
    super.initState();

    _amountController.text = "1.00";
    _upiAddressController.text = "sawan00meena@ucobank";
    _currentTransactionRef = DateTime.now().millisecondsSinceEpoch.toString();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _slideController.forward();
    _fadeController.forward();

    _createPendingTransaction(_currentTransactionRef!);
  }

  @override
  void dispose() {
    // ✅ CRITICAL: Cancel status checking timer
    _statusCheckTimer?.cancel();

    // ✅ SAFETY CHECK: Log if payment wasn't confirmed
    if (!_paymentConfirmed) {
      log("⚠️ Payment screen disposed WITHOUT payment confirmation");
      log("🛡️ Cart will be preserved (NOT cleared)");
    } else {
      log("✅ Payment screen disposed AFTER successful payment confirmation");
    }

    _amountController.dispose();
    _upiAddressController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();

    super.dispose();
  }

  String get _upiString {
    return 'upi://pay?pa=${_upiAddressController.text}'
        '&pn=ShreeNails'
        '&am=1'
        '&cu=INR'
        '&tn=Order%20Payment'
        '&tr=$_currentTransactionRef';
  }

  String _getUpiDeepLink(String scheme) {
    return '$scheme?pa=${_upiAddressController.text}'
        '&pn=ShreeNails'
        '&am=1'
        '&cu=INR'
        '&tn=Order%20Payment'
        '&tr=$_currentTransactionRef';
  }

  Future<void> _createPendingTransaction(String transactionRef) async {
    final orderId = widget.orderDetails?["order_id"];

    if (orderId == null) {
      log("⚠️ Order ID missing");
      return;
    }

    try {
      final success = await ApiService.createTransaction(
        orderId: orderId,
        transactionRef: transactionRef,
        amount: double.parse("1"),
        status: "pending",
      );

      if (success) {
        log("✅ Pending transaction created: $transactionRef");
      } else {
        log("❌ Transaction API failed");
      }
    } catch (e) {
      log("❌ Failed to create pending transaction: $e");
    }
  }

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
      log("✅ Transaction status updated: $transactionRef -> $status");
    } catch (e) {
      log("❌ Failed to update transaction: $e");
    }
  }

  // ✅ CONFIRM PAYMENT TO BACKEND & CLEAR CART
  // 🔥 THIS IS THE *ONLY* PLACE WHERE CART SHOULD BE CLEARED!
  Future<void> _confirmPaymentToBackend(String transactionRef) async {
    final orderId = widget.orderDetails?["order_id"];

    if (orderId == null) {
      throw Exception("Order ID missing");
    }

    log("📝 Confirming payment to backend...");

    final success = await ApiService.confirmPayment(
      orderId: orderId,
      transactionRef: transactionRef,
      paymentMethod: "UPI",
    );

    if (!success) {
      throw Exception("Backend payment confirmation failed");
    }

    log("✅ Backend payment confirmed successfully");

    // ✅ SET FLAG: Payment is now confirmed
    _paymentConfirmed = true;
    log("🎯 _paymentConfirmed set to TRUE");

    // 🔥 ONLY CLEAR CART AFTER:
    // 1. Payment status is 'success' from backend
    // 2. Backend has confirmed the payment
    // 3. Widget is still mounted
    // 4. We have user ID

    try {
      if (mounted) {
        final userId = widget.orderDetails?["user_id"];
        if (userId != null) {
          log("═══════════════════════════════════════════");
          log("🗑️ PAYMENT CONFIRMED - Now clearing cart");
          log("User ID: $userId");
          log("Transaction: $transactionRef");
          log("═══════════════════════════════════════════");

          // ✅ THIS IS THE ONLY PLACE WHERE CART SHOULD BE CLEARED!
          await context.read<CartProvider>().clearCart(userId);

          log("✅ Cart cleared successfully after confirmed payment");
        } else {
          log("⚠️ User ID not found, cannot clear cart");
        }
      }
    } catch (e) {
      log("❌ Error clearing cart: $e");
      // Don't throw - payment was successful even if cart clear failed
    }
  }

  void _openUpiApp(String deepLink) async {
    log('🚀 Opening UPI app with deep link: $deepLink');

    setState(() {
      _isProcessing = true;
      _isWaitingForPayment = true;
      _statusCheckAttempts = 0;
    });

    try {
      final uri = Uri.parse(deepLink);

      try {
        log('📱 Attempting to launch UPI app...');
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (launched) {
          log('✅ UPI app launched successfully');

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Complete payment in UPI app...',
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.deepPurple,
                duration: const Duration(seconds: 3),
              ),
            );
          }

          _startAutoStatusChecking();
        } else {
          throw Exception('Could not launch UPI app');
        }
      } catch (e) {
        log('❌ Could not launch URL: $e');
        _isWaitingForPayment = false;
        if (mounted) {
          setState(() => _isProcessing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'App not installed. Please scan QR code instead.',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      log('❌ Error opening UPI app: $e');
      _isWaitingForPayment = false;
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startAutoStatusChecking() {
    log('🔄 Starting auto status checking...');

    _statusCheckTimer?.cancel();

    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (
      timer,
    ) async {
      _statusCheckAttempts++;
      log(
        '🔍 Status check attempt: $_statusCheckAttempts/$_maxStatusCheckAttempts',
      );

      if (_statusCheckAttempts > _maxStatusCheckAttempts) {
        timer.cancel();
        log('⏱️ Max attempts reached - stopping auto check');
        if (mounted && _isWaitingForPayment) {
          setState(() {
            _isProcessing = false;
            _isWaitingForPayment = false;
          });
          _showPaymentTimeoutDialog();
        }
        return;
      }

      await _checkPaymentStatus(isAutoCheck: true);
    });
  }

  Future<void> _checkPaymentStatus({bool isAutoCheck = false}) async {
    if (_currentTransactionRef == null) return;

    log(
      '🔍 Checking payment status for: $_currentTransactionRef (auto: $isAutoCheck)',
    );

    try {
      final status = await ApiService.getTransactionStatus(
        _currentTransactionRef!,
      );

      log('📊 Payment status received: $status');

      if (!mounted) return;

      if (status == 'success') {
        log('✅ Payment successful!');
        _statusCheckTimer?.cancel();

        setState(() {
          _isProcessing = false;
          _isWaitingForPayment = false;
        });

        // ✅ ONLY confirm payment (and clear cart) if status is 'success'
        try {
          await _confirmPaymentToBackend(_currentTransactionRef!);
          _confettiController.play();
          _showSuccessDialog();
        } catch (e) {
          log('❌ Payment confirmation failed: $e');
          // ❌ DO NOT CLEAR CART ON CONFIRMATION ERROR
          _showFailureDialog();
        }
      } else if (status == 'failed') {
        log('❌ Payment failed');
        _statusCheckTimer?.cancel();

        setState(() {
          _isProcessing = false;
          _isWaitingForPayment = false;
        });

        await _updateTransactionStatus(
          _currentTransactionRef!,
          'failed',
          'Payment failed',
        );

        // ❌ DO NOT CLEAR CART ON FAILURE!
        _showFailureDialog();
      } else if (status == 'pending') {
        log('⏳ Payment still pending...');
        // ❌ DO NOT CLEAR CART WHILE PENDING!
        if (!isAutoCheck) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment is still pending. Please wait...',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      log('❌ Status check error: $e');
      // ❌ DO NOT CLEAR CART ON ERROR!
      if (!isAutoCheck && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPaymentTimeoutDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time,
                  size: 48,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Payment Status Unknown',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We couldn\'t verify your payment. Did you complete it?',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();

                        // ✅ Mark as failed but DON'T clear cart
                        await _updateTransactionStatus(
                          _currentTransactionRef!,
                          'failed',
                          'User confirmed payment not completed',
                        );

                        // ❌ DO NOT CLEAR CART HERE!
                        _showFailureDialog();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Not Paid',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
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
                        setState(() => _isProcessing = true);
                        // ❌ DO NOT CLEAR CART - just check status again
                        _checkPaymentStatus(isAutoCheck: false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Check Again',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // ✅ INTERCEPT BACK BUTTON
      onWillPop: () async {
        if (_isWaitingForPayment) {
          // Show warning if payment is in progress
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Payment in Progress',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: Text(
                'Are you sure you want to go back? Your payment verification is still in progress.',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Stay', style: GoogleFonts.poppins()),
                ),
                TextButton(
                  onPressed: () {
                    // ✅ Cancel status checking
                    _statusCheckTimer?.cancel();
                    Navigator.pop(context, true);
                  },
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.poppins(color: Colors.red),
                  ),
                ),
              ],
            ),
          );

          return shouldPop ?? false;
        }

        // ✅ Safe to go back if not waiting for payment
        log("⬅️ User navigating back from payment screen");
        log("🛡️ Payment not confirmed - cart will be preserved");
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xffF8F9FB),
        appBar: AppBar(
          title: Text(
            'Secure Payment',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        _buildAmountCard(),
                        const SizedBox(height: 24),
                        _buildPaymentCard(),
                        const SizedBox(height: 24),
                        _buildTransactionIdCard(),
                        const SizedBox(height: 24),
                        _buildInstructionsCard(),

                        if (_isWaitingForPayment) ...[
                          const SizedBox(height: 24),
                          _buildWaitingCard(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ... (rest of the build methods remain the same - _buildAmountCard, _buildPaymentCard, etc.)

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple, Color(0xff8B5CF6)],
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

  // ... (include all other widget methods from your original file)
  // _buildPaymentCard, _buildUpiAppsGrid, _buildUpiAppCard,
  // _buildTransactionIdCard, _buildInstructionsCard, _buildWaitingCard,
  // _instructionStep, _showSuccessDialog, _showFailureDialog

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
                'Payment was not completed. Please try again.',
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
                      onPressed: () {
                        // ❌ DO NOT CLEAR CART!
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pop(); // Go back to cart/address
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Go Back',
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

                        // ❌ DO NOT CLEAR CART!
                        // Just reset for retry
                        setState(() {
                          _currentTransactionRef = DateTime.now()
                              .millisecondsSinceEpoch
                              .toString();
                          _isProcessing = false;
                          _isWaitingForPayment = false;
                          _statusCheckAttempts = 0;
                        });
                        _createPendingTransaction(_currentTransactionRef!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Retry Payment',
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

  Widget _buildPaymentCard() {
    return Container(
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
            'Pay Using UPI App',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Click on your preferred app',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          _buildUpiAppsGrid(),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),

          Text(
            'Or Scan QR Code',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.deepPurple, width: 2),
            ),
            child: QrImageView(
              data: _upiString,
              version: QrVersions.auto,
              size: 150,
              backgroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
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
                        Clipboard.setData(
                          ClipboardData(text: _upiAddressController.text),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'UPI ID Copied!',
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiAppsGrid() {
    final upiApps = [
      {
        'name': 'Google Pay',
        'scheme': _getUpiDeepLink('tez://upi/pay'),
        'color': const Color(0xff4285F4),
        'icon': Icons.payment,
      },
      {
        'name': 'PhonePe',
        'scheme': _getUpiDeepLink('phonepe://pay'),
        'color': const Color(0xff5F259F),
        'icon': Icons.phone_android,
      },
      {
        'name': 'Paytm',
        'scheme': _getUpiDeepLink('paytmmp://pay'),
        'color': const Color(0xff00BAF2),
        'icon': Icons.account_balance_wallet,
      },
      {
        'name': 'BHIM',
        'scheme': _getUpiDeepLink('upi://pay'),
        'color': const Color(0xffED1C24),
        'icon': Icons.account_balance,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: upiApps.length,
      itemBuilder: (context, index) {
        final app = upiApps[index];
        return _buildUpiAppCard(
          name: app['name'] as String,
          deepLink: app['scheme'] as String,
          color: app['color'] as Color,
          icon: app['icon'] as IconData,
        );
      },
    );
  }

  Widget _buildUpiAppCard({
    required String name,
    required String deepLink,
    required Color color,
    required IconData icon,
  }) {
    return InkWell(
      onTap: _isProcessing ? null : () => _openUpiApp(deepLink),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: Icon(icon, size: 32, color: Colors.white),
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to Pay',
              style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionIdCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        children: [
          Text(
            'Transaction ID',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            _currentTransactionRef ?? '',
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'How to Pay:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[900],
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _instructionStep('1', 'Click on your UPI app above'),
          _instructionStep('2', 'Complete payment in the app'),
          _instructionStep('3', 'We\'ll verify automatically'),
        ],
      ),
    );
  }

  Widget _buildWaitingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.deepPurple[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple[200]!),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Waiting for payment...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete payment in UPI app.\nWe\'ll verify automatically.',
            style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Check attempt: $_statusCheckAttempts/$_maxStatusCheckAttempts',
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _instructionStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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

  // ✅ SUCCESS DIALOG
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
                    'Payment Successful! 🎉',
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
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Go back to previous screen
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
}
