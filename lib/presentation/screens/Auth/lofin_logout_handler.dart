import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:demo/data/providers/auth_provider.dart';
import 'package:demo/data/providers/cart_provider.dart';
import 'package:demo/data/services/provider.dart'; // FavoritesProvider

/// 🔑 LOGIN HANDLER
/// Call this function after successful login API response
Future<void> handleLogin({
  required BuildContext context,
  required int userId,
  required String userName,
  required String userEmail,
  required String token,
}) async {
  try {
    log("🔑 Starting login process for user: $userName (ID: $userId)");

    // 1️⃣ Save auth data using AuthProvider
    await context.read<AuthProvider>().login(
      userId: userId,
      name: userName,
      email: userEmail,
      token: token,
    );

    // 2️⃣ Load user's cart and favorites
    if (context.mounted) {
      log("📦 Loading user data...");

      // Load cart
      await context.read<CartProvider>().loadCart(userId);

      // Load favorites
      await context.read<FavoritesProvider>().loadFavorites(userId);

      log("✅ Login complete - User data loaded");
    }

   
  } catch (e) {
    log("❌ Error during login: $e");
    rethrow;
  }
}

/// 🚪 LOGOUT HANDLER
/// Call this function when user clicks logout
Future<void> handleLogout({
  required BuildContext context,
  bool navigateToLogin = true,
}) async {
  try {
    log("🚪 Starting logout process");

    // 1️⃣ Logout from AuthProvider (clears SharedPreferences)
    await context.read<AuthProvider>().logout();

    // 2️⃣ Clear cart and favorites data from memory
    if (context.mounted) {
      log("🗑️ Clearing user data...");

      // Clear cart
      context.read<CartProvider>().clearLocalCart();

      // Clear favorites
      context.read<FavoritesProvider>().clearFavorites();

      log("✅ Logout complete - All user data cleared");
    }

    // 3️⃣ Navigate to login screen (optional)
    if (navigateToLogin && context.mounted) {
     
    }
  } catch (e) {
    log("❌ Error during logout: $e");
    rethrow;
  }
}

