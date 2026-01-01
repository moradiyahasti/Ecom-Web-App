import 'package:demo/models/product_model.dart';
import 'package:demo/screens/product_details_screen.dart';
import 'package:demo/services/api_service.dart';
import 'package:demo/services/provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onFavoriteChanged;

  ProductCard({required this.product, this.onFavoriteChanged, Key? key})
    : super(key: key);
  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int quantity = 0;
  int? cartId;
  bool isAdding = false;
  late bool isFavorite;

  @override
  void initState() {
    super.initState();
  }

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
          MaterialPageRoute(builder: (_) => NailProductDetailsExactUI()),
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
                      widget.product.image,
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
                    child: _tag(widget.product.isTrending),
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
                    widget.product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.product.subtitle,
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
                        "${widget.product.reviews} Reviews",
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
    final isFav = favProvider.isFavorite(widget.product.id);

    return GestureDetector(
      onTap: () {
        context.read<FavoritesProvider>().toggleFavorite(1, widget.product);
        if (widget.onFavoriteChanged != null) {
          widget.onFavoriteChanged!(); // optional callback
        }
      },
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          size: 18,
          color: Colors.red,
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
          SizedBox(width: double.infinity, child: _cartButton()),
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
          _cartButton(),
        ],
      );
    }
  }

  // CART BUTTON
  Widget _cartButton() {
    if (quantity == 0) {
      return GestureDetector(
        onTap: () async {
          if (isAdding) return;
          setState(() => isAdding = true);

          final res = await ApiService.addToCart(
            userId: 1,
            productId: widget.product.id,
            quantity: 1,
          );

          if (!mounted) return;

          setState(() {
            quantity = 1;
            cartId = res;
            isAdding = false;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Add To Cart",
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
          ),
        ),
      );
    }
    return _qtyCounter();
  }

  // QTY COUNTER
  Widget _qtyCounter() {
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
            GestureDetector(
              onTap: () async {
                if (cartId == null || quantity <= 1) return;
                await ApiService.updateCartQuantity(
                  cartId: cartId!,
                  quantity: quantity - 1,
                );
                setState(() => quantity--);
              },
              child: const Icon(Icons.remove, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              quantity.toString(),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () async {
                if (cartId == null) return;
                await ApiService.updateCartQuantity(
                  cartId: cartId!,
                  quantity: quantity + 1,
                );
                setState(() => quantity++);
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
