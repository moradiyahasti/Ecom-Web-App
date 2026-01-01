import 'package:flutter/material.dart';
import '../models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get cartCount => _items.length;

  double get totalAmount {
    double total = 0;
    _items.forEach((key, item) {
      total += item.totalPrice;
    });
    return total;
  }

  void addToCart(Product product) {
    if (_items.containsKey(product.title)) {
      _items[product.title]!.quantity++;
    } else {
      _items[product.title] = CartItem(product: product);
    }
    notifyListeners();
  }

  void removeFromCart(String name) {
    _items.remove(name);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
