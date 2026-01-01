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
      favorites = await ApiService.getFavorites(userId);
    } catch (e) {
      favorites = [];
    }

    isLoading = false;
    notifyListeners();
  }

  bool isFavorite(int productId) {
    return favorites.any((p) => p.id == productId);
  }

  Future<void> toggleFavorite(int userId, Product product) async {
    final isFav = await ApiService.toggleFavorite(
      userId: userId,
      productId: product.id,
    );

    if (isFav) {
      favorites.add(product);
    } else {
      favorites.removeWhere((p) => p.id == product.id);
    }

    notifyListeners();
  }
}
