import 'dart:async';
import 'dart:developer';
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      log("🔄 App resumed - refreshing products");
      loadProducts(showLoading: false);

      // 🔥 Refresh user data when app resumes
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isLoggedIn && authProvider.userId != null) {
        final userId = authProvider.userId!;
        context.read<CartProvider>().loadCart(userId);
        context.read<FavoritesProvider>().loadFavorites(userId);
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
                    _buildBannerCards(),
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
                      ? [Colors.green.shade600, Colors.green.shade700]
                      : [Colors.red.shade600, Colors.red.shade700],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isSuccess ? Colors.green : Colors.red)
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
