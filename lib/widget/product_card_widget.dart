import 'package:demo/data/models/product_model.dart';
import 'package:demo/data/providers/auth_provider.dart';
import 'package:demo/data/providers/cart_provider.dart';
import 'package:demo/data/services/provider.dart';
import 'package:demo/presentation/screens/product/product_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
// ... other imports ...

class ProductCard extends StatefulWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  @override
  void initState() {
    super.initState();
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

  // TRENDING TAG

  Widget _cartButton(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final authProvider = context.watch<AuthProvider>();
    final quantity = cartProvider.getQuantity(widget.product.id);
    final isLoading = cartProvider.isLoading;

    // જો cart માં નથી, તો "Add to Cart" button
    if (quantity == 0) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: InkWell(
              onTap: isLoading
                  ? null
                  : () async {
                      if (authProvider.userId != null) {
                        await context.read<CartProvider>().addToCart(
                          userId: authProvider.userId!,
                          productId: widget.product.id,
                          quantity: 1,
                        );

                        if (mounted) {
                          _showPremiumSnackbar(
                            title: "Added to Cart! 🎉",
                            message: widget.product.title,
                            isSuccess: true,
                          );
                        }
                      } else {
                        if (mounted) {
                          _showPremiumSnackbar(
                            title: "Login Required",
                            message: "Please login to add items to cart",
                            isSuccess: false,
                          );
                        }
                      }
                    },
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLoading
                        ? [Colors.grey.shade400, Colors.grey.shade500]
                        : [const Color(0xff5B3DF5), const Color(0xff7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isLoading
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xff5B3DF5).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Add To Cart",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
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

    // જો cart માં છે, તો Compact Quantity Counter
    return _compactQtyCounter(context, quantity);
  }

  // 🎨 COMPACT QUANTITY COUNTER (Small & Clean)
  Widget _compactQtyCounter(BuildContext context, int quantity) {
    final cartProvider = context.read<CartProvider>();
    final authProvider = context.read<AuthProvider>();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: const Color(0xff5B3DF5),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff5B3DF5).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // MINUS BUTTON
                _compactButton(
                  icon: Icons.remove,
                  onTap: () async {
                    if (authProvider.userId != null) {
                      await cartProvider.decrementQuantity(
                        authProvider.userId!,
                        widget.product.id,
                      );

                      if (mounted && quantity > 1) {
                        _showPremiumSnackbar(
                          title: "Updated!",
                          message: "Quantity decreased",
                          isSuccess: true,
                        );
                      }
                    }
                  },
                ),

                // QUANTITY DISPLAY
                Expanded(
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      quantity.toString(),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // PLUS BUTTON
                _compactButton(
                  icon: Icons.add,
                  onTap: () async {
                    if (authProvider.userId != null) {
                      await cartProvider.incrementQuantity(
                        authProvider.userId!,
                        widget.product.id,
                      );

                      if (mounted) {
                        _showPremiumSnackbar(
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
          ),
        );
      },
    );
  }

  // 🎨 COMPACT +/- BUTTON
  Widget _compactButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: const Color(0xff5B3DF5)),
      ),
    );
  }

  // 🎨 PREMIUM CART BUTTON

  // 🎨 PREMIUM COUNTER BUTTON
  Widget _premiumCounterButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xff5B3DF5).withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xff5B3DF5).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: const Color(0xff5B3DF5)),
      ),
    );
  }

  // 🎨 PREMIUM SNACKBAR METHOD
  void _showPremiumSnackbar({
    required String title,
    required String message,
    required bool isSuccess,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _PremiumSnackBarWidget(
        title: title,
        message: message,
        isSuccess: isSuccess,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  Widget _tag(bool isTrending) {
    if (!isTrending) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepPurple,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        "TRENDING",
        style: TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _priceAndCart(BuildContext context) {
    if (_isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "₹${widget.product.price}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "₹${widget.product.oldPrice}",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: _cartButton(context)),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              Text(
                "₹${widget.product.price}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "₹${widget.product.oldPrice}",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          _cartButton(context),
        ],
      );
    }
  }

  // 🆕 SHOW SNACKBAR METHOD
  void _showSnackBar({
    required String title,
    required String message,
    required bool isSuccess,
    VoidCallback? onAction,
    String? actionText,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _ProductCardSnackBar(
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
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final favProvider = context.watch<FavoritesProvider>();
    final isFavorite = favProvider.isFavorite(widget.product.id);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          // Navigate to product details
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EnhancedNailProductDetails(
                productId: widget.product.id,
                title: widget.product.title,
                mainImage: widget.product.image,
                productImages: widget.product.productImages.isNotEmpty
                    ? widget.product.productImages
                    : [widget.product.image],
                oldPrice: widget.product.oldPrice,
                review: widget.product.reviews,
                price: widget.product.price,
              ),
            ),
          );
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // Product Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.network(
                        widget.product.image,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),

                    // Favorite Button
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () async {
                            if (authProvider.userId != null) {
                              await favProvider.toggleFavorite(
                                authProvider.userId!,
                                widget.product,
                              );

                              if (mounted) {
                                final nowFav = favProvider.isFavorite(
                                  widget.product.id,
                                );

                                _showSnackBar(
                                  title: nowFav ? "Added!" : "Removed!",
                                  message: nowFav
                                      ? "${widget.product.title} added to favorites"
                                      : "${widget.product.title} removed from favorites",
                                  isSuccess: nowFav,
                                  // actionText: nowFav ? "VIEW" : null,
                                  onAction: nowFav
                                      ? () {
                                          // Navigate to favorites
                                          Navigator.pushNamed(
                                            context,
                                            '/favorites',
                                          );
                                        }
                                      : null,
                                );
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isFavorite ? Colors.red : Colors.grey,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Discount Badge
                    if (widget.product.oldPrice > widget.product.price)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade600,
                                Colors.red.shade800,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "${(((widget.product.oldPrice - widget.product.price) / widget.product.oldPrice) * 100).toInt()}% OFF",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Product Details Section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Title
                      Text(
                        widget.product.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),

                      Text(
                        widget.product.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            "${widget.product.reviews} Reviews",
                            style: GoogleFonts.poppins(fontSize: 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "FREE SHIPPING ABOVE ₹799",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // const Spacer(),

                      // Price Row
                      Row(
                        children: [
                          Text(
                            "₹${widget.product.price.toInt()}",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                          const SizedBox(width: 6),
                          if (widget.product.oldPrice > widget.product.price)
                            Text(
                              "₹${widget.product.oldPrice.toInt()}",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 6),
                      // const SizedBox(width: 12),
                      _cartButton(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🎨 ProductCard SnackBar Widget (same as before)
class _ProductCardSnackBar extends StatefulWidget {
  final String title;
  final String message;
  final bool isSuccess;
  final VoidCallback onDismiss;
  final VoidCallback? onAction;
  final String? actionText;

  const _ProductCardSnackBar({
    required this.title,
    required this.message,
    required this.isSuccess,
    required this.onDismiss,
    this.onAction,
    this.actionText,
  });

  @override
  State<_ProductCardSnackBar> createState() => _ProductCardSnackBarState();
}

class _ProductCardSnackBarState extends State<_ProductCardSnackBar>
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

// 🎨 PREMIUM SNACKBAR WIDGET
class _PremiumSnackBarWidget extends StatefulWidget {
  final String title;
  final String message;
  final bool isSuccess;
  final VoidCallback onDismiss;

  const _PremiumSnackBarWidget({
    required this.title,
    required this.message,
    required this.isSuccess,
    required this.onDismiss,
  });

  @override
  State<_PremiumSnackBarWidget> createState() => _PremiumSnackBarWidgetState();
}

class _PremiumSnackBarWidgetState extends State<_PremiumSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

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
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.isSuccess
                        ? [const Color(0xff00C853), const Color(0xff00E676)]
                        : [const Color(0xffFF3D00), const Color(0xffFF6E40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (widget.isSuccess
                                  ? const Color(0xff00C853)
                                  : const Color(0xffFF3D00))
                              .withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Animated Icon Container
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              widget.isSuccess
                                  ? Icons.check_circle_rounded
                                  : Icons.error_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 16),

                    // Text Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.95),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Close Button
                    IconButton(
                      onPressed: widget.onDismiss,
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
