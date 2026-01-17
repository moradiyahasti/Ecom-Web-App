import 'package:demo/data/models/product_model.dart';
import 'package:demo/data/providers/auth_provider.dart';
import 'package:demo/data/providers/cart_provider.dart';
import 'package:demo/data/services/provider.dart';
import 'package:demo/utils/snackbar_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen>
    with TickerProviderStateMixin {
  AnimationController? _headerController;
  AnimationController? _floatingController;
  Animation<double>? _headerAnimation;
  Animation<double>? _floatingAnimation;

  @override
  void initState() {
    super.initState();

    // Header animation
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerController!,
      curve: Curves.easeOutBack,
    );

    // Floating animation for badges
    _floatingController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatingAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _floatingController!, curve: Curves.easeInOut),
    );

    _headerController!.forward();

    // 🔥 LOAD FAVORITES - Use AuthProvider for userId
    Future.microtask(() {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();

        if (authProvider.isLoggedIn && authProvider.userId != null) {
          context.read<FavoritesProvider>().loadFavorites(authProvider.userId!);
        }
      }
    });
  }

  @override
  void dispose() {
    _headerController?.dispose();
    _floatingController?.dispose();
    super.dispose();
  }

  void _showCustomSnackBar({
    required String title,
    required String message,
    required bool isSuccess,
    VoidCallback? onAction,
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
    final favProvider = context.watch<FavoritesProvider>();
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            floating: false,
            pinned: false,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.deepPurple.shade600,
                          Colors.deepPurple.shade400,
                          Colors.purple.shade400,
                        ],
                      ),
                    ),
                  ),

                  ..._buildFloatingCircles(),

                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ScaleTransition(
                            scale:
                                _headerAnimation ?? AlwaysStoppedAnimation(1.0),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "My Favorites",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 28,
                                        ),
                                      ),
                                      Text(
                                        "Your curated collection",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          if (favProvider.favorites.isNotEmpty)
                            FadeTransition(
                              opacity:
                                  _headerAnimation ??
                                  AlwaysStoppedAnimation(1.0),
                              child: Row(
                                children: [
                                  _buildStatCard(
                                    "${favProvider.favorites.length}",
                                    "Items",
                                    Icons.favorite,
                                  ),
                                  const SizedBox(width: 12),
                                  _buildStatCard(
                                    "₹ ${_calculateTotal(favProvider)}",
                                    "Total",
                                    Icons.currency_rupee,
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: favProvider.isLoading
                  ? _buildLoading()
                  : favProvider.favorites.isEmpty
                  ? _buildEmptyState()
                  : _buildGridView(favProvider, authProvider),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFloatingCircles() {
    if (_floatingController == null || _floatingAnimation == null) {
      return [];
    }

    return [
      Positioned(
        top: -50,
        right: -30,
        child: AnimatedBuilder(
          animation: _floatingController!,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _floatingAnimation!.value),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            );
          },
        ),
      ),
      Positioned(
        bottom: -20,
        left: -40,
        child: AnimatedBuilder(
          animation: _floatingController!,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, -_floatingAnimation!.value),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            );
          },
        ),
      ),
    ];
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateTotal(FavoritesProvider provider) {
    double total = 0;
    for (var item in provider.favorites) {
      total += item.price;
    }
    return total.toInt().toString();
  }

  Widget _buildLoading() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(80),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade50,
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: Colors.deepPurple,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Loading your favorites...",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
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
          child: Container(
            height: 500,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.deepPurple.shade50,
                        Colors.purple.shade50,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.deepPurple.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.deepPurple.shade400,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  "No Favorites Yet",
                  style: GoogleFonts.poppins(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Start adding products you love!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.shade400,
                          Colors.deepPurple.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shopping_bag,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Browse Products",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
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
      },
    );
  }

  Widget _buildGridView(
    FavoritesProvider favProvider,
    AuthProvider authProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 2;

          if (constraints.maxWidth >= 1200) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth >= 800) {
            crossAxisCount = 3;
          } else {
            crossAxisCount = 2;
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: favProvider.favorites.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.68,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final product = favProvider.favorites[index];

              return _AnimatedProductCard(
                product: product,
                index: index,
                onRemove: () async {
                  // 🔥 Get AuthProvider
                  final authProvider = context.read<AuthProvider>();

                  if (authProvider.userId != null) {
                    await context.read<FavoritesProvider>().toggleFavorite(
                      authProvider.userId!, // 🔥 DYNAMIC
                      product,
                    );

                    if (mounted) {
                      SnackbarService.show(
                        context: context,
                        title: "Removed!",
                        message: "${product.title} removed from favorites",
                        isSuccess: false,
                      );
                    }
                  }
                },
                onAddToCart: (product) async {
                  // 🔥 Get AuthProvider
                  final authProvider = context.read<AuthProvider>();

                  if (authProvider.userId != null) {
                    await context.read<CartProvider>().addToCart(
                      userId: authProvider.userId!, // 🔥 DYNAMIC
                      productId: product.id,
                      quantity: 1,
                    );

                    if (mounted) {
                      SnackbarService.show(
                        context: context,
                        title: "Added to Cart!",
                        message: product.title,
                        isSuccess: true,
                        actionText: "VIEW CART",
                        onAction: () {
                          // Navigate to cart screen
                          // Navigator.pushNamed(context, '/cart');
                        },
                      );
                    }
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _CustomSnackBar extends StatefulWidget {
  final String title;
  final String message;
  final bool isSuccess;
  final VoidCallback onDismiss;
  final VoidCallback? onAction;

  const _CustomSnackBar({
    required this.title,
    required this.message,
    required this.isSuccess,
    required this.onDismiss,
    this.onAction,
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
                          : Icons.close,
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
                          maxLines: 1,
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

class _AnimatedProductCard extends StatefulWidget {
  final Product product;
  final int index;
  final VoidCallback onRemove;
  final Function(Product) onAddToCart;

  const _AnimatedProductCard({
    required this.product,
    required this.index,
    required this.onRemove,
    required this.onAddToCart,
  });

  @override
  State<_AnimatedProductCard> createState() => _AnimatedProductCardState();
}

class _AnimatedProductCardState extends State<_AnimatedProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: 400 + (widget.index * 100)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
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
    final cartProvider = context.watch<CartProvider>();
    final cartQuantity = cartProvider.getQuantity(widget.product.id);
    final authProvider = context.watch<AuthProvider>();

    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: InkWell(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeInOut,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(15),
                          ),
                          child: Image.network(
                            widget.product.image,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: double.infinity,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.grey.shade200,
                                      Colors.grey.shade300,
                                    ],
                                  ),
                                ),
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 56,
                                  color: Colors.grey.shade500,
                                ),
                              );
                            },
                          ),
                        ),

                        Positioned(
                          top: 12,
                          right: 12,
                          child: _AnimatedFavoriteButton(
                            onPressed: widget.onRemove,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "₹${widget.product.price.toInt()}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // 🔥 QUANTITY COUNTER OR ADD TO CART BUTTON
                        if (cartQuantity == 0)
                          // ADD TO CART BUTTON
                          SizedBox(
                            width: double.infinity,
                            height: 36,
                            child: ElevatedButton(
                              onPressed: () async {
                                if (authProvider.userId != null) {
                                  await cartProvider.addToCart(
                                    userId: authProvider.userId!,
                                    productId: widget.product.id,
                                    quantity: 1,
                                  );

                                  if (context.mounted) {
                                    SnackbarService.show(
                                      context: context,
                                      title: "Added to Cart!",
                                      message: widget.product.title,
                                      isSuccess: true,
                                    );
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepPurple,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.shopping_cart_outlined,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Add to Cart',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          // QUANTITY COUNTER
                          Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.deepPurple.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // DECREMENT BUTTON
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      if (authProvider.userId != null) {
                                        await cartProvider.decrementQuantity(
                                          authProvider.userId!,
                                          widget.product.id,
                                        );
                                      }
                                    },
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(10),
                                      bottomLeft: Radius.circular(10),
                                    ),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.remove,
                                        size: 16,
                                        color: Colors.deepPurple.shade700,
                                      ),
                                    ),
                                  ),
                                ),

                                // QUANTITY DISPLAY
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Text(
                                    cartQuantity.toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple.shade700,
                                    ),
                                  ),
                                ),

                                // INCREMENT BUTTON
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () async {
                                      if (authProvider.userId != null) {
                                        await cartProvider.incrementQuantity(
                                          authProvider.userId!,
                                          widget.product.id,
                                        );
                                      }
                                    },
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(10),
                                      bottomRight: Radius.circular(10),
                                    ),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      alignment: Alignment.center,
                                      child: Icon(
                                        Icons.add,
                                        size: 16,
                                        color: Colors.deepPurple.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
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

class _AnimatedFavoriteButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedFavoriteButton({required this.onPressed});

  @override
  State<_AnimatedFavoriteButton> createState() =>
      _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState extends State<_AnimatedFavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red, size: 20),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(),
          onPressed: () {
            _controller.forward().then((_) {
              _controller.reverse();
              widget.onPressed();
            });
          },
        ),
      ),
    );
  }
}

class _AnimatedCartButton extends StatefulWidget {
  final VoidCallback onPressed;

  const _AnimatedCartButton({required this.onPressed});

  @override
  State<_AnimatedCartButton> createState() => _AnimatedCartButtonState();
}

class _AnimatedCartButtonState extends State<_AnimatedCartButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.8), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.2), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.deepPurple.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          onTap: () {
            _controller.forward().then((_) {
              _controller.reverse();
              widget.onPressed();
            });
          },
          child: const Icon(
            Icons.shopping_cart_outlined,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}
