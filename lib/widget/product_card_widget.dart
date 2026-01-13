import 'package:demo/data/models/product_model.dart';
import 'package:demo/presentation/screens/product/product_details_screen.dart';
import 'package:demo/data/providers/cart_provider.dart';
import 'package:demo/data/services/provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({required this.product, super.key});

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
       
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EnhancedNailProductDetails(
              productId: product.id, // 🔥 IMPORTANT - આ add કરવું જરૂરી છે

              title: product.title,
              mainImage: product.image,
              productImages: product.productImages.isNotEmpty
                  ? product.productImages
                  : [
                      product.image,
                      product.image,
                      product.image,
                      product.image,
                    ],
              oldPrice: product.oldPrice,
              review: product.reviews,
              price: product.price,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // IMAGE + TAG + FAVORITE
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                    child: Image.network(
                      product.image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _tag(product.isTrending),
                  ),
                  Positioned(top: 10, right: 10, child: _favoriteIcon(context)),
                ],
              ),
            ),

            // CONTENT
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.red),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${product.reviews} Reviews",
                        style: GoogleFonts.poppins(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.pink.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "FREE SHIPPING ABOVE ₹799",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontSize: 9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _priceAndCart(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _favoriteIcon(BuildContext context) {
    final favProvider = context.watch<FavoritesProvider>();
    final isFav = favProvider.isFavorite(product.id);

    return InkWell(
      onTap: () async {
        await context.read<FavoritesProvider>().toggleFavorite(1, product);
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: isFav ? Colors.red : Colors.grey.shade600,
        ),
      ),
    );
  }

  // PRICE + CART LAYOUT
  Widget _priceAndCart(BuildContext context) {
    if (_isMobile(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "₹${product.price}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "₹${product.oldPrice}",
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
                "₹${product.price}",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "₹${product.oldPrice}",
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

  // CART BUTTON - 🔥 PROVIDER INTEGRATED
  Widget _cartButton(BuildContext context) {
    // 🔥 Watch કરો cart provider ને
    final cartProvider = context.watch<CartProvider>();
    final quantity = cartProvider.getQuantity(product.id);
    final isLoading = cartProvider.isLoading;

    // જો cart માં નથી, તો "Add to Cart" બતાવો
    if (quantity == 0) {
      return InkWell(
        onTap: isLoading
            ? null
            : () async {
                // 🔥 Provider દ્વારા add કરો
                await context.read<CartProvider>().addToCart(
                  userId: 1,
                  productId: product.id,
                  quantity: 1,
                );

                // ✅ Success message (optional)
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("${product.title} added to cart"),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isLoading ? Colors.grey : Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  "Add To Cart",
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
                ),
        ),
      );
    }

    // જો cart માં છે, તો quantity counter બતાવો
    return _qtyCounter(context, quantity);
  }

  // QTY COUNTER - 🔥 PROVIDER INTEGRATED
  Widget _qtyCounter(BuildContext context, int quantity) {
    final cartProvider = context.read<CartProvider>();

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 🔥 MINUS BUTTON
            InkWell(
              onTap: () async {
                await cartProvider.decrementQuantity(1, product.id);
              },
              child: const Icon(Icons.remove, size: 16),
            ),
            const SizedBox(width: 10),

            // QUANTITY TEXT
            Text(
              quantity.toString(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 10),

            // 🔥 PLUS BUTTON
            InkWell(
              onTap: () async {
                await cartProvider.incrementQuantity(1, product.id);
              },
              child: const Icon(Icons.add, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  // TRENDING TAG
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
}
