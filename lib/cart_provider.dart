// import 'package:demo/models/product_model.dart';
// import 'package:flutter/material.dart';

// class CartItem {
//   final Product product;
//   int quantity;

//   CartItem({required this.product, this.quantity = 1});

//   double get totalPrice => product.price * quantity;
// }

// class CartProvider extends ChangeNotifier {
//   final Map<String, CartItem> _cartItems = {};
//   final List<Product> _favoriteItems = [];

//   // Cart getters
//   Map<String, CartItem> get cartItems => _cartItems;
//   int get cartCount => _cartItems.length;
//   double get totalAmount {
//     double total = 0.0; 
//     _cartItems.forEach((key, cartItem) {
//       total += cartItem.totalPrice;
//     });
//     return total;
//   }

//   // Favorite getters
//   List<Product> get favoriteItems => _favoriteItems;
//   int get favoriteCount => _favoriteItems.length;

//   // Check if product is in cart
//   bool isInCart(String productName) {
//     return _cartItems.containsKey(productName);
//   }

//   // Check if product is favorite
//   bool isFavorite(String productName) {
//     return _favoriteItems.any((product) => product.title == productName);
//   }

//   // Add to cart
//   void addToCart(Product product) {
//     if (_cartItems.containsKey(product.title)) {
//       _cartItems[product.title]!.quantity++;
//     } else {
//       _cartItems[product.title] = CartItem(product: product);
//     }
//     notifyListeners();
//   }

//   // Remove from cart
//   void removeFromCart(String productName) {
//     _cartItems.remove(productName);
//     notifyListeners();
//   }

//   // Increase quantity
//   void increaseQuantity(String productName) {
//     if (_cartItems.containsKey(productName)) {
//       _cartItems[productName]!.quantity++;
//       notifyListeners();
//     }
//   }

//   // Decrease quantity
//   void decreaseQuantity(String productName) {
//     if (_cartItems.containsKey(productName)) {
//       if (_cartItems[productName]!.quantity > 1) {
//         _cartItems[productName]!.quantity--;
//       } else {
//         _cartItems.remove(productName);
//       }
//       notifyListeners();
//     }
//   }

//   // Toggle favorite
//   void toggleFavorite(Product product) {
//     if (isFavorite(product.title)) {
//       _favoriteItems.removeWhere((item) => item.title == product.title);
//     } else {
//       _favoriteItems.add(product);
//     }
//     notifyListeners();
//   }

//   // Clear cart
//   void clearCart() {
//     _cartItems.clear();
//     notifyListeners();
//   }
// }
