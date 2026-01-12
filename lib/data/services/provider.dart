import 'package:demo/data/models/product_model.dart';
import 'package:demo/data/services/api_service.dart';
import 'package:flutter/foundation.dart';

class FavoritesProvider with ChangeNotifier {
  final Set<int> _favoriteIds = {};
  List<Product> _favorites = []; // 🔥 ADD THIS - Actual product list
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  Set<int> get favoriteIds => _favoriteIds;
  List<Product> get favorites => _favorites; // 🔥 ADD THIS GETTER

  /// 🔥 CHECK if product is favorite
  bool isFavorite(int productId) {
    return _favoriteIds.contains(productId);
  }

  /// 🔥 LOAD favorites from API
  Future<void> loadFavorites(int userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 🔥 API માંથી actual products લો
      final products = await ApiService.getFavorites(userId);
      
      // 🔥 બંને update કરો - IDs અને Products
      _favoriteIds.clear();
      _favoriteIds.addAll(products.map((p) => p.id));
      
      _favorites = products; // 🔥 Products પણ store કરો

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error loading favorites: $e");
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔥 TOGGLE favorite - accepts BOTH Product object AND productId
  /// આ function બે રીતે call કરી શકાય:
  /// 1. toggleFavorite(1, product) - જ્યારે Product object available હોય
  /// 2. toggleFavorite(1, null, productId: 123) - જ્યારે માત્ર productId હોય
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

    try {
      // 🔥 OPTIMISTIC UPDATE - પહેલા UI update કરો
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
        // 🔥 Product list માંથી પણ remove કરો
        _favorites.removeWhere((p) => p.id == id);
      } else {
        _favoriteIds.add(id);
        // 🔥 જો Product object available છે તો list માં add કરો
        if (product != null && !_favorites.any((p) => p.id == product.id)) {
          _favorites.add(product);
        }
      }
      notifyListeners();

      // 🔥 API call
      final isFavorite = await ApiService.toggleFavorite(
        userId: userId,
        productId: id,
      );

      // 🔥 VERIFY - API response સાથે sync કરો
      if (isFavorite) {
        _favoriteIds.add(id);
        // જો product object છે અને list માં નથી, તો add કરો
        if (product != null && !_favorites.any((p) => p.id == product.id)) {
          _favorites.add(product);
        }
      } else {
        _favoriteIds.remove(id);
        _favorites.removeWhere((p) => p.id == id);
      }

      notifyListeners();
    } catch (e) {
      debugPrint("❌ Error toggling favorite: $e");
      
      // 🔥 ROLLBACK - error થયો તો પાછું revert કરો
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

  /// 🔥 CLEAR all favorites (optional - જો reset button હોય)
  void clearFavorites() {
    _favoriteIds.clear();
    _favorites.clear();
    notifyListeners();
  }

  /// 🔥 GET favorite count (helper method)
  int get favoritesCount => _favorites.length;
}