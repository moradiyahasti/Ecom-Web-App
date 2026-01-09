import 'dart:developer';
import 'package:demo/models/product_model.dart';
import 'package:demo/services/api_service.dart';
import 'package:flutter/material.dart';

class FavoritesProvider with ChangeNotifier {
  List<Product> favorites = [];
  bool isLoading = false;

  Future<void> loadFavorites(int userId) async {
    isLoading = true;
    notifyListeners();

    try {
      log("🔄 Loading favorites for user: $userId");
      favorites = await ApiService.getFavorites(userId);
      log("✅ Loaded ${favorites.length} favorites");
      
      // Debug: Print all favorite IDs
      for (var fav in favorites) {
        log("❤️ Favorite ID: ${fav.id}, Title: ${fav.title}");
      }
    } catch (e) {
      log("❌ Error loading favorites: $e");
      favorites = [];
    }

    isLoading = false;
    notifyListeners();
  }

  bool isFavorite(int productId) {
    final result = favorites.any((p) => p.id == productId);
    log("🔍 Checking isFavorite for $productId: $result");
    return result;
  }

  Future<void> toggleFavorite(int userId, Product product) async {
    try {
      log("🔄 Toggling favorite for product ID: ${product.id}");
      
      final isFav = await ApiService.toggleFavorite(
        userId: userId,
        productId: product.id,
      );

      log("📡 API Response - isFavorite: $isFav");

      if (isFav) {
        // Check if already exists to avoid duplicates
        if (!favorites.any((p) => p.id == product.id)) {
          favorites.add(product);
          log("❤️ Added to favorites: ${product.id}");
        } else {
          log("⚠️ Product ${product.id} already in favorites");
        }
      } else {
        favorites.removeWhere((p) => p.id == product.id);
        log("💔 Removed from favorites: ${product.id}");
      }

      log("📋 Current favorites count: ${favorites.length}");
      log("📋 Current favorite IDs: ${favorites.map((p) => p.id).toList()}");

      notifyListeners();
    } catch (e) {
      log("❌ Error toggling favorite: $e");
    }
  }

  // Optional: Clear favorites (for logout)
  void clearFavorites() {
    favorites.clear();
    notifyListeners();
  }
}




