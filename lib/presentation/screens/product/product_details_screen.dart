import 'package:demo/data/providers/auth_provider.dart';
import 'package:demo/data/providers/cart_provider.dart';
import 'package:demo/data/services/provider.dart';
import 'package:demo/presentation/screens/Auth/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EnhancedNailProductDetails extends StatefulWidget {
  final String title;
  final String mainImage;
  final double oldPrice;
  final int review;
  final double price;
  final List<String> productImages;
  final int productId;

  const EnhancedNailProductDetails({
    super.key,
    required this.title,
    required this.mainImage,
    required this.oldPrice,
    required this.review,
    required this.price,
    required this.productImages,
    required this.productId,
  });

  @override
  State<EnhancedNailProductDetails> createState() =>
      _EnhancedNailProductDetailsState();
}

class _EnhancedNailProductDetailsState extends State<EnhancedNailProductDetails>
    with SingleTickerProviderStateMixin {
  int selectedImage = 0;
  int qty = 1;
  String? selectedSize;
  String? selectedBundle;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  final List<String> sizes = ['XS', 'S', 'M', 'L'];
  final List<Map<String, dynamic>> bundles = [
    {
      'title': 'Buy 2 Sets Save 10%',
      'price': 6300.00,
      'oldPrice': 7000.00,
      'savings': 700.00,
      'badge': 'SAVE 10%',
    },
    {
      'title': 'Buy 3 Sets Save 20%',
      'price': 7840.00,
      'oldPrice': 9800.00,
      'savings': 1960.00,
      'badge': 'SAVE 20%',
    },
  ];

  @override
  void initState() {
    super.initState();
    selectedSize = 'M';
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showFullScreenImage(int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => FullScreenImageViewer(
        images: widget.productImages,
        initialIndex: index,
      ),
    );
  }

  void _showSizeChart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SizeChartBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    // 🔥 WATCH PROVIDERS - આથી real-time updates મળશે
    final favProvider = context.watch<FavoritesProvider>();
    final cartProvider = context.watch<CartProvider>();

    // 🔥 GET CURRENT STATE FROM PROVIDERS
    final isFavorite = favProvider.isFavorite(widget.productId);
    final cartQuantity = cartProvider.getQuantity(widget.productId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.share_outlined, size: 20),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isMobile
            ? _mobileView(isFavorite, cartProvider, cartQuantity)
            : _webView(isFavorite, cartProvider, cartQuantity),
      ),
    );
  }

  Widget _webView(
    bool isFavorite,
    CartProvider cartProvider,
    int cartQuantity,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _imageGallery(isFavorite),
            const SizedBox(width: 40),
            Expanded(child: _details(cartProvider, cartQuantity)),
          ],
        ),
      ),
    );
  }

  Widget _mobileView(
    bool isFavorite,
    CartProvider cartProvider,
    int cartQuantity,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _imageGallery(isFavorite),
        const SizedBox(height: 24),
        _details(cartProvider, cartQuantity),
      ],
    );
  }

  // 🔥 IMAGE GALLERY - હવે isFavorite parameter લે છે
  Widget _imageGallery(bool isFavorite) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = MediaQuery.of(context).size.width < 900;
        final thumbnailSize = isMobile ? 50.0 : 60.0;
        final mainImageSize = isMobile
            ? constraints.maxWidth - thumbnailSize - 16
            : 420.0;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: List.generate(widget.productImages.length, (i) {
                  return InkWell(
                    onTap: () => setState(() => selectedImage = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          width: 2.5,
                          color: selectedImage == i
                              ? const Color(0xFF6C5CE7)
                              : Colors.transparent,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: selectedImage == i
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF6C5CE7,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          widget.productImages[i],
                          width: thumbnailSize,
                          height: thumbnailSize,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: thumbnailSize,
                              height: thumbnailSize,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.image),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _showFullScreenImage(selectedImage),
                      child: Hero(
                        tag: 'product_image_$selectedImage',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.productImages[selectedImage],
                            width: mainImageSize,
                            height: mainImageSize,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: mainImageSize,
                                height: mainImageSize,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image, size: 80),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    // 🔥 FAVORITE BUTTON - FIXED
                    Positioned(
                      top: 12,
                      right: 12,
                      child: InkWell(
                        onTap: () async {
                          // 🔥 GET AUTH PROVIDER
                          final authProvider = context.read<AuthProvider>();

                          if (authProvider.userId != null) {
                            // 🔥 TOGGLE FAVORITE - Use productId only (no product object needed)
                            await context
                                .read<FavoritesProvider>()
                                .toggleFavorite(
                                  authProvider.userId!,
                                  null, // product object નથી, માત્ર productId use કરો
                                  productId: widget.productId,
                                );

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isFavorite
                                        ? "Removed from favorites"
                                        : "Added to favorites",
                                  ),
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          } else {
                            // User not logged in
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please login to add favorites'),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? Colors.red
                                : Colors.grey.shade700,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔥 DETAILS SECTION
  Widget _details(CartProvider cartProvider, int cartQuantity) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badgeRow(),
          const SizedBox(height: 16),
          Text(
            widget.title,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.3,
              letterSpacing: -0.5,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFB300), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '4.5',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFB300),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${widget.review} reviews)',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹ ${widget.price.toInt()}',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6C5CE7),
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '₹ ${widget.oldPrice.toInt()}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Save 45%',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4CAF50),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C5CE7).withOpacity(0.1),
                  const Color(0xFFA29BFE).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6C5CE7).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFF6C5CE7),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Hurry Up! Only 3 left in stock!',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF6C5CE7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _bundleSection(),
          const SizedBox(height: 24),
          _sizeSection(),
          const SizedBox(height: 24),
          Text(
            'Quantity',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 28),
          // 🔥 ACTION BUTTONS
          _actionButtons(cartProvider, cartQuantity),
          const SizedBox(height: 28),
          _expandableSections(),
          const SizedBox(height: 20),
          _customizeLink(),
        ],
      ),
    );
  }

  // 🔥 ACTION BUTTONS - FIXED WITH AUTHPROVIDER
  Widget _actionButtons(CartProvider cartProvider, int cartQuantity) {
    final isLoading = cartProvider.isLoading;

    return Column(
      children: [
        // 🔥 ADD TO CART / QUANTITY COUNTER
        if (cartQuantity == 0)
          // ADD TO CART BUTTON
          SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      _controller.forward().then((_) => _controller.reverse());

                      // 🔥 GET AUTH PROVIDER
                      final authProvider = context.read<AuthProvider>();

                      if (authProvider.userId != null) {
                        // 🔥 ADD TO CART WITH DYNAMIC USER ID
                        await cartProvider.addToCart(
                          userId: authProvider.userId!,
                          productId: widget.productId,
                          quantity: qty,
                        );

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("${widget.title} added to cart"),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } else {
                        // User not logged in
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please login to add to cart'),
                            duration: Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isLoading
                    ? Colors.grey
                    : const Color(0xFF6C5CE7),
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : ScaleTransition(
                      scale: _scaleAnimation,
                      child: Text(
                        'ADD TO CART',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
            ),
          )
        else
          // QUANTITY COUNTER (જો cart માં છે)
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF6C5CE7), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'In Cart',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6C5CE7),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        // 🔥 GET AUTH PROVIDER
                        final authProvider = context.read<AuthProvider>();

                        if (authProvider.userId != null) {
                          await cartProvider.decrementQuantity(
                            authProvider.userId!,
                            widget.productId,
                          );
                        }
                      },
                      icon: const Icon(Icons.remove, size: 20),
                      color: const Color(0xFF6C5CE7),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C5CE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cartQuantity.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        // 🔥 GET AUTH PROVIDER
                        final authProvider = context.read<AuthProvider>();

                        if (authProvider.userId != null) {
                          await cartProvider.incrementQuantity(
                            authProvider.userId!,
                            widget.productId,
                          );
                        }
                      },
                      icon: const Icon(Icons.add, size: 20),
                      color: const Color(0xFF6C5CE7),
                    ),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // BUY NOW BUTTON
        SizedBox(
          height: 56,
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF8B7FF8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              onPressed: () async {
                _controller.forward().then((_) => _controller.reverse());

                // 🔥 GET AUTH PROVIDER
                final authProvider = context.read<AuthProvider>();

                if (authProvider.userId != null) {
                  // જો cart માં નથી તો add કરો
                  if (cartQuantity == 0) {
                    await cartProvider.addToCart(
                      userId: authProvider.userId!,
                      productId: widget.productId,
                      quantity: qty,
                    );
                  }

                  // Cart screen પર જાવ
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const MainLayout(initialIndex: 1), // Cart tab
                      ),
                      (route) => false,
                    );
                  }
                } else {
                  // User not logged in
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please login to buy'),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Buy with ',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Image.network(
                    'https://cdn.worldvectorlogo.com/logos/shopify.svg',
                    height: 20,
                    color: Colors.white,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(
                        'ShopPay',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bundleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'BUNDLE & SAVE',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const Spacer(),
          ],
        ),
        const SizedBox(height: 12),
        ...bundles.map((bundle) => _bundleOption(bundle)).toList(),
      ],
    );
  }

  Widget _bundleOption(Map<String, dynamic> bundle) {
    final isSelected = selectedBundle == bundle['title'];
    return GestureDetector(
      onTap: () => setState(() => selectedBundle = bundle['title']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C5CE7) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF6C5CE7)
                      : Colors.grey.shade400,
                  width: 2,
                ),
                color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bundle['title'],
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Wow! You save Rs. ${bundle['savings'].toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    bundle['badge'],
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rs. ${bundle['price'].toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Rs. ${bundle['oldPrice'].toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey.shade400,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sizeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'SIZE',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _showSizeChart,
              child: Row(
                children: [
                  const Icon(
                    Icons.straighten,
                    size: 16,
                    color: Color(0xFF6C5CE7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'SIZE CHART',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF6C5CE7),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sizes.map((size) {
            final isSelected = selectedSize == size;
            return GestureDetector(
              onTap: () => setState(() => selectedSize = size),
              child: Container(
                width: 60,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6C5CE7) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF6C5CE7)
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    size,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _badgeRow() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C5CE7).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            '-45% OFF',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '17 sold in last 15 hours',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFF6F00),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _expandableSections() {
    return Column(
      children: [
        _expandableSection(
          'Product Description',
          'High-quality press-on nails made with premium materials. Easy to apply and remove. Long-lasting and durable design.',
        ),
        const SizedBox(height: 12),
        _expandableSection(
          'Complimentary Tool Kit Includes',
          '• Nail File\n• Cuticle Pusher\n• Alcohol Prep Pad\n• Mini Nail File\n• Application Instructions',
        ),
      ],
    );
  }

  Widget _expandableSection(String title, String content) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customizeLink() {
    return Center(
      child: RichText(
        text: TextSpan(
          text: 'Want to customize your nail shape or length? ',
          style: GoogleFonts.poppins(color: Colors.grey.shade700, fontSize: 14),
          children: [
            TextSpan(
              text: 'Click here',
              style: GoogleFonts.poppins(
                color: const Color(0xFF6C5CE7),
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Full Screen Image Viewer (No changes needed - same as before)
class FullScreenImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => currentIndex = index);
            },
            itemCount: widget.images.length,
            itemBuilder: (context, index) {
              return InteractiveViewer(
                maxScale: 3.0,
                minScale: 1.0,
                child: Center(
                  child: Hero(
                    tag: 'product_image_$index',
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.image,
                          size: 100,
                          color: Colors.white,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (currentIndex > 0)
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                const SizedBox(width: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentIndex + 1} / ${widget.images.length}',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                if (currentIndex < widget.images.length - 1)
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
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
}

// Size Chart Bottom Sheet (Same as before - no changes needed)
class SizeChartBottomSheet extends StatelessWidget {
  const SizeChartBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Irsa Nails Size Guide',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStep1(),
                  const SizedBox(height: 32),
                  _buildStep2(),
                  const SizedBox(height: 32),
                  _buildStep3(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP 1: MEASURE YOUR NAILS',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'METHOD 1: (RECOMMENDED)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hold a measuring tape horizontally to measure the widest curvature of your nail bed. Record the sizes.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'METHOD 2:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Place a ruler against your nail bed. Mark the widest part of your nail. Measure the distance between the two dots.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STEP 2: CHOOSE THE RIGHT SIZE',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'measurements in mm',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Table(
          border: TableBorder.all(color: Colors.grey.shade300),
          children: [
            _buildTableRow([
              'SIZE',
              'THUMB',
              'INDEX',
              'MIDDLE',
              'RING',
              'PINKY',
            ], isHeader: true),
            _buildTableRow(['XS', '14', '10', '11', '10', '8']),
            _buildTableRow(['S', '15', '11', '12', '11', '9']),
            _buildTableRow(['M', '16', '12', '13', '12', '10']),
            _buildTableRow(['L', '17', '13', '14', '13', '11']),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• PLEASE SELECT THE SIZE THAT FITS MOST OF YOUR FINGERS.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• CONSIDER SIZING UP IF YOU ARE BETWEEN TWO SIZES OR HAVE FLATTER NAIL BEDS.',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP 3: NAIL SHAPES & LENGTHS',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        _buildShapeGrid(context),
      ],
    );
  }

  Widget _buildShapeGrid(BuildContext context) {
    final shapes = [
      {'name': 'Long Oval', 'length': '27-30MM'},
      {'name': 'Long Almond', 'length': '25-28MM'},
      {'name': 'Medium Almond', 'length': '22-25MM'},
      {'name': 'Short Almond', 'length': '18-21MM'},
      {'name': 'Long Coffin', 'length': '26-30MM'},
      {'name': 'Medium Coffin', 'length': '19-23MM'},
      {'name': 'Short Coffin', 'length': '16-18MM'},
      {'name': 'Short Squoval', 'length': '15-17MM'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 16,
      children: shapes.map((shape) {
        return Container(
          width: (MediaQuery.of(context).size.width - 72) / 2,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                shape['name']!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'APPROX. LENGTH: ${shape['length']}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  TableRow _buildTableRow(List<String> cells, {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader
            ? const Color(0xFF6C5CE7).withOpacity(0.1)
            : Colors.white,
      ),
      children: cells.map((cell) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            cell,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
              color: isHeader ? const Color(0xFF6C5CE7) : Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }).toList(),
    );
  }
}