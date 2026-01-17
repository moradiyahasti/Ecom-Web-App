import 'package:demo/data/models/product_model.dart';
import 'package:demo/data/services/api_service.dart';
import 'package:flutter/foundation.dart';

class FavoritesProvider with ChangeNotifier {
  final Set<int> _favoriteIds = {};
  List<Product> _favorites = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  Set<int> get favoriteIds => _favoriteIds;
  List<Product> get favorites => _favorites;

  /// 🔥 CHECK if product is favorite
  bool isFavorite(int productId) {
    return _favoriteIds.contains(productId);
  }

  /// 🔥 LOAD favorites from API
  Future<void> loadFavorites(int userId) async {
    try {
      debugPrint("🔄 Loading favorites for user: $userId");

      _isLoading = true;
      notifyListeners();

      // 🔥 API માંથી actual products લો
      final products = await ApiService.getFavorites(userId);

      // 🔥 બંને update કરો - IDs અને Products
      _favoriteIds.clear();
      _favoriteIds.addAll(products.map((p) => p.id));

      _favorites = products;

      debugPrint(
        "✅ Favorites loaded: ${_favorites.length} items for user $userId",
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error loading favorites: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔥 TOGGLE favorite
  Future<void> toggleFavorite(
    int userId,
    Product? product, {
    int? productId,
  }) async {
    // 🔥 Determine the actual productId
    final id = product?.id ?? productId;

    if (id == null) {
      debugPrint("❌ Error: No productId provided");
      return;
    }

    debugPrint("🔄 Toggling favorite - User: $userId, Product: $id");

    try {
      // 🔥 OPTIMISTIC UPDATE
      final wasInFavorites = _favoriteIds.contains(id);

      if (wasInFavorites) {
        _favoriteIds.remove(id);
        _favorites.removeWhere((p) => p.id == id);
        debugPrint("🗑️ Removed from favorites (optimistic): Product $id");
      } else {
        _favoriteIds.add(id);
        if (product != null && !_favorites.any((p) => p.id == product.id)) {
          _favorites.add(product);
        }
        debugPrint("💖 Added to favorites (optimistic): Product $id");
      }
      notifyListeners();

      // 🔥 API call
      final isFavorite = await ApiService.toggleFavorite(
        userId: userId,
        productId: id,
      );

      // 🔥 VERIFY - API response સાથે sync કરો
      if (isFavorite) {
        if (!_favoriteIds.contains(id)) {
          _favoriteIds.add(id);
          if (product != null && !_favorites.any((p) => p.id == product.id)) {
            _favorites.add(product);
          }
        }
        debugPrint("✅ Favorite confirmed: Product $id");
      } else {
        _favoriteIds.remove(id);
        _favorites.removeWhere((p) => p.id == id);
        debugPrint("✅ Unfavorite confirmed: Product $id");
      }

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error toggling favorite: $e");

      // 🔥 ROLLBACK on error
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
        _favorites.removeWhere((p) => p.id == id);
      } else {
        _favoriteIds.add(id);
        if (product != null && !_favorites.any((p) => p.id == product.id)) {
          _favorites.add(product);
        }
      }
      notifyListeners();
    }
  }

  /// 🔥 CLEAR all favorites (called on logout)
  void clearFavorites() {
    debugPrint("🗑️ Clearing all favorites");
    _favoriteIds.clear();
    _favorites.clear();
    _isLoading = false;
    notifyListeners();
  }

  /// 🔥 GET favorite count
  int get favoritesCount => _favorites.length;
}
