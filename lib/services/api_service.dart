import 'dart:convert';
import 'dart:developer';
import 'package:demo/models/get_cart_item_model.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/product_model.dart';

class ApiService {
  // 🔴 BASE URL
  // Web → localhost
  // Android Emulator → 10.0.2.2
  static const String baseUrl = "http://192.168.1.25:5000"; // office
  // static const String baseUrl = "http://192.168.0.105:5000"; // home

  static const headers = {"Content-Type": "application/json"};

  // ========================= AUTH =========================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/auth/register");
    final body = {"name": name, "email": email, "password": password};

    debugPrint("➡️ REGISTER URL: $url");
    debugPrint("➡️ BODY: ${jsonEncode(body)}");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    debugPrint("⬅️ STATUS: ${res.statusCode}");
    debugPrint("⬅️ RESPONSE: ${res.body}");

    return {"status": res.statusCode, "data": jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/auth/login");
    final body = {"email": email, "password": password};

    debugPrint("➡️ LOGIN URL: $url");
    debugPrint("➡️ BODY: ${jsonEncode(body)}");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    debugPrint("⬅️ STATUS: ${res.statusCode}");
    debugPrint("⬅️ RESPONSE: ${res.body}");

    return {"status": res.statusCode, "data": jsonDecode(res.body)};
  }

  // ========================= PRODUCTS =========================

