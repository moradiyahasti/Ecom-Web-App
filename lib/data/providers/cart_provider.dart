import 'dart:developer';
import 'package:demo/data/models/get_cart_item_model.dart';
import 'package:demo/data/services/api_service.dart';
import 'package:demo/data/services/token_service.dart';
import 'package:flutter/material.dart';

class CartProvider extends ChangeNotifier {
  Map<int, GetCartItemMode> _cartItems = {}; 
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  
  // 🔥 Check SharedPreferences for payment flag
  Future<bool> get isPaymentInProgress async {
    return await TokenService.isPaymentInProgress();
  }
  
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

  // 🔥 Start payment flow - PERSISTS across app restarts
  Future<void> startPaymentFlow() async {
    print("═══════════════════════════════════════════");
    print("🔒 STARTING PAYMENT FLOW");
    print("═══════════════════════════════════════════");
    
    await TokenService.setPaymentInProgress(true);
    
    // 🔥 VERIFY it was set
    final verified = await TokenService.isPaymentInProgress();
    print("✅ Payment flow started - Flag verified: $verified");
    
    log("🔒 Payment flow started - automatic reloads BLOCKED (SAVED TO DISK)");
    notifyListeners();
  }
  
  // 🔥 End payment flow - PERSISTS across app restarts
  Future<void> endPaymentFlow() async {
    print("═══════════════════════════════════════════");
    print("🔓 ENDING PAYMENT FLOW");
    print("═══════════════════════════════════════════");
    
    await TokenService.setPaymentInProgress(false);
    
    // 🔥 VERIFY it was cleared
    final verified = await TokenService.isPaymentInProgress();
    print("✅ Payment flow ended - Flag verified: $verified");
    
    log("🔓 Payment flow ended - automatic reloads ALLOWED");
    notifyListeners();
  }

