/* import 'dart:developer';
import 'package:demo/models/product_model.dart';
import 'package:demo/services/api_service.dart';
import 'package:demo/services/cart_provider.dart';
import 'package:demo/services/provider.dart';
import 'package:demo/utils/app_colors.dart';
import 'package:demo/widget/all_widget.dart';
import 'package:demo/widget/banner_card_widget.dart';
import 'package:demo/widget/category_item_widget.dart';
import 'package:demo/widget/fotterview.dart';
import 'package:demo/widget/product_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Product> products = [];
  bool loading = true;

  late AnimationController _bannerController;
  late AnimationController _categoryController;
  late Animation<double> _bannerAnimation;
  late Animation<Offset> _categorySlideAnimation;

  @override
  void initState() {
    super.initState();

    // Banner animation
    _bannerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _bannerAnimation = CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeOutQuart,
    );

    // Category animation
    _categoryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _categorySlideAnimation =
        Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _categoryController,
            curve: Curves.easeOutCubic,
          ),
        );

    _bannerController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _categoryController.forward();
    });

    // 🔥 Load data using Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().loadFavorites(1);
      context.read<CartProvider>().loadCart(1); // 🛒 Load cart
    });

    // Load products
    loadProducts();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    try {
      setState(() => loading = true);
      final data = await ApiService.fetchProducts();
      setState(() {
        products = data;
        loading = false;
      });
      log("✅ Products fetched: ${products.length}");
    } catch (e) {
      log("❌ Error fetching products: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAnimatedBanner(),
            _buildMarquee(),
            const SizedBox(height: 25),
            _buildCategoriesSection(),
            const SizedBox(height: 20),
            _buildTrendingSection(),
            const SizedBox(height: 5),
            _buildProductsGrid(),
            const SizedBox(height: 25),
            _buildBannerCards(),
            const SizedBox(height: 25),
            featuresSection(),
            const SizedBox(height: 25),
            const FooterView(),
          ],
        ),
      ),
    );
  }

  // 🎨 ANIMATED BANNER
  Widget _buildAnimatedBanner() {
    return ScaleTransition(
      scale: _bannerAnimation,
      child: FadeTransition(
        opacity: _bannerAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade400,
                Colors.deepPurple.shade600,
                Colors.purple.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: _buildPulsingCircle(150, Colors.white.withOpacity(0.1)),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: _buildPulsingCircle(120, Colors.white.withOpacity(0.08)),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Text(
                            "🔥",
                            style: TextStyle(fontSize: 50 * value),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Big Sale",
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Up to 50% OFF",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
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

  Widget _buildPulsingCircle(double size, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        );
      },
      onEnd: () => setState(() {}),
    );
  }

  // 📢 MARQUEE
  Widget _buildMarquee() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.black, Colors.grey.shade900]),
      ),
      child: Marquee(
        text:
            "UP TO 50% OFF ON SELECTED ITEMS   •   LIMITED TIME DEALS   •   EXTRA DISCOUNTS ON PREPAID ORDERS   •   FREE SHIPPING ABOVE ₹799",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
        scrollAxis: Axis.horizontal,
        blankSpace: 50,
        velocity: 80,
        pauseAfterRound: const Duration(seconds: 0),
      ),
    );
  }

  // 🎯 CATEGORIES SECTION
  Widget _buildCategoriesSection() {
    return Column(
      children: [
        SlideTransition(
          position: _categorySlideAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Categories",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDeep,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade100,
                        Colors.purple.shade100,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "View All",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 90,
          child: Center(
            child: ListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                CategoryItem("Mobiles", Icons.phone_android),
                CategoryItem("Fashion", Icons.checkroom),
                CategoryItem("Electronics", Icons.devices),
                CategoryItem("Shoes", Icons.hiking),
                CategoryItem("Beauty", Icons.brush),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🔥 TRENDING SECTION
  Widget _buildTrendingSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade400, Colors.deepOrange],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Trending Products",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      "Hot 🔥",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
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

  // 📦 PRODUCTS GRID
  Widget _buildProductsGrid() {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        ),
      );
    }

    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: _getCardHeight(context),
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: ProductCard(product: product),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "No products found",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🖼️ BANNER CARDS
  Widget _buildBannerCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;
          return isMobile ? _buildMobileBanners() : _buildDesktopBanners();
        },
      ),
    );
  }

  Widget _buildMobileBanners() {
    return Column(
      children: [
        _buildAnimatedBannerCard(0),
        const SizedBox(height: 16),
        _buildAnimatedBannerCard(1),
      ],
    );
  }

  Widget _buildDesktopBanners() {
    return Row(
      children: [
        Expanded(child: _buildAnimatedBannerCard(0)),
        const SizedBox(width: 10),
        Expanded(child: _buildAnimatedBannerCard(1)),
      ],
    );
  }

  Widget _buildAnimatedBannerCard(int index) {
    final images = [
      'https://media.istockphoto.com/id/1426458619/photo/happy-man-using-mobile-phone-app-while-buying-groceries-in-supermarket-and-looking-at-camera.jpg?s=612x612&w=0&k=20&c=oUiBgl9UZ1ga77CnvG1zdGm73ehb8GZOkfcScGqnXjs=',
      'https://www.shutterstock.com/image-photo/fashion-shopping-friends-choice-clothes-260nw-2472680449.jpg',
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: bannerCard(
              image: images[index],
              title: 'Shop Now',
              subtitle: 'Special Offer',
            ),
          ),
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  double _getCardHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 340;
    if (width < 600) return 380;
    if (width < 900) return 410;
    return 440;
  }
}
 */

