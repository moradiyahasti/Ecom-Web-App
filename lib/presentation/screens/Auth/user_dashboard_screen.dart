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

  // User Data
  String userName = "";
  String userEmail = "";
  String userMobile = "";
  String userAddress = "";
  String userCity = "";
  String userState = "";
  String userPincode = "";

  // Order Statistics
  int totalOrders = 0;
  int successfulOrders = 0;
  int pendingOrders = 0;
  double totalSpent = 0.0;
  double pendingAmount = 0.0;

  // Order History
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
      // Load user profile data
      final name = await TokenService.getName();
      final email = await TokenService.getEmail();
      final authProvider = context.read<AuthProvider>();
      final userId = authProvider.userId;

      if (userId != null) {
        // Fetch user address
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
        } catch (e) {
          debugPrint("Error fetching address: $e");
        }

        // Fetch user orders
        try {
          final orders = await ApiService.getUserOrders(userId);

          setState(() {
            orderHistory = orders;
            _calculateStatistics();
          });
        } catch (e) {
          debugPrint("Error fetching orders: $e");
          // Use mock data if API fails
          _loadMockOrderData();
        }
      } else {
        // No user ID - use defaults
        setState(() {
          userName = name ?? "Guest User";
          userEmail = email ?? "guest@example.com";
          _loadMockOrderData();
        });
      }

      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint("Error loading user data: $e");
    }
  }

  void _calculateStatistics() {
    totalOrders = orderHistory.length;
    successfulOrders = orderHistory
        .where(
          (order) =>
              order['payment_status']?.toString().toLowerCase() ==
                  'completed' ||
              order['payment_status']?.toString().toLowerCase() == 'paid',
        )
        .length;
    pendingOrders = orderHistory
        .where(
          (order) =>
              order['payment_status']?.toString().toLowerCase() == 'pending',
        )
        .length;

    totalSpent = orderHistory
        .where(
          (order) =>
              order['payment_status']?.toString().toLowerCase() ==
                  'completed' ||
              order['payment_status']?.toString().toLowerCase() == 'paid',
        )
        .fold(0.0, (sum, order) {
          final total = order['total'];
          if (total is int) return sum + total.toDouble();
          if (total is double) return sum + total;
          return sum;
        });

    pendingAmount = orderHistory
        .where(
          (order) =>
              order['payment_status']?.toString().toLowerCase() == 'pending',
        )
        .fold(0.0, (sum, order) {
          final total = order['total'];
          if (total is int) return sum + total.toDouble();
          if (total is double) return sum + total;
          return sum;
        });
  }

  void _loadMockOrderData() {
    // Mock data for demonstration
    orderHistory = [
      {
        "order_id": 1001,
        "date": DateTime.now()
            .subtract(const Duration(days: 2))
            .toIso8601String(),
        "status": "delivered",
        "payment_status": "completed",
        "items": [
          {"name": "Nail Polish - Rose Gold", "qty": 2, "price": 299.0},
          {"name": "Gel Nail Kit", "qty": 1, "price": 1499.0},
        ],
        "subtotal": 2097.0,
        "tax": 80.0,
        "shipping": 130.0,
        "discount": 200.0,
        "total": 2107.0,
      },
      {
        "order_id": 1002,
        "date": DateTime.now()
            .subtract(const Duration(days: 5))
            .toIso8601String(),
        "status": "shipped",
        "payment_status": "completed",
        "items": [
          {"name": "Matte Top Coat", "qty": 1, "price": 199.0},
          {"name": "Nail Art Brush Set", "qty": 3, "price": 399.0},
        ],
        "subtotal": 1396.0,
        "tax": 80.0,
        "shipping": 0.0,
        "discount": 0.0,
        "total": 1476.0,
      },
      {
        "order_id": 1003,
        "date": DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        "status": "processing",
        "payment_status": "pending",
        "items": [
          {"name": "UV Nail Lamp", "qty": 1, "price": 2999.0},
          {"name": "Cuticle Oil Set", "qty": 2, "price": 249.0},
        ],
        "subtotal": 3497.0,
        "tax": 80.0,
        "shipping": 130.0,
        "discount": 0.0,
        "total": 3707.0,
      },
    ];

    _calculateStatistics();
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
                        // Welcome Section
                        _buildWelcomeSection(),

                        const SizedBox(height: 24),

                        // Stats Cards
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

                        // Order History
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
            child: const Icon(
              Icons.person_outline,
              size: 40,
              color: Colors.white,
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
                color: Colors.deepPurple,
                delay: 0,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: "Successful",
                value: successfulOrders.toString(),
                icon: Icons.check_circle_outline,
                color: const Color(0xff00D9A5),
                delay: 100,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: "Pending",
                value: pendingOrders.toString(),
                icon: Icons.pending_outlined,
                color: const Color(0xffFF6B6B),
                delay: 200,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                title: "Total Spent",
                value: "₹${totalSpent.toInt()}",
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xffFFA500),
                delay: 300,
              ),
            ),
          ],
        ),
        if (pendingAmount > 0) ...[
          const SizedBox(height: 16),
          _buildStatCard(
            title: "Pending Payments",
            value: "₹${pendingAmount.toInt()}",
            icon: Icons.payment_outlined,
            color: const Color(0xffE74C3C),
            delay: 400,
            fullWidth: true,
          ),
        ],
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      if (!fullWidth)
                        Icon(
                          Icons.trending_up,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xff1A1A2E),
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
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.deepPurple, Color(0xff8B7FE8)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : "?",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Profile",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              userName,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xff1A1A2E),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.deepPurple),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No orders yet",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Start shopping to see your order history",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
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

    // Parse date
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
    final paymentStatus = (order['payment_status'] ?? 'pending').toString();

    // Parse items
    List<Map<String, dynamic>> items = [];
    try {
      if (order['items'] is List) {
        items = (order['items'] as List).cast<Map<String, dynamic>>();
      } else if (order['order_items'] is List) {
        items = (order['order_items'] as List).cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint("Error parsing items: $e");
    }

    // Parse total
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
      debugPrint("Error parsing total: $e");
    }

    final statusColor = _getStatusColor(status);
    final paymentColor = _getPaymentColor(paymentStatus);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: paymentStatus.toLowerCase() == 'pending'
              ? const Color(0xffFF6B6B).withOpacity(0.3)
              : Colors.grey.shade200,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(20),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  statusColor.withOpacity(0.2),
                  statusColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                "#$orderId",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ),
          title: Text(
            "Order #$orderId",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xff1A1A2E),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM yyyy, hh:mm a').format(date),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildStatusChip(status, statusColor),
                  const SizedBox(width: 8),
                  _buildStatusChip(
                    paymentStatus.toLowerCase() == 'completed' ||
                            paymentStatus.toLowerCase() == 'paid'
                        ? 'Paid'
                        : 'Pending Payment',
                    paymentColor,
                  ),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "₹${total.toInt()}",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xff1A1A2E),
                ),
              ),
              Text(
                "${items.length} items",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          children: [
            const Divider(),
            const SizedBox(height: 12),
            if (items.isNotEmpty)
              ...items.map((item) => _buildOrderItem(item))
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  "No item details available",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _buildOrderSummary(order),
            if (paymentStatus.toLowerCase() == 'pending') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffFF6B6B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Complete payment for order #$orderId",
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        backgroundColor: const Color(0xffFF6B6B),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.payment, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        "Complete Payment",
                        style: GoogleFonts.poppins(
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

  Widget _buildOrderItem(Map<String, dynamic> item) {
    final name = item['name'] ?? item['product_name'] ?? 'Unknown Product';
    final qty = item['qty'] ?? item['quantity'] ?? 1;

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
      debugPrint("Error parsing price: $e");
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xff1A1A2E),
              ),
            ),
          ),
          Text(
            "Qty: $qty",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "₹${(price * qty).toInt()}",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xff1A1A2E),
            ),
          ),
        ],
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
      debugPrint("Error parsing order summary: $e");
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
        const Divider(),
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
              fontSize: 14,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: color ?? Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: color ?? const Color(0xff1A1A2E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return const Color(0xff00D9A5);
      case 'shipped':
        return Colors.deepPurple;
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
