import 'dart:async';
import 'dart:developer';
import 'dart:math' as math;
import 'package:demo/data/models/product_model.dart';
import 'package:demo/data/providers/auth_provider.dart';
import 'package:demo/data/services/api_service.dart';
import 'package:demo/data/providers/cart_provider.dart';
import 'package:demo/data/services/provider.dart';
import 'package:demo/presentation/screens/product/product_details_screen.dart';
import 'package:demo/widget/all_widget.dart';
import 'package:demo/widget/banner_card_widget.dart';
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

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  List<Product> products = [];
  bool loading = true;

  // 🔍 SEARCH VARIABLES
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Product> _searchResults = [];
  bool _showSearchResults = false;
  Timer? _searchDebounce;
  String _searchErrorMessage = '';

  // 🔄 AUTO REFRESH TIMER
  Timer? _autoRefreshTimer;
  static const Duration _refreshInterval = Duration(seconds: 30);

  late AnimationController _bannerController;
  late AnimationController _categoryController;
  late AnimationController _whatsappController;
  late Animation<double> _bannerAnimation;
  late Animation<double> _whatsappPulseAnimation;

  final String whatsappNumber = "+919925503530";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Animations
    _bannerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _bannerAnimation = CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeOutQuart,
    );

    _categoryController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

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

    // 🔥 LOAD DATA using AuthProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();

      if (authProvider.isLoggedIn && authProvider.userId != null) {
        final userId = authProvider.userId!;

        // Load favorites and cart for logged-in user
        context.read<FavoritesProvider>().loadFavorites(userId);
        context.read<CartProvider>().loadCart(userId);
      }
    });

    loadProducts();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bannerController.dispose();
    _categoryController.dispose();
    _whatsappController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _showCustomSnackBar({
    required String title,
    required String message,
    required bool isSuccess,
    VoidCallback? onAction,
    String? actionText,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _CustomSnackBar(
        title: title,
        message: message,
        isSuccess: isSuccess,
        onDismiss: () => overlayEntry.remove(),
        onAction: onAction,
        actionText: actionText,
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   super.didChangeAppLifecycleState(state);

  //   if (state == AppLifecycleState.resumed) {
  //     log("🔄 App resumed - refreshing products");
  //     loadProducts(showLoading: false);

  //     // 🔥 Refresh user data when app resumes
  //     final authProvider = context.read<AuthProvider>();
  //     if (authProvider.isLoggedIn && authProvider.userId != null) {
  //       final userId = authProvider.userId!;
  //       context.read<CartProvider>().loadCart(userId);
  //       context.read<FavoritesProvider>().loadFavorites(userId);
  //     }
  //   }
  // }

  // 🔥 UPDATED HOME_SCREEN.DART METHOD
  // Replace your existing didChangeAppLifecycleState method with this:

  @override
  // 🔥 CRITICAL SECTION FROM home_screen.dart
  // Replace your didChangeAppLifecycleState method with this EXACT code:
  @override
// 🔥 UPDATED didChangeAppLifecycleState METHOD FOR home_screen.dart
// Replace your existing didChangeAppLifecycleState method with this:

@override
void didChangeAppLifecycleState(AppLifecycleState state) async {
  super.didChangeAppLifecycleState(state);

  if (state == AppLifecycleState.resumed) {
    log("🔄 App resumed - refreshing products");
    loadProducts(showLoading: false);

    // 🔥 Automatic reload on app resume (respects payment flag)
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isLoggedIn && authProvider.userId != null) {
      final userId = authProvider.userId!;
      final cartProvider = context.read<CartProvider>();
      
      // 🔥 CRITICAL: Use forceReload = false for automatic app resume
      // This will skip reload if payment is in progress
      await cartProvider.loadCart(
        userId,
        forceReload: false, // <-- Automatic reload, respect payment flag
      );
      
      await context.read<FavoritesProvider>().loadFavorites(userId);
      log("✅ App resumed - attempted cart reload (respects payment flag)");
    }
  }
}
  void _startAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(_refreshInterval, (timer) {
      log("🔄 Auto-refreshing products (every ${_refreshInterval.inSeconds}s)");
      loadProducts(showLoading: false);
    });
  }

  Future<void> loadProducts({bool showLoading = true}) async {
    try {
      if (showLoading) {
        setState(() => loading = true);
      }

      final data = await ApiService.fetchProducts();

      if (mounted) {
        setState(() {
          products = data;
          loading = false;
        });
        log("✅ Products fetched: ${products.length}");
      }
    } catch (e) {
      log("❌ Error fetching products: $e");
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _handleRefresh() async {
    log("🔄 Manual refresh triggered");
    await loadProducts(showLoading: false);
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _searchErrorMessage = '';
      });
      return;
    }

    setState(() {
      _searchErrorMessage = '';
    });

    try {
      final results = await ApiService.searchProducts(query);

      setState(() {
        _searchResults = results;
        _showSearchResults = true;

        if (results.isEmpty) {
          _searchErrorMessage = 'No products found for "$query"';
        }
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _searchErrorMessage = 'Error searching products';
      });
      log("❌ Search error: $e");
    }
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

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
      child: GestureDetector(
        onTap: () {
          if (_showSearchResults) {
            setState(() => _showSearchResults = false);
            _searchFocusNode.unfocus();
          }
        },
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _handleRefresh,
              color: Colors.deepPurple,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildAnimatedBanner(),
                    _buildMarquee(),

                    if (_showSearchResults && isMobile(context))
                      _buildSearchResults(),

                    const SizedBox(height: 25),
                    _buildTrendingSection(),
                    const SizedBox(height: 5),
                    _buildProductsGrid(),
                    const SizedBox(height: 25),
                    // _buildBannerCards(),
                    _buildPremiumHeader(),
                    const SizedBox(height: 20),
                    _buildPremiumNailsCarousel(),
                    const SizedBox(height: 25),

                    featuresSection(),

                    const SizedBox(height: 25),
                    const ContactFormSection(),
                    const SizedBox(height: 25),

                    FooterView(),
                  ],
                ),
              ),
            ),

            _buildWhatsAppButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade50,
            Colors.pink.shade50,
            Colors.purple.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✨ Sparkle Animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSparkle(Colors.pink.shade300, 0.0),
                    const SizedBox(width: 8),
                    Text("💅", style: TextStyle(fontSize: 36 * value)),
                    const SizedBox(width: 8),
                    _buildSparkle(Colors.purple.shade300, 0.5),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // 🎯 Main Title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                Colors.deepPurple.shade700,
                Colors.pink.shade400,
                Colors.purple.shade600,
              ],
            ).createShader(bounds),
            child: Text(
              "Premium Collection",
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 💫 Subtitle with animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 1,
                        width: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.deepPurple.shade300,
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          "Luxury Nail Art & Polish",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.deepPurple.shade700,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      Container(
                        height: 1,
                        width: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.shade300,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // 🏷️ Feature Tags
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFeatureTag("✨", "Long Lasting"),
              _buildFeatureTag("💎", "Premium Quality"),
              _buildFeatureTag("🌈", "50+ Colors"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSparkle(Color color, double delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 6.28, // Full rotation
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withOpacity(0.8),
                  color.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
            child: Icon(Icons.star, size: 16, color: color),
          ),
        );
      },
    );
  }

  Widget _buildFeatureTag(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.deepPurple.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumNailsCarousel() {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
        ),
      );
    }

    if (products.isEmpty) {
      return _buildEmptyState();
    }

    return _PremiumNailsCarousel(products: products);
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _searchErrorMessage.isEmpty
                      ? 'Found ${_searchResults.length} products'
                      : 'Search Results',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.deepPurple,
                  onPressed: () {
                    setState(() => _showSearchResults = false);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Flexible(
            child: _searchErrorMessage.isNotEmpty
                ? _buildNoResults()
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      return _buildSearchResultItem(_searchResults[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchErrorMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(Product product) {
    return InkWell(
      onTap: () {
        setState(() => _showSearchResults = false);
        _searchFocusNode.unfocus();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EnhancedNailProductDetails(
              productId: product.id,
              title: product.title,
              mainImage: product.image,
              productImages: product.productImages.isNotEmpty
                  ? product.productImages
                  : [product.image, product.image, product.image],
              oldPrice: product.oldPrice,
              review: product.reviews,
              price: product.price,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                product.image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${product.price}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${product.oldPrice}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xff25D366), Color(0xff128C7E)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: const Icon(
                  FontAwesomeIcons.whatsapp,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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

  Widget _buildMarquee() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.black, Colors.grey.shade900]),
      ),
      child: Marquee(
        text:
            "UP TO 50% OFF ON NAIL ART & EXTENSIONS • LIMITED TIME GLAM DEALS • EXTRA SAVINGS ON PREPAID APPOINTMENTS • FREE SHIPPING ABOVE ₹799",
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

  Widget _buildProductsGrid() {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(30),
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
      padding: const EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
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
    if (width < 400) return 380; // Was 340, now 380 (+40px)
    if (width < 600) return 420; // Was 380, now 420 (+40px)
    if (width < 900) return 450; // Was 410, now 450 (+40px)
    return 480;
  }
}

// 🎨 Custom Snackbar Widget
class _CustomSnackBar extends StatefulWidget {
  final String title;
  final String message;
  final bool isSuccess;
  final VoidCallback onDismiss;
  final VoidCallback? onAction;
  final String? actionText;

  const _CustomSnackBar({
    required this.title,
    required this.message,
    required this.isSuccess,
    required this.onDismiss,
    this.onAction,
    this.actionText,
  });

  @override
  State<_CustomSnackBar> createState() => _CustomSnackBarState();
}

class _CustomSnackBarState extends State<_CustomSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
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
    return Positioned(
      top: 50,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isSuccess
                      ? [Colors.deepPurple, Colors.deepPurple]
                      : [Colors.red.shade600, Colors.red.shade700],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isSuccess ? Colors.deepPurple : Colors.red)
                        .withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.isSuccess
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
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
}

class _PremiumNailsCarousel extends StatefulWidget {
  final List<Product> products;

  const _PremiumNailsCarousel({required this.products});

  @override
  State<_PremiumNailsCarousel> createState() => _PremiumNailsCarouselState();
}

class _PremiumNailsCarouselState extends State<_PremiumNailsCarousel>
    with TickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page?.round() ?? 0;
      });
    });

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 🎯 Carousel
        SizedBox(
          height: 520,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.products.length,
            itemBuilder: (context, index) {
              return _buildCarouselCard(widget.products[index], index);
            },
          ),
        ),

        const SizedBox(height: 24),

        // 📍 Page Indicators
        _buildPageIndicators(),

        const SizedBox(height: 16),

        // 🔥 Quick View Row (horizontal list of upcoming products)
        _buildQuickViewRow(),
      ],
    );
  }

  Widget _buildCarouselCard(Product product, int index) {
    final isActive = index == _currentPage;
    final scale = isActive ? 1.0 : 0.85;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.85, end: scale),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: isActive ? 1.0 : 0.6,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(isActive ? 0.3 : 0.1),
                    blurRadius: isActive ? 30 : 15,
                    offset: Offset(0, isActive ? 15 : 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: _buildProductCard(product, isActive),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product, bool isActive) {
    return GestureDetector(
      onTap: () => _navigateToDetails(product),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Colors.purple.shade50, Colors.pink.shade50],
          ),
        ),
        child: Stack(
          children: [
            // ✨ Shimmer Effect
            if (isActive) _buildShimmerEffect(),

            // 🖼️ Product Image
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 300,
              child: Hero(
                tag: 'product_${product.id}',
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.deepPurple.shade100, Colors.transparent],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Image.network(
                          product.image,
                          height: 280,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image,
                            size: 100,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ),

                      // 💎 Badge
                      // if (product.discount != null && product.discount! > 0)
                      //   Positioned(
                      //     top: 16,
                      //     right: 16,
                      //     child: _buildDiscountBadge(product.discount!),
                      //   ),
                      if (80 != null && 60! > 0)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: _buildDiscountBadge(50!),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 📝 Product Details
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0),
                      Colors.white,
                      Colors.white,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ⭐ Rating
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < (product.rating ?? 4)
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            color: Colors.amber.shade600,
                            size: 20,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '${product.rating ?? 4.5} (${product.reviews})',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 📌 Product Name
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 💰 Price Section
                    Row(
                      children: [
                        Text(
                          '₹${product.price}',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₹${product.oldPrice}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey.shade500,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const Spacer(),

                        // 🛒 Add to Cart Button
                        // Container(
                        //   padding: const EdgeInsets.all(12),
                        //   decoration: BoxDecoration(
                        //     gradient: LinearGradient(
                        //       colors: [
                        //         Colors.deepPurple,
                        //         Colors.purple.shade700,
                        //       ],
                        //     ),
                        //     borderRadius: BorderRadius.circular(16),
                        //     boxShadow: [
                        //       BoxShadow(
                        //         color: Colors.deepPurple.withOpacity(0.4),
                        //         blurRadius: 12,
                        //         offset: const Offset(0, 6),
                        //       ),
                        //     ],
                        //   ),
                        //   child: const Icon(
                        //     Icons.shopping_cart_rounded,
                        //     color: Colors.white,
                        //     size: 26,
                        //   ),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ❤️ Favorite Button
            /*             Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  color: Colors.red.shade400,
                  size: 22,
                ),
              ),
            ),
          */
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Positioned.fill(
          child: Transform.translate(
            offset: Offset(300 * _shimmerController.value - 150, 0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Colors.white.withOpacity(0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiscountBadge(int discount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade500, Colors.red.shade700],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        '$discount% OFF',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.products.length, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: isActive
                ? LinearGradient(
                    colors: [Colors.deepPurple, Colors.purple.shade700],
                  )
                : null,
            color: isActive ? null : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildQuickViewRow() {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.products.length,
        itemBuilder: (context, index) {
          final product = widget.products[index];
          final isSelected = index == _currentPage;

          return GestureDetector(
            onTap: () {
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isSelected ? 90 : 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                  width: isSelected ? 3 : 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: Colors.grey.shade100,
                  child: Image.network(
                    product.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.image, color: Colors.grey.shade400),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnhancedNailProductDetails(
          productId: product.id,
          title: product.title,
          mainImage: product.image,
          productImages: product.productImages.isNotEmpty
              ? product.productImages
              : [product.image, product.image, product.image],
          oldPrice: product.oldPrice,
          review: product.reviews,
          price: product.price,
        ),
      ),
    );
  }
}

// 🎯 ALTERNATIVE: 3D CAROUSEL (Optional Premium Effect)
class _Premium3DCarousel extends StatefulWidget {
  final List<Product> products;

  const _Premium3DCarousel({required this.products});

  @override
  State<_Premium3DCarousel> createState() => _Premium3DCarouselState();
}

class _Premium3DCarouselState extends State<_Premium3DCarousel> {
  late PageController _pageController;
  double _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 450,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.products.length,
        itemBuilder: (context, index) {
          final offset = (_currentPage - index).abs();
          final scale = math.max(0.8, 1 - (offset * 0.2));
          final rotationY = (index - _currentPage) * 0.3;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(rotationY)
              ..scale(scale),
            alignment: Alignment.center,
            child: _build3DCard(widget.products[index]),
          );
        },
      ),
    );
  }

  Widget _build3DCard(Product product) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.purple.shade50],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Product Image
            Center(
              child: Image.network(
                product.image,
                height: 250,
                fit: BoxFit.contain,
              ),
            ),

            // Product Info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.white],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      maxLines: 2,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${product.price}',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

// 📝 USAGE IN HomeScreen:
// Replace: _buildProductsGrid()
// With: _buildPremiumNailsCarousel()
// Or: _Premium3DCarousel(products: products)