  static Future<List<Product>> fetchProducts() async {
    final url = Uri.parse("$baseUrl/api/products");

    log("➡️ GET PRODUCTS URL: $url");

    final res = await http.get(url);

    log("⬅️PRODUCTS STATUS: ${res.statusCode}");
    log("⬅️PRODUCTS BODY: ${res.body}");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load products");
    }
  }

  static Future<List<Product>> fetchTrending() async {
    final url = Uri.parse("$baseUrl/api/products/trending");

    debugPrint("➡️ GET TRENDING URL: $url");

    final res = await http.get(url);

    debugPrint("⬅️ STATUS: ${res.statusCode}");
    debugPrint("⬅️ BODY: ${res.body}");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load trending products");
    }
  }

  static Future<Product> getProductById(int id) async {
    final url = Uri.parse("$baseUrl/api/products/$id");

    debugPrint("➡️ GET PRODUCT BY ID URL: $url");

    final res = await http.get(url);

    debugPrint("⬅️ STATUS: ${res.statusCode}");
    debugPrint("⬅️ BODY: ${res.body}");

    return Product.fromJson(jsonDecode(res.body));
  }

  static Future<List<Product>> searchProducts(String query) async {
    final url = Uri.parse("$baseUrl/api/products/search/$query");

    debugPrint("➡️ SEARCH URL: $url");

    final res = await http.get(url);

    debugPrint("⬅️ STATUS: ${res.statusCode}");
    debugPrint("⬅️ BODY: ${res.body}");

    final List data = jsonDecode(res.body);
    return data.map((e) => Product.fromJson(e)).toList();
  }

  // ========================= CART =========================

  /// ➕ ADD TO CART
  static Future<int> addToCart({
    required int userId,
    required int productId,
    int quantity = 1,
  }) async {
    final url = Uri.parse("$baseUrl/api/cart/add");

    final body = {
      "user_id": userId,
      "product_id": productId,
      "quantity": quantity,
    };

    // 🔹 LOG REQUEST
    debugPrint("➡️ ADD TO CART URL: $url");
    debugPrint("➡️ ADD TO CART BODY: ${jsonEncode(body)}");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    // 🔹 LOG RESPONSE STATUS
    debugPrint("⬅️ STATUS CODE: ${res.statusCode}");

    // 🔹 LOG RAW RESPONSE
    debugPrint("⬅️ RESPONSE BODY: ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      // 🔹 LOG PARSED DATA
      debugPrint("✅ PARSED DATA: $data");
      debugPrint("🆔 CART ID: ${data['cart']['id']}");

      return data['cart']['id']; // return cart_id
    } else {
      debugPrint("❌ ADD TO CART FAILED");
      throw Exception("Add to cart failed");
    }
  }



  static Future<List<GetCartItemMode>> getCart(int userId) async {
    final url = Uri.parse("$baseUrl/api/cart/$userId");

    // 🔹 LOG REQUEST
    log("➡️ GET CART URL: $url");

    final res = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    // 🔹 LOG STATUS
    log("⬅️ STATUS CODE: ${res.statusCode}");

    // 🔹 LOG RAW RESPONSE
    log("⬅️ RAW RESPONSE: ${res.body}");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      // 🔹 LOG PARSED JSON
      log("✅ PARSED JSON LIST: $data");

      final cartItems = data.map((e) => GetCartItemMode.fromJson(e)).toList();

      // 🔹 LOG MODEL DATA
      for (var item in cartItems) {
        log(
          "🛒 CartItem → "
          "cartId: ${item.cartId}, "
          "productId: ${item.productId}, "
          "title: ${item.title}, "
          "price: ${item.price}, "
          "qty: ${item.quantity}",
        );
      }

      return cartItems;
    } else {
      log("❌ FAILED TO LOAD CART");
      throw Exception("Failed to load cart");
    }
  }

  static Future<void> updateCartQuantity({
    required int cartId,
    required int quantity,
  }) async {
    final url = Uri.parse("$baseUrl/api/cart/update");

    final body = {"cart_id": cartId, "quantity": quantity};

    debugPrint("➡️ UPDATE CART: $body");

    final res = await http.put(url, headers: headers, body: jsonEncode(body));

    debugPrint("⬅️ STATUS: ${res.statusCode}");
    debugPrint("⬅️ RESPONSE: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Update quantity failed");
    }
  }

  /// ❌ REMOVE FROM CART
  static Future<void> removeFromCart(int cartId) async {
    final url = Uri.parse("$baseUrl/api/cart/remove/$cartId");

    debugPrint("➡️ REMOVE CART URL: $url");

    final res = await http.delete(url);

    debugPrint("⬅️ REMOVE CART STATUS: ${res.statusCode}");
    debugPrint("⬅️ REMOVE CART BODY: ${res.body}");
  }

  /// 🔁 UPDATE QTY
  static Future<void> updateQuantity({
    required int cartId,
    required int quantity,
  }) async {
    final url = Uri.parse("$baseUrl/api/cart/update");

    final body = {"cart_id": cartId, "quantity": quantity};

    debugPrint("➡️ UPDATE QTY URL: $url");
    debugPrint("➡️ BODY: ${jsonEncode(body)}");

    final res = await http.put(url, headers: headers, body: jsonEncode(body));

    debugPrint("⬅️ STATUS: ${res.statusCode}");
    debugPrint("⬅️ BODY: ${res.body}");
  }

  static Future<List<Product>> getFavorites(int userId) async {
    final url = Uri.parse("$baseUrl/api/favorites/$userId");

    debugPrint("➡️ GET FAVORITES URL: $url");

    final res = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    debugPrint("⬅️ STATUS: ${res.statusCode}");
    debugPrint("⬅️ BODY: ${res.body}");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load favorites");
    }
  }

  // ========================= FAVORITES =========================

  /// 🔁 TOGGLE FAVORITE
  /// Adds or removes product from favorites.
  /// Returns `true` if the product is now a favorite, `false` if removed.
  static Future<bool> toggleFavorite({
    required int userId,
    required int productId,
  }) async {
    final url = Uri.parse("$baseUrl/api/favorites/toggle");

    final body = {"user_id": userId, "product_id": productId};

    debugPrint("➡️ TOGGLE FAVORITE URL: $url");
    debugPrint("➡️ BODY: ${jsonEncode(body)}");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    debugPrint("⬅️ STATUS: ${res.statusCode}");
    debugPrint("⬅️ RESPONSE: ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      // ✅ CORRECT KEY
      return data['favorite'] == true;
    } else {
      throw Exception("Failed to toggle favorite");
    }
  }
}

