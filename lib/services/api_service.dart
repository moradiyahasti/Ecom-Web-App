  import 'dart:convert';
  import 'dart:developer';
  import 'package:demo/models/get_cart_item_model.dart';
  import 'package:flutter/foundation.dart';
  import 'package:http/http.dart' as http;
  import 'package:url_launcher/url_launcher.dart';

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

      // 🔹 LOG RAW RESPONSE cg
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

    // static Future<bool> updateProfile({
    //   required String token,
    //   required String name,
    //   required String email,
    // }) async {
    //   final url = Uri.parse("$baseUrl/auth/update-profile");

    //   // 🔍 LOG REQUEST DATA
    //   debugPrint("➡️ UPDATE PROFILE URL: $url");
    //   debugPrint("➡️ TOKEN: $token");
    //   debugPrint(
    //     "➡️ HEADERS: "
    //     "Content-Type=application/json, "
    //     "Authorization=Bearer $token",
    //   );
    //   debugPrint("➡️ BODY: ${jsonEncode({"name": name, "email": email})}");

    //   final res = await http.put(
    //     url,
    //     headers: {
    //       "Content-Type": "application/json",
    //       "Authorization": "Bearer $token",
    //     },
    //     body: jsonEncode({"name": name, "email": email}),
    //   );

    //   // 🔁 LOG RESPONSE DATA
    //   debugPrint("⬅️ UPDATE PROFILE STATUS: ${res.statusCode}");
    //   debugPrint("⬅️ RESPONSE BODY: ${res.body}");

    //   return res.statusCode == 200;
    // }

    static Future<Map<String, dynamic>?> updateProfile({
      required String token,
      required String name,
      required String email,
    }) async {
      final url = Uri.parse("$baseUrl/auth/update-profile");

      final res = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"name": name, "email": email}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['user']; // ✅ updated user
      } else {
        return null;
      }
    }

    static Future<bool> changePassword({
      required String oldPassword,
      required String newPassword,
      required String token,
    }) async {
      try {
        // final token = await TokenService.getToken();
        if (token == null) return false;

        final url = Uri.parse("$baseUrl/auth/change-password");

        final response = await http.put(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({
            "oldPassword": oldPassword,
            "newPassword": newPassword,
          }),
        );

        if (response.statusCode == 200) {
          // Password changed successfully
          return true;
        } else {
          // Error message from backend
          log("Change password failed: ${response.body}");
          return false;
        }
      } catch (e) {
        log("Exception in changePassword: $e");
        return false;
      }
    }

    static Future<int?> saveAddress({
      required int userId,
      required String name,
      required String mobile,
      required String addressLine,
      required String city,
      required String state,
      required String pincode,
    }) async {
      final url = Uri.parse("$baseUrl/api/address/add");

      final body = {
        "user_id": userId,
        "name": name,
        "mobile": mobile,
        "address_line": addressLine,
        "city": city,
        "state": state,
        "pincode": pincode,
      };

      log("➡️ SAVE ADDRESS URL: $url");
      log("➡️ BODY: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      log("⬅️ STATUS: ${response.statusCode}");
      log("⬅️ RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["address_id"];
      } else {
        log("❌ Address save failed");
        return null;
      }
    }
    // ========================= PAYMENT =========================

    static Future<bool> createTransaction({
      required int orderId,
      required String transactionRef,
      required double amount,
      required String status,
    }) async {
      final url = Uri.parse("$baseUrl/api/payment/transaction/create");

      final body = {
        "order_id": orderId,
        "transaction_ref": transactionRef,
        "amount": amount,
        "status": status,
        "payment_method": "UPI",
      };

      log("➡️ CREATE TRANSACTION URL: $url");
      log("➡️ BODY: ${jsonEncode(body)}");

      try {
        final response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
          body: jsonEncode(body),
        );

        log("⬅️ STATUS: ${response.statusCode}");
        log("⬅️ RESPONSE: ${response.body}");

        return response.statusCode == 200 || response.statusCode == 201;
      } catch (e) {
        log("❌ CREATE TRANSACTION ERROR: $e");
        return false;
      }
    }

    // ✅ Update transaction status
    static Future<bool> updateTransaction({
      required String transactionRef,
      required String status,
      required String upiResponse,
    }) async {
      final url = Uri.parse("$baseUrl/api/payment/transaction/update");

      final body = {
        "transaction_ref": transactionRef,
        "status": status,
        "upi_response": upiResponse,
      };

      log("➡️ UPDATE TRANSACTION URL: $url");
      log("➡️ BODY: ${jsonEncode(body)}");

      try {
        final response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );

        log("⬅️ STATUS: ${response.statusCode}");
        log("⬅️ RESPONSE: ${response.body}");

        return response.statusCode == 200;
      } catch (e) {
        log("❌ UPDATE TRANSACTION ERROR: $e");
        return false;
      }
    }

    // ✅ Confirm payment (updated)
    static Future<bool> confirmPayment({
      required int orderId,
      required String transactionRef,
      required String paymentMethod,
    }) async {
      final url = Uri.parse("$baseUrl/api/payment/success");

      final body = {
        "order_id": orderId,
        "transaction_ref": transactionRef,
        "payment_method": paymentMethod,
      };

      log("➡️ PAYMENT CONFIRM URL: $url");
      log("➡️ BODY: ${jsonEncode(body)}");

      try {
        final response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(body),
        );

        log("⬅️ STATUS: ${response.statusCode}");
        log("⬅️ RESPONSE: ${response.body}");

        return response.statusCode == 200;
      } catch (e) {
        log("❌ CONFIRM PAYMENT ERROR: $e");
        return false;
      }
    }
    // ========================= ORDERS =========================

    static Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
      final url = Uri.parse("$baseUrl/api/orders/$orderId");

      log("➡️ GET ORDER DETAILS URL: $url");

      final res = await http.get(
        url,
        headers: {"Content-Type": "application/json"},
      );

      log("⬅️ STATUS: ${res.statusCode}");
      log("⬅️ BODY: ${res.body}");

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Failed to load order details");
      }
    }

    // ========================= CART CLEAR =========================

    /// 🗑️ CLEAR ENTIRE CART
    static Future<void> clearCart(int userId) async {
      final url = Uri.parse("$baseUrl/api/cart/clear/$userId");

      log("➡️ CLEAR CART URL: $url");

      final res = await http.delete(url);

      log("⬅️ CLEAR CART STATUS: ${res.statusCode}");
      log("⬅️ CLEAR CART RESPONSE: ${res.body}");

      if (res.statusCode != 200) {
        throw Exception("Failed to clear cart");
      }
    }

    Future<void> openUpiWeb() async {
      final upiUrl =
          'upi://pay?pa=sawan00meena@ucobank&pn=Test%20Merchant&am=1&cu=INR';

      final uri = Uri.parse(upiUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch UPI';
      }
    }
  }