  /// 🔥 MODIFIED: Load cart from API with detailed logging
  Future<void> loadCart(int userId, {bool forceReload = false}) async {
    print("═══════════════════════════════════════════");
    print("📦 LOAD CART CALLED");
    print("User ID: $userId");
    print("Force Reload: $forceReload");
    print("Current items in cart: ${_cartItems.length}");
    print("───────────────────────────────────────────");
    
    // ✅ CHECK PERSISTENT FLAG (unless forceReload is true)
    if (!forceReload) {
      final paymentInProgress = await TokenService.isPaymentInProgress();
      
      print("🔍 Checking payment flag...");
      print("Payment in progress: $paymentInProgress");
      
      if (paymentInProgress) {
        print("⏸️ SKIPPED: Payment in progress");
        print("═══════════════════════════════════════════");
        log("⏸️ SKIPPED automatic cart reload - payment in progress");
        return;
      } else {
        print("✅ PROCEEDING: No payment in progress");
      }
    } else {
      print("🔄 FORCE RELOAD: Ignoring payment flag");
      log("🔄 FORCE RELOAD - ignoring payment flag (user action)");
    }
    
    try {
      log("🔄 Loading cart for user: $userId");
      
      _isLoading = true;
      notifyListeners();

      print("📡 Calling API to get cart...");
      final cartItems = await ApiService.getCart(userId);
      
      print("📦 API returned ${cartItems.length} items");
      
      _cartItems.clear();
      for (var item in cartItems) {
        _cartItems[item.productId] = item;
      }

      print("✅ Cart loaded successfully");
      print("Items in memory: ${_cartItems.length}");
      print("Total price: ₹${totalPrice.toInt()}");
      print("═══════════════════════════════════════════");
      
      log("✅ Cart loaded: ${_cartItems.length} items, Total: ₹${totalPrice.toInt()} for user $userId");
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print("❌ ERROR loading cart: $e");
      print("═══════════════════════════════════════════");
      log("❌ Error loading cart: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔥 ADD to cart - ALWAYS RELOADS (forceReload = true)
  Future<bool> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    try {
      print("═══════════════════════════════════════════");
      print("➕ ADD TO CART");
      print("User ID: $userId");
      print("Product ID: $productId");
      print("Quantity: $quantity");
      print("───────────────────────────────────────────");
      
      log("🔄 Adding to cart - User: $userId, Product: $productId");
      
      final cartId = await ApiService.addToCart(
        userId: userId,
        productId: productId,
        quantity: quantity,
      );

      print("✅ API call successful - Cart ID: $cartId");
      print("🔄 Now reloading cart with forceReload=true...");

      // 🔥 CRITICAL FIX: Force reload to get updated cart (ignore payment flag)
      await loadCart(userId, forceReload: true);

      print("✅ Add to cart complete");
      print("═══════════════════════════════════════════");
      
      log("✅ Added to cart: Product $productId (CartID: $cartId)");
      return true;
    } catch (e) {
      print("❌ ERROR adding to cart: $e");
      print("═══════════════════════════════════════════");
      log("❌ Error adding to cart: $e");
      return false;
    }
  }

  /// 🔥 UPDATE quantity - Updates local state immediately
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

      // 🔥 Update local state immediately (no API reload needed)
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

  /// 🔥 REMOVE from cart - Updates local state immediately
  Future<bool> removeFromCart(int userId, int productId) async {
    final cartItem = _cartItems[productId];
    if (cartItem == null) return false;

    try {
      log("🔄 Removing from cart - User: $userId, Product: $productId");
      
      await ApiService.removeFromCart(cartItem.cartId);
      
      // 🔥 Update local state immediately
      _cartItems.remove(productId);
      notifyListeners();
      log("✅ Removed from cart: Product $productId");
      return true;
    } catch (e) {
      log("❌ Error removing from cart: $e");
      return false;
    }
  }

  /// 🔥 CLEAR cart - ONLY CALL THIS AFTER SUCCESSFUL PAYMENT!
  Future<void> clearCart(int userId) async {
    try {
      print("═══════════════════════════════════════════════════");
      print("🚨🚨🚨 CLEAR CART CALLED! 🚨🚨🚨");
      print("User ID: $userId");
      print("Items in cart before clear: ${_cartItems.length}");
      print("Total price before clear: ₹${totalPrice.toInt()}");
      print("─────────────────────────────────────────────────");
      print("🔍 STACK TRACE (who called clearCart?):");
      print(StackTrace.current);
      print("═══════════════════════════════════════════════════");
      
      log("🔄 CLEARING CART for user: $userId");
      log("⚠️ WARNING: This will PERMANENTLY DELETE all cart items!");
      
      _isLoading = true;
      notifyListeners();

      // 🔥 CALL API TO DELETE CART ITEMS FROM DATABASE
      await ApiService.clearCart(userId);
      
      // 🔥 CLEAR LOCAL STATE
      _cartItems.clear();
      
      // 🔥 IMPORTANT: Clear payment flag after successful cart clear
      await TokenService.setPaymentInProgress(false);
      
      _isLoading = false;
      notifyListeners();
      
      log("✅ Cart cleared successfully for user $userId");
      print("✅ Cart is now empty - ${_cartItems.length} items remaining");
      
    } catch (e) {
      log("❌ Error clearing cart: $e");
      print("❌ Error clearing cart: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔥 CLEAR LOCAL CART ONLY (called on logout - no API call)
  Future<void> clearLocalCart() async {
    log("🗑️ Clearing local cart data (logout - NO API CALL)");
    print("🗑️ Clearing local cart - items before: ${_cartItems.length}");
    
    _cartItems.clear();
    _isLoading = false;
    
    // 🔥 IMPORTANT: Clear payment flag on logout
    await TokenService.setPaymentInProgress(false);
    
    notifyListeners();
    print("✅ Local cart cleared - items after: ${_cartItems.length}");
  }

  /// Get cart item by product ID
  GetCartItemMode? getCartItem(int productId) {
    return _cartItems[productId];
  }
}