import 'dart:developer';

import 'package:confetti/confetti.dart';
import 'package:demo/models/get_cart_item_model.dart';
import 'package:demo/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  CartScreenState createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  int shippingMode = 1;

  List<GetCartItemMode> cartItems = [];
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    loadCart(); // 👈 આ લાઇન ઉમેરો
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadCart(); // 🔥 everytime screen opens
  }

  Future<void> loadCart() async {
    try {
      log("🔥 loadCart called");

      final data = await ApiService.getCart(1);

      setState(() {
        cartItems = List<GetCartItemMode>.from(data); // 👈 VERY IMPORTANT
        isLoading = false;
      });

      log("✅ cartItems length: ${cartItems.length}");
    } catch (e) {
      log("❌ Cart error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
      // appBar: _appBar(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: isDesktop ? _desktopView() : _mobileView(),
      ),
    );
  }

  // ================= DESKTOP =================
  Widget _desktopView() {
    return SingleChildScrollView(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// LEFT
          Expanded(flex: 3, child: _leftSection()),

          const SizedBox(width: 24),

          /// RIGHT
          Expanded(
            flex: 1,
            child: Column(
              children: [
                if (!isCouponApplied) _bestCouponHint(), // 👈 SHOW THIS FIRST
                _couponSection(),
                const SizedBox(height: 10),

                /// STICKY EFFECT
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Positioned.fill(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _orderSummary(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> coupons = [
    {"code": "SAVE200", "discount": 200, "desc": "Save ₹200 on your order"},
    {"code": "WELCOME100", "discount": 100, "desc": "Welcome offer ₹100 OFF"},
    {"code": "FIRST50", "discount": 50, "desc": "Flat ₹50 OFF"},
  ];
  String? appliedCoupon;
  int discountAmount = 0;
  void applyBestCoupon() {
    coupons.sort((a, b) => b["discount"].compareTo(a["discount"]));

    setState(() {
      appliedCoupon = coupons.first["code"];
      discountAmount = coupons.first["discount"];
    });

    _confettiController.play();
  }

  void showCouponSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Available Coupons",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              ...coupons.map((coupon) {
                return ListTile(
                  leading: const Icon(Icons.local_offer),
                  title: Text(coupon["code"]),
                  subtitle: Text(coupon["desc"]),
                  trailing: TextButton(
                    child: const Text("APPLY"),
                    onPressed: () {
                      setState(() {
                        appliedCoupon = coupon["code"];
                        discountAmount = coupon["discount"];
                      });
                      Navigator.pop(context);
                      _confettiController.play();
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget couponSummary() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: appliedCoupon == null
            ? const Color(0xffF5F3FF)
            : const Color(0xffE8FFF1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              appliedCoupon == null
                  ? "Best coupon available"
                  : "Coupon $appliedCoupon applied (₹$discountAmount OFF)",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),

          if (appliedCoupon == null)
            TextButton(onPressed: showCouponSheet, child: const Text("VIEW"))
          else
            TextButton(
              onPressed: () {
                setState(() {
                  appliedCoupon = null;
                  discountAmount = 0;
                });
              },
              child: const Text("REMOVE"),
            ),
        ],
      ),
    );
  }

  // ================= MOBILE =================
  Widget _mobileView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _leftSection(),

          const SizedBox(height: 20),

          /// 🔥 BEST COUPON (TOP ORANGE BOX)
          if (!isCouponApplied) _bestCouponHint(),

          const SizedBox(height: 10),

          /// 💜 UNLOCK YOUR SAVINGS (INPUT + APPLY)
          _couponSection(),

          const SizedBox(height: 10),

          /// 🧾 ORDER SUMMARY
          _orderSummary(),
        ],
      ),
    );
  }

  // ================= APP BAR =================
  PreferredSizeWidget _appBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xffF8F9FB),
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      title: Text(
        "My Cart",
        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600),
      ),
      actions: [
        Icon(Icons.notifications_none, color: Colors.deepPurple),
        const SizedBox(width: 16),
        const CircleAvatar(radius: 16),
        const SizedBox(width: 16),
      ],
    );
  }

  // ================= LEFT SECTION =================
  Widget _leftSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// HEADER ROW (Left + Right text)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// LEFT SIDE
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Almost Yours ✨",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Review items before checkout",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            /// RIGHT SIDE
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Welcome back Jelii",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Shop your items here",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        /// CART TABLE
        _cartTable(),

        const SizedBox(height: 24),

        /// SHIPPING MODE
        _shippingMode(),
      ],
    );
  }

  Widget _cartTable() {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 📱 MOBILE UNIQUE INFO
          if (isMobile)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 18,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You have added ${cartItems.length} unique "
                      "${cartItems.length == 1 ? "product" : "products"} to your cart",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          /// 💻 WEB HEADER
          if (!isMobile) ...[_cartHeader(), const Divider(height: 24)],

          /// 🛒 CART ITEMS
          for (int i = 0; i < cartItems.length; i++) _cartItem(i),
        ],
      ),
    );
  }

  Widget _cartHeader() {
    return Row(
      children: [
        const SizedBox(width: 55),
        const SizedBox(width: 12),
        Expanded(flex: 3, child: _headerText("Product")),
        SizedBox(width: 90, child: _headerText("Qty", center: true)),
        Expanded(child: _headerText("Total")),
        const SizedBox(width: 32),
      ],
    );
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 700;
  }

  Widget _cartItem(int index) {
    return _isMobile(context) ? _cartItemMobile(index) : _cartItemWeb(index);
  }

  Widget _cartItemMobile(int index) {
    final item = cartItems[index];
    final int itemTotal = (item.price * item.quantity).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: _box(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🖼 IMAGE
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade100,
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(item.image),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 12),

          /// 📦 DETAILS (TITLE, PRICE, QTY)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "₹ ${item.price}",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Container(child: _qtyCounter(index)),
              ],
            ),
          ),

          /// ❌ CLOSE BUTTON
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () async {
                  final cartId = cartItems[index].cartId;
                  try {
                    await ApiService.removeFromCart(cartId);
                    setState(() => cartItems.removeAt(index));
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to remove item")),
                    );
                  }
                },
              ),
              Text(
                "₹ $itemTotal",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _cartItemWeb(int index) {
    final item = cartItems[index];
    // final int itemTotal = item.price * item.quantity;
    final int itemTotal = (item.price * item.quantity).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(item.image),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                Text(
                  "₹ ${item.price}",
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          _qtyCounter(index),
          Expanded(
            child: Text(
              "₹ $itemTotal",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              final cartId = cartItems[index].cartId;
              await ApiService.removeFromCart(cartId);
              setState(() => cartItems.removeAt(index));
            },
          ),
        ],
      ),
    );
  }

  Widget _qtyCounter(int index) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      width: isMobile ? 84 : 100,
      height: 34,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _qtyButton(
            icon: Icons.remove,
            onTap: () {
              if (cartItems[index].quantity > 1) {
                setState(() => cartItems[index].quantity--);
              }
            },
          ),
          Text(
            cartItems[index].quantity.toString(),
            style: const TextStyle(fontSize: 13),
          ),
          _qtyButton(
            icon: Icons.add,
            onTap: () {
              setState(() => cartItems[index].quantity++);
            },
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return SizedBox(
      width: 28,
      height: 28,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          hoverColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: onTap,
          child: Center(child: Icon(icon, size: 14)),
        ),
      ),
    );
  }

  // ================= SHIPPING =================
  Widget _shippingMode() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title("Choose shipping mode"),
          const SizedBox(height: 12),
          _shippingTile(
            value: 0,
            title: "Store pickup (Free)",
            subtitle: "Ready within 1 hour",
          ),
          const SizedBox(height: 12),
          _shippingTile(
            value: 1,
            title: "Home delivery (₹2,000)",
            subtitle: "2 - 4 days",
            address: "12 Adenuga Street, Tajudeen Avenue, Ikeja, Lagos State.",
          ),
        ],
      ),
    );
  }

  Widget _shippingTile({
    required int value,
    required String title,
    required String subtitle,
    String? address,
  }) {
    final selected = shippingMode == value;

    return InkWell(
      onTap: () => setState(() => shippingMode = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.deepPurple : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  if (address != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        address,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Radio<int>(
              value: value,
              groupValue: shippingMode,
              activeColor: Colors.deepPurple,
              onChanged: (v) => setState(() => shippingMode = v!),
            ),
          ],
        ),
      ),
    );
  }

  bool isCouponApplied = false;
  bool isInvalidCoupon = false;

  final TextEditingController couponController = TextEditingController();
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );
  @override
  void dispose() {
    couponController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  // COUPE SECTION =============================
  Widget _couponSection() {
    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isCouponApplied
                ? const LinearGradient(
                    colors: [Color(0xffE8FFF1), Color(0xffF6FFFA)],
                  )
                : const LinearGradient(
                    colors: [Color(0xffF5F3FF), Color(0xffFFFFFF)],
                  ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCouponApplied
                  ? Colors.green
                  : Colors.deepPurple.shade100,
            ),
            boxShadow: [
              BoxShadow(
                color: isCouponApplied
                    ? Colors.green.withOpacity(.25)
                    : Colors.black.withOpacity(.06),
                blurRadius: 14,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// TITLE + BADGE
              Row(
                children: [
                  Text(
                    isCouponApplied
                        ? "Coupon Applied 🎉"
                        : "Unlock Your Savings",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isCouponApplied ? Colors.green : Colors.deepPurple,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!isCouponApplied)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "BEST DEAL",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                isCouponApplied
                    ? "You saved ₹200 on this order"
                    : "Apply exclusive coupon & celebrate your discount",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 16),

              /// INPUT + APPLY BUTTON
              Row(
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      transform: isInvalidCoupon
                          ? Matrix4.translationValues(8, 0, 0)
                          : Matrix4.identity(),
                      child: TextField(
                        readOnly: true,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.green,
                        ),
                        controller: couponController,
                        decoration: InputDecoration(
                          hintText: "Enter coupon code",
                          hintStyle: GoogleFonts.poppins(fontSize: 12),
                          errorText: isInvalidCoupon
                              ? "Invalid coupon code"
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),

                            borderSide: BorderSide(color: Colors.green),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: isCouponApplied ? null : _applyCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCouponApplied
                          ? Colors.green
                          : Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isCouponApplied ? "Applied" : "Apply",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        /// CONFETTI
        Positioned.fill(
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 20,
            colors: const [
              Colors.green,
              Colors.deepPurple,
              Colors.orange,
              Colors.pink,
              Colors.brown,
              Colors.blue,
            ],
          ),
        ),
      ],
    );
  }

  void _applyCoupon() {
    if (couponController.text.trim().toUpperCase() == "SAVE200") {
      setState(() {
        isCouponApplied = true;
        isInvalidCoupon = false;
      });
      _confettiController.play(); // 🎉 celebration
    } else {
      setState(() {
        isInvalidCoupon = true;
      });
    }
  }

  Widget _bestCouponHint() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xffFFF7E6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer, color: Colors.orange),
          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Best Coupon Available",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Use SAVE200 & get ₹200 OFF",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          TextButton(onPressed: _applyBestCoupon, child: const Text("APPLY")),
        ],
      ),
    );
  }

  void _applyBestCoupon() {
    setState(() {
      couponController.text = "SAVE200"; // 👈 THIS IS THE ANSWER
      isCouponApplied = true;
      isInvalidCoupon = false;
    });

    _confettiController.play(); // 🎉
  }

  void applyCoupon(String code) {
    if (code == "SAVE200") {
      setState(() {
        appliedCoupon = code;
        discountAmount = 200; // 👈 HERE
      });
    }
  }

  double get subtotal {
    return cartItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  int get tax => 2500;
  int get shippingCost => shippingMode == 1 ? 2000 : 0;

  double get total => subtotal + tax + shippingCost - discountAmount;
  // double total = cartItems.fold<double>(
  //   0.0,
  //   (sum, item) => sum + (item.price * item.quantity),
  // );

  // Text("Total: ₹${total.toStringAsFixed(0)}")

  // ================= SUMMARY =================
  Widget _orderSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title("Order summary"),
          const SizedBox(height: 12),

          _row("Subtotal", "₹ $subtotal"),
          _row("Tax", "₹ $tax"),
          _row("Shipping", "₹ $shippingCost"),

          /// 👇 NEW DISCOUNT ROW
          if (discountAmount > 0) _row("Discount", "- ₹ $discountAmount"),

          const Divider(),

          _row("Total", "₹ $total", bold: true),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {},
              child: Text(
                "Proceed to payment",
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================
  Widget _row(String t, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(t),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.bold : null)),
        ],
      ),
    );
  }

  Widget _title(String text) => Text(
    text,
    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600),
  );

  Widget _headerText(String text, {bool center = false}) => Text(
    text,
    textAlign: center ? TextAlign.center : TextAlign.start,
    style: GoogleFonts.poppins(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Colors.grey,
    ),
  );

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12),
    ],
  );
}
