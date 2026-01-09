// 🛒 services/cart_provider.dart
import 'dart:developer';
import 'package:demo/models/get_cart_item_model.dart';
import 'package:demo/services/api_service.dart';
import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  Map<int, GetCartItemMode> _cartItems = {}; // productId -> GetCartItemMode
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  
  // Get all cart items as list
  List<GetCartItemMode> get cartItems => _cartItems.values.toList();
  
  // Get quantity for a specific product
  int getQuantity(int productId) {
    return _cartItems[productId]?.quantity ?? 0;
  }

  // Get cart ID for a specific product
  int? getCartId(int productId) {
    return _cartItems[productId]?.cartId;
  }

  // Check if product is in cart
  bool isInCart(int productId) {
    return _cartItems.containsKey(productId);
  }

  // Get total items count
  int get totalItems {
    return _cartItems.values.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get total price
  double get totalPrice {
    return _cartItems.values.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  // Load all cart items
  Future<void> loadCart(int userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 🔥 તમારી API service નો ઉપયોગ
      final cartItems = await ApiService.getCart(userId);
      
      _cartItems.clear();
      for (var item in cartItems) {
        _cartItems[item.productId] = item;
      }

      _isLoading = false;
      notifyListeners();
      log("✅ Cart loaded: ${_cartItems.length} items, Total: ₹${totalPrice.toInt()}");
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      log("❌ Error loading cart: $e");
    }
  }

  // Add product to cart
  Future<bool> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    try {
      // 🔥 API call to add to cart
      final cartId = await ApiService.addToCart(
        userId: userId,
        productId: productId,
        quantity: quantity,
      );

      // 🔄 Reload cart to get complete item details
      await loadCart(userId);

      log("✅ Added to cart: Product $productId (CartID: $cartId)");
      return true;
    } catch (e) {
      log("❌ Error adding to cart: $e");
      return false;
    }
  }

  // Update quantity
  Future<bool> updateQuantity({
    required int userId,
    required int productId,
    required int newQuantity,
  }) async {
    final cartItem = _cartItems[productId];
    if (cartItem == null) return false;

    try {
      // If quantity is 0 or less, remove from cart
      if (newQuantity <= 0) {
        return await removeFromCart(userId, productId);
      }

      // 🔥 તમારી API service નો ઉપયોગ
      await ApiService.updateCartQuantity(
        cartId: cartItem.cartId,
        quantity: newQuantity,
      );

      // Update local state
      _cartItems[productId] = GetCartItemMode(
        cartId: cartItem.cartId,
        productId: cartItem.productId,
        title: cartItem.title,
        subtitle: cartItem.subtitle,
        price: cartItem.price,
        // oldPrice: cartItem.oldPrice,
        image: cartItem.image,
        quantity: newQuantity, userID: cartItem.userID,
      );

      notifyListeners();
      log("✅ Updated quantity: Product $productId -> $newQuantity");
      return true;
    } catch (e) {
      log("❌ Error updating quantity: $e");
      return false;
    }
  }

  // Increment quantity
  Future<bool> incrementQuantity(int userId, int productId) async {
    final currentQty = getQuantity(productId);
    return await updateQuantity(
      userId: userId,
      productId: productId,
      newQuantity: currentQty + 1,
    );
  }

  // Decrement quantity
  Future<bool> decrementQuantity(int userId, int productId) async {
    final currentQty = getQuantity(productId);
    if (currentQty <= 1) {
      // જો quantity 1 છે અને - દબાવો, તો item remove થઈ જશે
      return await removeFromCart(userId, productId);
    }
    return await updateQuantity(
      userId: userId,
      productId: productId,
      newQuantity: currentQty - 1,
    );
  }

  // Remove from cart
  Future<bool> removeFromCart(int userId, int productId) async {
    final cartItem = _cartItems[productId];
    if (cartItem == null) return false;

    try {
      // 🔥 તમારી API service નો ઉપયોગ
      await ApiService.removeFromCart(cartItem.cartId);
      
      _cartItems.remove(productId);
      notifyListeners();
      log("✅ Removed from cart: Product $productId");
      return true;
    } catch (e) {
      log("❌ Error removing from cart: $e");
      return false;
    }
  }

  // Clear all cart (optional)
  // Future<void> clearCart(int userId) async {
  //   try {
  //     // Remove all items one by one
  //     final itemsToRemove = List<int>.from(_cartItems.keys);
  //     for (var productId in itemsToRemove) {
  //       await removeFromCart(userId, productId);
  //     }
  //     log("🗑️ Cart cleared");
  //   } catch (e) {
  //     log("❌ Error clearing cart: $e");
  //   }
  // }

  // Get cart item by product ID
  GetCartItemMode? getCartItem(int productId) {
    return _cartItems[productId];
  }

  // cart_provider.dart માં આ method ઉમેરો
// Clear all cart
Future<void> clearCart(int userId) async {
  try {
    _isLoading = true;
    notifyListeners();

    // 🔥 Backend API call
    await ApiService.clearCart(userId);
    
    // Local state પણ clear કરો
    _cartItems.clear();
    
    _isLoading = false;
    notifyListeners();
    
    log("✅ Cart cleared successfully");
  } catch (e) {
    log("❌ Error clearing cart: $e");
    _isLoading = false;
    notifyListeners();
  }
}

}