import 'dart:developer';
import 'package:demo/data/models/product_model.dart';
import 'package:demo/data/services/api_service.dart';
import 'package:demo/data/providers/cart_provider.dart';
import 'package:demo/data/services/provider.dart';
import 'package:demo/utils/app_colors.dart';
import 'package:demo/widget/all_widget.dart';
import 'package:demo/widget/banner_card_widget.dart';
import 'package:demo/widget/category_item_widget.dart';
import 'package:demo/widget/fotterview.dart';
import 'package:demo/widget/product_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Product> products = [];
  bool loading = true;

  late AnimationController _bannerController;
  late AnimationController _categoryController;
  late AnimationController _whatsappController;
  late Animation<double> _bannerAnimation;
  late Animation<Offset> _categorySlideAnimation;
  late Animation<double> _whatsappPulseAnimation;

  // 📱 WhatsApp number (change this to your number)
  final String whatsappNumber = "+919925503530"; // Replace with your number

  @override
  void initState() {
    super.initState();

    // Banner animation
    _bannerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _bannerAnimation = CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeOutQuart,
    );

    // Category animation
    _categoryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _categorySlideAnimation =
        Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _categoryController,
            curve: Curves.easeOutCubic,
          ),
        );

    // WhatsApp pulse animation
    _whatsappController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _whatsappPulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _whatsappController, curve: Curves.easeInOut),
    );

    _bannerController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _categoryController.forward();
    });

    // Load data using Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().loadFavorites(1);
      context.read<CartProvider>().loadCart(1);
    });

    // Load products
    loadProducts();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    _categoryController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    try {
      setState(() => loading = true);
      final data = await ApiService.fetchProducts();
      setState(() {
        products = data;
        loading = false;
      });
      log("✅ Products fetched: ${products.length}");
    } catch (e) {
      log("❌ Error fetching products: $e");
      setState(() => loading = false);
    }
  }

  // 📱 Open WhatsApp
  Future<void> _openWhatsApp() async {
    final message = "Hello! I need help with my order.";
    final url = Uri.parse(
      "https://wa.me/$whatsappNumber?text=${Uri.encodeComponent(message)}",
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      log('Error opening WhatsApp: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error opening WhatsApp'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildAnimatedBanner(),
                _buildMarquee(),
                const SizedBox(height: 25),
                _buildCategoriesSection(),
                const SizedBox(height: 20),
                _buildTrendingSection(),
                const SizedBox(height: 5),
                _buildProductsGrid(),
                const SizedBox(height: 25),
                _buildBannerCards(),
                const SizedBox(height: 25),
                featuresSection(),
                const SizedBox(height: 25),
                const FooterView(),
              ],
            ),
          ),
          // 📱 WhatsApp Floating Button
          _buildWhatsAppButton(),
        ],
      ),
    );
  }

  // 📱 WhatsApp Floating Button
  Widget _buildWhatsAppButton() {
    return Positioned(
      right: 20,
      bottom: 20,
      child: ScaleTransition(
        scale: _whatsappPulseAnimation,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xff25D366).withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openWhatsApp,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xff25D366), Color(0xff128C7E)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Icon(
                  FontAwesomeIcons.whatsapp,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎨 ANIMATED BANNER
  Widget _buildAnimatedBanner() {
    return ScaleTransition(
      scale: _bannerAnimation,
      child: FadeTransition(
        opacity: _bannerAnimation,
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          height: 200,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade400,
                Colors.deepPurple.shade600,
                Colors.purple.shade700,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: -50,
                right: -50,
                child: _buildPulsingCircle(150, Colors.white.withOpacity(0.1)),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: _buildPulsingCircle(120, Colors.white.withOpacity(0.08)),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 1000),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Text(
                            "🔥",
                            style: TextStyle(fontSize: 50 * value),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Big Sale",
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "Up to 50% OFF",
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
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

  Widget _buildPulsingCircle(double size, Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        );
      },
      onEnd: () => setState(() {}),
    );
  }

  // 📢 MARQUEE
  Widget _buildMarquee() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.black, Colors.grey.shade900]),
      ),
      child: Marquee(
        text:
            "UP TO 50% OFF ON SELECTED ITEMS   •   LIMITED TIME DEALS   •   EXTRA DISCOUNTS ON PREPAID ORDERS   •   FREE SHIPPING ABOVE ₹799",
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
        scrollAxis: Axis.horizontal,
        blankSpace: 50,
        velocity: 80,
        pauseAfterRound: const Duration(seconds: 0),
      ),
    );
  }

  // 🎯 CATEGORIES SECTION
  Widget _buildCategoriesSection() {
    return Column(
      children: [
        SlideTransition(
          position: _categorySlideAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Categories",
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDeep,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade100,
                        Colors.purple.shade100,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "View All",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 90,
          child: Center(
            child: ListView(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: const [
                CategoryItem("Mobiles", Icons.phone_android),
                CategoryItem("Fashion", Icons.checkroom),
                CategoryItem("Electronics", Icons.devices),
                CategoryItem("Shoes", Icons.hiking),
                CategoryItem("Beauty", Icons.brush),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 🔥 TRENDING SECTION
  Widget _buildTrendingSection() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade400, Colors.deepOrange],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.local_fire_department,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Trending Products",
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      "Hot 🔥",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
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

  // 📦 PRODUCTS GRID
  Widget _buildProductsGrid() {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        ),
      );
    }

    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        mainAxisExtent: _getCardHeight(context),
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: ProductCard(product: product),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "No products found",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🖼️ BANNER CARDS
  Widget _buildBannerCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 600;
          return isMobile ? _buildMobileBanners() : _buildDesktopBanners();
        },
      ),
    );
  }

  Widget _buildMobileBanners() {
    return Column(
      children: [
        _buildAnimatedBannerCard(0),
        const SizedBox(height: 16),
        _buildAnimatedBannerCard(1),
      ],
    );
  }

  Widget _buildDesktopBanners() {
    return Row(
      children: [
        Expanded(child: _buildAnimatedBannerCard(0)),
        const SizedBox(width: 10),
        Expanded(child: _buildAnimatedBannerCard(1)),
      ],
    );
  }

  Widget _buildAnimatedBannerCard(int index) {
    final images = [
      'https://media.istockphoto.com/id/1426458619/photo/happy-man-using-mobile-phone-app-while-buying-groceries-in-supermarket-and-looking-at-camera.jpg?s=612x612&w=0&k=20&c=oUiBgl9UZ1ga77CnvG1zdGm73ehb8GZOkfcScGqnXjs=',
      'https://www.shutterstock.com/image-photo/fashion-shopping-friends-choice-clothes-260nw-2472680449.jpg',
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: bannerCard(
              image: images[index],
              title: 'Shop Now',
              subtitle: 'Special Offer',
            ),
          ),
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  double _getCardHeight(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 400) return 340;
    if (width < 600) return 380;
    if (width < 900) return 410;
    return 440;
  }
}
