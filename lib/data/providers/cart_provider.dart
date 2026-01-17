
import 'dart:developer';
import 'package:demo/data/models/get_cart_item_model.dart';
import 'package:demo/data/services/api_service.dart';
import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  Map<int, GetCartItemMode> _cartItems = {}; 
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

  /// 🔥 LOAD cart from API
  Future<void> loadCart(int userId) async {
    try {
      log("🔄 Loading cart for user: $userId");
      
      _isLoading = true;
      notifyListeners();

      final cartItems = await ApiService.getCart(userId);
      
      _cartItems.clear();
      for (var item in cartItems) {
        _cartItems[item.productId] = item;
      }

      log("✅ Cart loaded: ${_cartItems.length} items, Total: ₹${totalPrice.toInt()} for user $userId");
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      log("❌ Error loading cart: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔥 ADD to cart
  Future<bool> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    try {
      log("🔄 Adding to cart - User: $userId, Product: $productId");
      
      final cartId = await ApiService.addToCart(
        userId: userId,
        productId: productId,
        quantity: quantity,
      );

      // Reload cart to get complete item details
      await loadCart(userId);

      log("✅ Added to cart: Product $productId (CartID: $cartId)");
      return true;
    } catch (e) {
      log("❌ Error adding to cart: $e");
      return false;
    }
  }

  /// 🔥 UPDATE quantity
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

      log("🔄 Updating quantity - User: $userId, Product: $productId, Qty: $newQuantity");

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
        image: cartItem.image,
        quantity: newQuantity,
        userID: cartItem.userID,
      );

      notifyListeners();
      log("✅ Updated quantity: Product $productId -> $newQuantity");
      return true;
    } catch (e) {
      log("❌ Error updating quantity: $e");
      return false;
    }
  }

  /// 🔥 INCREMENT quantity
  Future<bool> incrementQuantity(int userId, int productId) async {
    final currentQty = getQuantity(productId);
    return await updateQuantity(
      userId: userId,
      productId: productId,
      newQuantity: currentQty + 1,
    );
  }

  /// 🔥 DECREMENT quantity
  Future<bool> decrementQuantity(int userId, int productId) async {
    final currentQty = getQuantity(productId);
    if (currentQty <= 1) {
      return await removeFromCart(userId, productId);
    }
    return await updateQuantity(
      userId: userId,
      productId: productId,
      newQuantity: currentQty - 1,
    );
  }

  /// 🔥 REMOVE from cart
  Future<bool> removeFromCart(int userId, int productId) async {
    final cartItem = _cartItems[productId];
    if (cartItem == null) return false;

    try {
      log("🔄 Removing from cart - User: $userId, Product: $productId");
      
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

  /// 🔥 CLEAR cart (called on logout or after order)
  Future<void> clearCart(int userId) async {
    try {
      log("🔄 Clearing cart for user: $userId");
      
      _isLoading = true;
      notifyListeners();

      await ApiService.clearCart(userId);
      
      _cartItems.clear();
      
      _isLoading = false;
      notifyListeners();
      
      log("✅ Cart cleared successfully for user $userId");
    } catch (e) {
      log("❌ Error clearing cart: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔥 CLEAR LOCAL CART (called on logout - no API call)
  void clearLocalCart() {
    log("🗑️ Clearing local cart data");
    _cartItems.clear();
    _isLoading = false;
    notifyListeners();
  }

  /// Get cart item by product ID
  GetCartItemMode? getCartItem(int productId) {
    return _cartItems[productId];
  }
}
