import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:demo/data/providers/auth_provider.dart';
import 'package:demo/data/services/token_service.dart';
import 'package:demo/data/services/api_service.dart';
import 'package:intl/intl.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  String userName = "";
  String userEmail = "";
  String userMobile = "";
  String userAddress = "";
  String userCity = "";
  String userState = "";
  String userPincode = "";

  int totalOrders = 0;
  int paidOrders = 0;
  int pendingOrders = 0;

  List<Map<String, dynamic>> orderHistory = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _loadUserData();
    _animationController.forward();
  }

  Future<void> _loadUserData() async {
    setState(() => isLoading = true);

    try {
      final name = await TokenService.getName();
      final email = await TokenService.getEmail();
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      debugPrint("🔍 USER DATA - ID: $userId, Name: $name, Email: $email");

      if (userId != null) {
        try {
          final addressData = await ApiService.getUserAddress(userId);

          setState(() {
            userName = name ?? "Guest User";
            userEmail = email ?? "guest@example.com";

            if (addressData != null) {
              userMobile = addressData['mobile'] ?? "";
              userAddress = addressData['address_line'] ?? "";
              userCity = addressData['city'] ?? "";
              userState = addressData['state'] ?? "";
              userPincode = addressData['pincode'] ?? "";
            }
          });

          debugPrint("✅ User loaded: $userName ($userEmail)");
        } catch (e) {
          debugPrint("❌ Error fetching address: $e");
        }

        try {
          final orders = await ApiService.getUserOrders(userId);

          debugPrint("📦 ORDERS FETCHED: ${orders.length} orders");

          setState(() {
            orderHistory = orders;
            _calculateStatistics();
          });
        } catch (e) {
          debugPrint("❌ Error fetching orders: $e");
        }
      } else {
        setState(() {
          userName = name ?? "Guest User";
          userEmail = email ?? "guest@example.com";
        });
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("❌ Error loading user data: $e");
    }
  }

  void _calculateStatistics() {
    totalOrders = orderHistory.length;
    paidOrders = 0;
    pendingOrders = 0;

    for (var order in orderHistory) {
      final paymentStatus =
          order['payment_status']?.toString().toLowerCase() ?? '';
      debugPrint(
        "🔍 Order ${order['order_id']}: Payment Status = '$paymentStatus'",
      );

      if (paymentStatus == 'paid' ||
          paymentStatus == 'completed' ||
          paymentStatus == 'success') {
        paidOrders++;
      } else if (paymentStatus == 'pending') {
        pendingOrders++;
      }
    }

    debugPrint("📊 FINAL STATS:");
    debugPrint("  Total Orders: $totalOrders");
    debugPrint("  Paid Orders: $paidOrders");
    debugPrint("  Pending Orders: $pendingOrders");
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          "My Dashboard",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xff1A1A2E),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.deepPurple),
            onPressed: _loadUserData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: RefreshIndicator(
                  onRefresh: _loadUserData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(isMobile ? 16 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeSection(),
                        const SizedBox(height: 24),
                        if (isMobile)
                          Column(
                            children: [
                              _buildStatsGrid(),
                              const SizedBox(height: 20),
                              _buildProfileCard(),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _buildStatsGrid()),
                              const SizedBox(width: 20),
                              Expanded(flex: 1, child: _buildProfileCard()),
                            ],
                          ),
                        const SizedBox(height: 24),
                        _buildOrderHistory(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Color(0xff8B7FE8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Welcome back! 👋",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  userName,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Here's your shopping overview",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : "?",
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: "Total Orders",
                value: totalOrders.toString(),
                icon: Icons.shopping_bag_outlined,
                color: const Color(0xff6C63FF),
                delay: 0,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: "Paid Orders",
                value: paidOrders.toString(),
                icon: Icons.check_circle_outline,
                color: const Color(0xff00D9A5),
                delay: 100,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildStatCard(
          title: "Pending Payments",
          value: pendingOrders.toString(),
          icon: Icons.pending_outlined,
          color: const Color(0xffFF6B6B),
          delay: 200,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required int delay,
    bool fullWidth = false,
  }) {
    return TweenAnimationBuilder(
      duration: Duration(milliseconds: 600 + delay),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double val, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * val),
          child: Opacity(
            opacity: val,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: color, size: 26),
                      ),
                      if (!fullWidth)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.trending_up,
                            color: Colors.green.shade600,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xff1A1A2E),
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, double val, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - val)),
          child: Opacity(
            opacity: val,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileRow(Icons.email_outlined, "Email", userEmail),
                  if (userMobile.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildProfileRow(
                      Icons.phone_outlined,
                      "Mobile",
                      userMobile,
                    ),
                  ],
                  if (userAddress.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildProfileRow(
                      Icons.location_on_outlined,
                      "Address",
                      "$userAddress${userCity.isNotEmpty ? ', $userCity' : ''}",
                    ),
                  ],
                  if (userState.isNotEmpty || userPincode.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildProfileRow(
                      Icons.map_outlined,
                      "Location",
                      "${userState.isNotEmpty ? userState : ''}${userPincode.isNotEmpty ? ' - $userPincode' : ''}",
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xff6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: const Color(0xff6C63FF)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff1A1A2E),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrderHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Order History",
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xff1A1A2E),
          ),
        ),
        const SizedBox(height: 16),
        if (orderHistory.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "No orders yet",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Start shopping to see your order history",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...orderHistory.asMap().entries.map((entry) {
            final index = entry.key;
            final order = entry.value;
            return TweenAnimationBuilder(
              duration: Duration(milliseconds: 400 + (index * 100)),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double val, child) {
                return Transform.translate(
                  offset: Offset(0, 30 * (1 - val)),
                  child: Opacity(
                    opacity: val,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildOrderCard(order),
                    ),
                  ),
                );
              },
            );
          }),
      ],
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['order_id'] ?? order['id'] ?? 0;

    DateTime date;
    try {
      final dateStr = order['date'] ?? order['created_at'];
      if (dateStr is String) {
        date = DateTime.parse(dateStr);
      } else {
        date = DateTime.now();
      }
    } catch (e) {
      date = DateTime.now();
    }

    final status = (order['status'] ?? 'processing').toString();
    final paymentStatus = (order['payment_status'] ?? 'pending')
        .toString()
        .toLowerCase();

    final isPending = paymentStatus == 'pending';
    final isPaid =
        paymentStatus == 'paid' ||
        paymentStatus == 'completed' ||
        paymentStatus == 'success';

    // 🔥 FIXED: Parse items properly
    List<Map<String, dynamic>> items = [];
    try {
      if (order['items'] != null) {
        if (order['items'] is String) {
          final decodedItems = jsonDecode(order['items']);
          if (decodedItems is List) {
            items = List<Map<String, dynamic>>.from(
              decodedItems.map((item) => Map<String, dynamic>.from(item)),
            );
          }
        } else if (order['items'] is List) {
          items = List<Map<String, dynamic>>.from(
            (order['items'] as List).map((item) {
              if (item is Map) {
                return Map<String, dynamic>.from(item);
              }
              return <String, dynamic>{};
            }),
          );
        }
      }
      debugPrint("✅ Order #$orderId parsed ${items.length} items");
    } catch (e) {
      debugPrint("❌ Error parsing items for order #$orderId: $e");
    }

    double total = 0.0;
    try {
      final totalValue = order['total'] ?? order['total_amount'] ?? 0;
      if (totalValue is int) {
        total = totalValue.toDouble();
      } else if (totalValue is double) {
        total = totalValue;
      } else if (totalValue is String) {
        total = double.tryParse(totalValue) ?? 0.0;
      }
    } catch (e) {
      debugPrint("❌ Error parsing total: $e");
    }

    final statusColor = _getStatusColor(status);
    final paymentColor = _getPaymentColor(paymentStatus);

    return Container(
      // margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPending
              ? const Color(0xffFF6B6B).withOpacity(0.3)
              : const Color(0xff00D9A5).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
                (isPending ? const Color(0xffFF6B6B) : const Color(0xff00D9A5))
                    .withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.15),
                  statusColor.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "#$orderId",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  "Order #$orderId",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff1A1A2E),
                  ),
                ),
              ),
              // 🔥 Show payment status badge in title
              _buildCompactStatusChip(
                isPaid ? '✓ PAID' : '⏳ PENDING',
                paymentColor,
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM yyyy').format(date),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "₹${total.toInt()}",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff1A1A2E),
                    ),
                  ),
                ],
              ),
            ],
          ),
          children: [
            Divider(color: Colors.grey.shade200, thickness: 1),
            const SizedBox(height: 12),

            // 🔥 FIXED: Show items like cart design
            if (items.isNotEmpty)
              ...items.map((item) => _buildCartStyleOrderItem(item))
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "No item details available",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, thickness: 1),
            // const SizedBox(height: 5),
            _buildOrderSummary(order),

            // 🔥 Payment button only for pending
            if (isPending) ...[
              const SizedBox(height: 10),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xffFF6B6B), Color(0xffFF8787)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffFF6B6B).withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.payment,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Complete payment for Order #$orderId",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xffFF6B6B),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payment, color: Colors.white, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        "Complete Payment",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 🔥 NEW: Cart-style item display (matching the image you showed)
  Widget _buildCartStyleOrderItem(Map<String, dynamic> item) {
    final name =
        item['name'] ??
        item['product_name'] ??
        item['title'] ??
        'Unknown Product';
    final subtitle = item['subtitle'] ?? 'Gel Information';
    final qty = item['qty'] ?? item['quantity'] ?? 1;
    final imageUrl = item['image_url'] ?? item['image'] ?? '';

    double price = 0.0;
    try {
      final priceValue = item['price'] ?? 0;
      if (priceValue is int) {
        price = priceValue.toDouble();
      } else if (priceValue is double) {
        price = priceValue;
      } else if (priceValue is String) {
        price = double.tryParse(priceValue) ?? 0.0;
      }
    } catch (e) {
      debugPrint("❌ Error parsing price: $e");
    }

    final itemTotal = price * qty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // 🔥 Product Image (like cart design)
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image_not_supported,
                          color: Colors.grey.shade400,
                          size: 30,
                        );
                      },
                    )
                  : Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.grey.shade400,
                      size: 30,
                    ),
            ),
          ),

          const SizedBox(width: 12),

          // 🔥 Product Info (like cart design)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xff1A1A2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                // Quantity display
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        "$qty",
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xff1A1A2E),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 🔥 Price (like cart design)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${itemTotal.toInt()}",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff1A1A2E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildOrderSummary(Map<String, dynamic> order) {
    double subtotal = 0.0;
    double tax = 0.0;
    double shipping = 0.0;
    double discount = 0.0;
    double total = 0.0;

    try {
      subtotal = _parseDouble(order['subtotal'] ?? order['sub_total'] ?? 0);
      tax = _parseDouble(order['tax'] ?? 0);
      shipping = _parseDouble(order['shipping'] ?? order['shipping_cost'] ?? 0);
      discount = _parseDouble(order['discount'] ?? 0);
      total = _parseDouble(order['total'] ?? order['total_amount'] ?? 0);
    } catch (e) {
      debugPrint("❌ Error parsing order summary: $e");
    }

    return Column(
      children: [
        if (subtotal > 0) _buildSummaryRow("Subtotal", "₹${subtotal.toInt()}"),
        if (tax > 0) _buildSummaryRow("Tax", "₹${tax.toInt()}"),
        if (shipping > 0) _buildSummaryRow("Shipping", "₹${shipping.toInt()}"),
        if (discount > 0)
          _buildSummaryRow(
            "Discount",
            "- ₹${discount.toInt()}",
            color: const Color(0xff00D9A5),
          ),
        Divider(color: Colors.grey.shade300, thickness: 1),
        _buildSummaryRow("Total", "₹${total.toInt()}", bold: true),
      ],
    );
  }

  double _parseDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Widget _buildSummaryRow(
    String label,
    String value, {
    bool bold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
              color: color ?? Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: bold ? 16 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: color ?? const Color(0xff1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'paid':
        return const Color(0xff00D9A5);
      case 'shipped':
        return const Color(0xff6C63FF);
      case 'processing':
        return const Color(0xffFFA500);
      case 'cancelled':
        return const Color(0xffFF6B6B);
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentColor(String paymentStatus) {
    switch (paymentStatus.toLowerCase()) {
      case 'completed':
      case 'paid':
      case 'success':
        return const Color(0xff00D9A5);
      case 'pending':
        return const Color(0xffFF6B6B);
      case 'failed':
        return const Color(0xffE74C3C);
      default:
        return Colors.grey;
    }
  }
}
