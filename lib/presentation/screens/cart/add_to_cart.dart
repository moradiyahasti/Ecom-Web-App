import 'package:confetti/confetti.dart';
import 'package:demo/data/providers/auth_provider.dart';
import 'package:demo/presentation/screens/Settings/address_screen.dart';
import 'package:demo/data/providers/cart_provider.dart';
import 'package:demo/utils/snackbar_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  CartScreenState createState() => CartScreenState();
}

class CartScreenState extends State<CartScreen> {
  int shippingMode = 1;
  bool isCouponApplied = false;
  bool isInvalidCoupon = false;
  int discountAmount = 0;

  final TextEditingController couponController = TextEditingController();
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );

  final List<Map<String, dynamic>> coupons = [
    {"code": "SAVE200", "discount": 200, "desc": "Save ₹200 on your order"},
    {"code": "WELCOME100", "discount": 100, "desc": "Welcome offer ₹100 OFF"},
    {"code": "FIRST50", "discount": 50, "desc": "Flat ₹50 OFF"},
  ];

  @override
  void initState() {
    super.initState();
  
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();

      if (authProvider.userId != null) {
        context.read<CartProvider>().loadCart(authProvider.userId!);
      }
    });
  }

  @override
  void dispose() {
    couponController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xffF8F9FB),
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
          Expanded(flex: 3, child: _leftSection()),
          const SizedBox(width: 24),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                if (!isCouponApplied) _bestCouponHint(),
                _couponSection(),
                const SizedBox(height: 10),
                _orderSummary(),
              ],
            ),
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
          if (!isCouponApplied) _bestCouponHint(),
          const SizedBox(height: 10),
          _couponSection(),
          const SizedBox(height: 10),
          _orderSummary(),
        ],
      ),
    );
  }

  // ================= LEFT SECTION =================
  Widget _leftSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        _cartTable(),
        const SizedBox(height: 24),
        _shippingMode(),
      ],
    );
  }

  Widget _cartTable() {
    // 🔥 Provider માંથી cart items લો
    final cartProvider = context.watch<CartProvider>();
    final cartItems = cartProvider.cartItems;
    final isLoading = cartProvider.isLoading;

    final isMobile = MediaQuery.of(context).size.width < 700;

    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: _box(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (cartItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: _box(),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                "Your cart is empty",
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          if (!isMobile) ...[_cartHeader(), const Divider(height: 24)],
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

  Widget _cartItem(int index) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return isMobile ? _cartItemMobile(index) : _cartItemWeb(index);
  }

  Widget _cartItemMobile(int index) {
    final cartProvider = context.read<CartProvider>();
    final item = cartProvider.cartItems[index];
    final int itemTotal = (item.price * item.quantity).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: _box(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                _qtyCounter(item.productId, item.quantity),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.close, size: 20),
              
                onPressed: () async {
                  final authProvider = context.read<AuthProvider>();

                  if (authProvider.userId != null) {
                    await cartProvider.removeFromCart(
                      authProvider.userId!, // 🔥 DYNAMIC
                      item.productId,
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
    final cartProvider = context.read<CartProvider>();
    final item = cartProvider.cartItems[index];
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
          _qtyCounter(item.productId, item.quantity),
          Expanded(
            child: Text(
              "₹ $itemTotal",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () async {
              // await cartProvider.removeFromCart(1, item.productId);
              await cartProvider.removeFromCart(item.userID, item.productId);

              if (mounted) {
                SnackbarService.show(
                  context: context,
                  title: "Removed!",
                  message: "${item.title} removed from cart",
                  isSuccess: false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _qtyCounter(int productId, int quantity) {
    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>(); // 🔥 GET AUTH

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
          
            onTap: () async {
              if (authProvider.userId != null) {
                await cartProvider.decrementQuantity(
                  authProvider.userId!, 
                  productId,
                );
                if (mounted) {
                  SnackbarService.show(
                    context: context,
                    title: "Updated!",
                    message: "Quantity decreased",
                    isSuccess: true,
                  );
                }
              }
            },
          ),
          Text(quantity.toString(), style: const TextStyle(fontSize: 13)),
          _qtyButton(
            icon: Icons.add,
           
            onTap: () async {
              if (authProvider.userId != null) {
                await cartProvider.incrementQuantity(
                  authProvider.userId!, // 🔥 DYNAMIC
                  productId,
                );
                if (mounted) {
                  SnackbarService.show(
                    context: context,
                    title: "Updated!",
                    message: "Quantity increased",
                    isSuccess: true,
                  );
                }
              }
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
            title: "Home delivery (₹330)",
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

  // ================= COUPON SECTION =================
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
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    ? "You saved ₹$discountAmount on this order"
                    : "Apply exclusive coupon & celebrate your discount",
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
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
        discountAmount = 200;
      });
      _confettiController.play();
    } else {
      setState(() => isInvalidCoupon = true);
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
          TextButton(
            onPressed: () {
              setState(() {
                couponController.text = "SAVE200";
                isCouponApplied = true;
                isInvalidCoupon = false;
                discountAmount = 200;
              });
              _confettiController.play();
            },
            child: const Text("APPLY"),
          ),
        ],
      ),
    );
  }

  // ================= ORDER SUMMARY =================
  Widget _orderSummary() {
    // 🔥 Provider માંથી totals લો
    final cartProvider = context.watch<CartProvider>();
    final subtotal = cartProvider.totalPrice;
    final tax = 80;
    final shippingCost = shippingMode == 1 ? 130 : 0;
    final total = subtotal + tax + shippingCost - discountAmount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title("Order summary"),
          const SizedBox(height: 12),
          _row("Subtotal", "₹ ${subtotal.toInt()}"),
          _row("Tax", "₹ $tax"),
          _row("Shipping", "₹ $shippingCost"),
          if (discountAmount > 0) _row("Discount", "- ₹ $discountAmount"),
          const Divider(),
          _row("Total", "₹ ${total.toInt()}", bold: true),
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
              onPressed: () {
                final cartProvider = context.read<CartProvider>();
                final subtotal = cartProvider.totalPrice;
                final tax = 80;
                final shippingCost = shippingMode == 1 ? 130 : 0;
                final total = subtotal + tax + shippingCost - discountAmount;
                final cartItems = cartProvider.cartItems;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddressScreen(
                      subtotal: subtotal,
                      tax: tax.toDouble(),
                      shipping: shippingCost.toDouble(),
                      discount: discountAmount.toDouble(),
                      total: total.toDouble(),
                      cartItems: cartItems,
                    ),
                  ),
                );
              },

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
