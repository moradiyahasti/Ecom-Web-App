import 'dart:convert';
import 'dart:developer';
import 'package:demo/data/models/get_cart_item_model.dart';
import 'package:demo/data/services/token_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/product_model.dart';

class ApiService {
  // 🔥 CORRECTED BASE URL - This should point to your public folder
  static const String baseUrl = "https://shreenails.com";

  static const headers = {"Content-Type": "application/json"};

  // ========================= AUTH =========================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/api/auth/register");
    final body = {"name": name, "email": email, "password": password};

    log("📤 REGISTER: $url");
    log("Body: ${jsonEncode(body)}");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    log("📥 Status: ${res.statusCode}");
    log("Response: ${res.body}");

    return {"status": res.statusCode, "data": jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/api/auth/login");
    final body = {"email": email, "password": password};

    log("📤 LOGIN: $url");
    log("Body: ${jsonEncode(body)}");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    log("📥 Status: ${res.statusCode}");
    log("Response: ${res.body}");

    return {"status": res.statusCode, "data": jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final url = Uri.parse("$baseUrl/api/auth/forgot-password");
    final body = {"email": email};

    log("📤 FORGOT PASSWORD: $url");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    log("📥 Status: ${res.statusCode}");

    return {"status": res.statusCode, "data": jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    final url = Uri.parse("$baseUrl/api/auth/verify-otp");
    final body = {"email": email, "otp": otp};

    log("📤 VERIFY OTP: $url");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    log("📥 Status: ${res.statusCode}");

    return {"status": res.statusCode, "data": jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final url = Uri.parse("$baseUrl/api/auth/reset-password");
    final body = {"email": email, "otp": otp, "newPassword": newPassword};

    log("📤 RESET PASSWORD: $url");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    log("📥 Status: ${res.statusCode}");

    return {"status": res.statusCode, "data": jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> resendOTP({required String email}) async {
    final url = Uri.parse("$baseUrl/api/auth/resend-otp");
    final body = {"email": email};

    log("📤 RESEND OTP: $url");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    log("📥 Status: ${res.statusCode}");

    return {"status": res.statusCode, "data": jsonDecode(res.body)};
  }

  static Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String token,
  }) async {
    try {
      if (token.isEmpty) return false;

      final url = Uri.parse("$baseUrl/api/auth/change-password");

      log("📤 CHANGE PASSWORD: $url");

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
        log("✅ Password changed successfully");
        return true;
      } else {
        log("❌ Change password failed: ${response.body}");
        return false;
      }
    } catch (e) {
      log("❌ Exception in changePassword: $e");
      return false;
    }
  }

  static Future<String?> refreshToken() async {
    try {
      final refreshToken = await TokenService.getRefreshToken();

      if (refreshToken == null) return null;

      final url = Uri.parse("$baseUrl/api/auth/refresh-token");
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"refreshToken": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];

        await TokenService.updateToken(newToken);

        log("✅ Token refreshed successfully");
        return newToken;
      }

      return null;
    } catch (e) {
      log("❌ Token refresh failed: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateProfile({
    required String token,
    required String name,
    required String email,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/api/auth/update-profile");

      log("📤 UPDATE PROFILE: $url");

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"name": name, "email": email}),
      );

      log("📥 Status: ${response.statusCode}");

      if (response.statusCode == 401) {
        log("Token expired, attempting refresh...");

        final newToken = await refreshToken();

        if (newToken != null) {
          final retryResponse = await http.put(
            url,
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $newToken",
            },
            body: jsonEncode({"name": name, "email": email}),
          );

          if (retryResponse.statusCode == 200) {
            final data = jsonDecode(retryResponse.body);
            if (data.containsKey('user')) {
              log("✅ Profile updated successfully (after refresh)");
              return data['user'];
            }
          }
        }

        return null;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('user')) {
          log("✅ Profile updated successfully");
          return data['user'];
        }
      }

      return null;
    } catch (e) {
      log("❌ Exception in updateProfile: $e");
      return null;
    }
  }

  // ========================= PRODUCTS =========================

  static Future<List<Product>> fetchProducts() async {
    final url = Uri.parse("$baseUrl/api/products");

    log("📤 GET PRODUCTS: $url");

    final res = await http.get(url);

    log("📥 Status: ${res.statusCode}");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load products");
    }
  }

  static Future<List<Product>> fetchTrending() async {
    final url = Uri.parse("$baseUrl/api/products/trending");

    log("📤 GET TRENDING: $url");

    final res = await http.get(url);

    log("📥 Status: ${res.statusCode}");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load trending products");
    }
  }

  static Future<Product> getProductById(int id) async {
    final url = Uri.parse("$baseUrl/api/products/$id");

    log("📤 GET PRODUCT BY ID: $url");

    final res = await http.get(url);

    log("📥 Status: ${res.statusCode}");

    return Product.fromJson(jsonDecode(res.body));
  }

  static Future<List<Product>> searchProducts(String query) async {
    final url = Uri.parse("$baseUrl/api/products/search/$query");

    log("📤 SEARCH PRODUCTS: $url");

    final res = await http.get(url);

    log("📥 Status: ${res.statusCode}");

    final List data = jsonDecode(res.body);
    return data.map((e) => Product.fromJson(e)).toList();
  }

  static Future<Product> getProductDetails({
    required int productId,
    int? userId,
  }) async {
    final url = userId != null
        ? Uri.parse("$baseUrl/api/products/$productId?user_id=$userId")
        : Uri.parse("$baseUrl/api/products/$productId");

    log("📤 GET PRODUCT DETAILS: $url");

    final res = await http.get(url);

    log("📥 Status: ${res.statusCode}");

    if (res.statusCode == 200) {
      return Product.fromJson(jsonDecode(res.body));
    } else {
      throw Exception("Failed to load product details");
    }
  }

  // ========================= CART =========================

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

    log("📤 ADD TO CART: $url");
    log("Body: ${jsonEncode(body)}");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    log("📥 Status: ${res.statusCode}");
    log("Response: ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      log("✅ Cart ID: ${data['cart']['id']}");
      return data['cart']['id'];
    } else {
      log("❌ Add to cart failed");
      throw Exception("Add to cart failed");
    }
  }

  static Future<List<GetCartItemMode>> getCart(int userId) async {
    final url = Uri.parse("$baseUrl/api/cart/$userId");

    log("📤 GET CART: $url");

    final res = await http.get(url, headers: headers);

    log("📥 Status: ${res.statusCode}");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => GetCartItemMode.fromJson(e)).toList();
    } else {
      log("❌ Failed to load cart");
      throw Exception("Failed to load cart");
    }
  }

  static Future<void> updateCartQuantity({
    required int cartId,
    required int quantity,
  }) async {
    final url = Uri.parse("$baseUrl/api/cart/update");

    final body = {"cart_id": cartId, "quantity": quantity};

    log("📤 UPDATE CART QUANTITY: $url");

    final res = await http.put(url, headers: headers, body: jsonEncode(body));

    log("📥 Status: ${res.statusCode}");

    if (res.statusCode != 200) {
      throw Exception("Update quantity failed");
    }
  }

  static Future<void> removeFromCart(int cartId) async {
    final url = Uri.parse("$baseUrl/api/cart/remove/$cartId");

    log("📤 REMOVE FROM CART: $url");

    final res = await http.delete(url);

    log("📥 Status: ${res.statusCode}");
  }

  static Future<void> updateQuantity({
    required int cartId,
    required int quantity,
  }) async {
    final url = Uri.parse("$baseUrl/api/cart/update");

    final body = {"cart_id": cartId, "quantity": quantity};

    log("📤 UPDATE QUANTITY: $url");

    final res = await http.put(url, headers: headers, body: jsonEncode(body));

    log("📥 Status: ${res.statusCode}");
  }

  // static Future<void> clearCart(int userId) async {
  //   final url = Uri.parse("$baseUrl/api/cart/clear/$userId");

  //   log("📤 CLEAR CART: $url");

  //   final res = await http.delete(url);

  //   log("📥 Status: ${res.statusCode}");

  //   if (res.statusCode != 200) {
  //     throw Exception("Failed to clear cart");
  //   }
  // }

  static Future<Map<String, dynamic>?> clearCart() async {
    try {
      final userId = await _getUserId();

      if (userId == null) {
        debugPrint("❌ User ID not found");
        return null;
      }

      debugPrint("🛒 Clearing cart for user: $userId");

      final response = await http.delete(
        Uri.parse('$baseUrl/api/cart/clear'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_id': userId}),
      );

      debugPrint("📥 Clear Cart Response: ${response.statusCode}");
      debugPrint("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint("✅ Cart cleared successfully");
        return data;
      } else {
        debugPrint("❌ Clear Cart Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Clear Cart Exception: $e");
      return null;
    }
  }

  // Helper to get user ID (if not already present)
  static Future<int?> _getUserId() async {
    try {
      // Get from SharedPreferences or your auth system
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt('user_id');
    } catch (e) {
      debugPrint("❌ Error getting user ID: $e");
      return null;
    }
  }

  // ========================= FAVORITES =========================

  static Future<List<Product>> getFavorites(int userId) async {
    final url = Uri.parse("$baseUrl/api/favorites/$userId");

    log("📤 GET FAVORITES: $url");

    final res = await http.get(url, headers: headers);

    log("📥 Status: ${res.statusCode}");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load favorites");
    }
  }

  static Future<bool> toggleFavorite({
    required int userId,
    required int productId,
  }) async {
    final url = Uri.parse("$baseUrl/api/favorites/toggle");

    final body = {"user_id": userId, "product_id": productId};

    log("📤 TOGGLE FAVORITE: $url");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    log("📥 Status: ${res.statusCode}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['favorite'] == true;
    } else {
      throw Exception("Failed to toggle favorite");
    }
  }

  // ========================= ADDRESS =========================

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

    log("📤 SAVE ADDRESS: $url");
    log("Body: ${jsonEncode(body)}");

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    log("📥 Status: ${response.statusCode}");
    log("Response: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      log("✅ Address saved with ID: ${data["address_id"]}");
      return data["address_id"];
    } else {
      log("❌ Address save failed");
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getUserAddress(int userId) async {
    final url = Uri.parse("$baseUrl/api/address/user/$userId");

    log("📤 GET USER ADDRESS: $url");

    try {
      final res = await http.get(url, headers: headers);

      log("📥 Status: ${res.statusCode}");
      log("Response: ${res.body}");

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(res.body);

        if (decoded is List && decoded.isNotEmpty) {
          log("✅ Got ${decoded.length} addresses, returning first");
          return decoded.first as Map<String, dynamic>;
        } else if (decoded is Map && decoded.containsKey('addresses')) {
          final addresses = decoded['addresses'] as List;
          log("Got wrapped response with ${addresses.length} addresses");
          return addresses.isNotEmpty ? addresses.first : null;
        } else if (decoded is List && decoded.isEmpty) {
          log("ℹ️ No addresses found");
          return null;
        } else {
          log("❌ Unexpected format: ${decoded.runtimeType}");
          return null;
        }
      } else {
        log("❌ Failed with status: ${res.statusCode}");
        return null;
      }
    } catch (e) {
      log("❌ GET USER ADDRESS ERROR: $e");
      return null;
    }
  }

  static Future<Map<String, dynamic>> addAddress({
    required int userId,
    required String name,
    required String mobile,
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
  }) async {
    final url = Uri.parse("$baseUrl/api/address/add");

    log("📤 ADD ADDRESS: $url");

    final body = jsonEncode({
      'user_id': userId,
      'name': name,
      'mobile': mobile,
      'address_line': addressLine,
      'city': city,
      'state': state,
      'pincode': pincode,
    });

    log("Body: $body");

    try {
      final res = await http.post(url, headers: headers, body: body);

      log("📥 Status: ${res.statusCode}");
      log("Response: ${res.body}");

      if (res.statusCode == 200 || res.statusCode == 201) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Failed to add address: ${res.statusCode}");
      }
    } catch (e) {
      log("❌ ADD ADDRESS ERROR: $e");
      rethrow;
    }
  }

  // ========================= PAYMENT =========================
  // 🔥 FIXED PAYMENT METHODS
  /* 
/*   static Future<bool> createTransaction({
    required int orderId,
    required String transactionRef,
    required double amount,
    required String status,
  }) async {
    try {
      log("══════════════════════════════════════════");
      log("📤 CREATE TRANSACTION");
      log("   Order ID: $orderId");
      log("   Transaction Ref: $transactionRef");
      log("   Amount: $amount");
      log("   Status: $status");
      log("══════════════════════════════════════════");

      final url = Uri.parse("$baseUrl/api/transactions/create");

      final body = {
        "order_id": orderId,
        "transaction_ref": transactionRef,
        "amount": amount,
        "status": status,
        "payment_method": "UPI",
      };

      log("URL: $url");
      log("Body: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      log("📥 Response Status: ${response.statusCode}");
      log("📥 Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("✅ Transaction created successfully");
        log("══════════════════════════════════════════");
        return true;
      } else {
        log("❌ Create transaction failed");
        log("══════════════════════════════════════════");
        return false;
      }
    } catch (e, stackTrace) {
      log("❌ CREATE TRANSACTION ERROR: $e");
      log("Stack trace: $stackTrace");
      log("══════════════════════════════════════════");
      return false;
    }
  }
 */
  static Future<String> getTransactionStatus(String transactionRef) async {
    try {
      log("══════════════════════════════════════════");
      log("📤 GET TRANSACTION STATUS");
      log("   Transaction Ref: $transactionRef");
      log("══════════════════════════════════════════");

      final url = Uri.parse('$baseUrl/api/transactions/$transactionRef/status');

      log("URL: $url");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      log("📥 Response Status: ${response.statusCode}");
      log("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'] as String;

        log("✅ Transaction status: \"$status\"");
        log("══════════════════════════════════════════");

        return status;
      } else if (response.statusCode == 404) {
        log("⚠️ Transaction not found");
        log("══════════════════════════════════════════");
        return 'pending';
      } else {
        log("❌ Failed to get transaction status");
        log("══════════════════════════════════════════");
        return 'pending';
      }
    } catch (e, stackTrace) {
      log("❌ GET TRANSACTION STATUS ERROR: $e");
      log("Stack trace: $stackTrace");
      log("══════════════════════════════════════════");
      return 'pending';
    }
  }

  static Future<bool> updateTransaction({
    required String transactionRef,
    required String status,
    required String upiResponse,
  }) async {
    try {
      log("══════════════════════════════════════════");
      log("📤 UPDATE TRANSACTION");
      log("   Transaction Ref: $transactionRef");
      log("   New Status: $status");
      log("   UPI Response: $upiResponse");
      log("══════════════════════════════════════════");

      final url = Uri.parse("$baseUrl/api/transactions/update");

      final body = {
        "transaction_ref": transactionRef,
        "status": status,
        "upi_response": upiResponse,
      };

      log("URL: $url");
      log("Body: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      log("📥 Response Status: ${response.statusCode}");
      log("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        log("✅ Transaction updated successfully");
        log("══════════════════════════════════════════");
        return true;
      } else {
        log("❌ Update transaction failed");
        log("══════════════════════════════════════════");
        return false;
      }
    } catch (e, stackTrace) {
      log("❌ UPDATE TRANSACTION ERROR: $e");
      log("Stack trace: $stackTrace");
      log("══════════════════════════════════════════");
      return false;
    }
  }

  static Future<bool> confirmPayment({
    required int orderId,
    required String transactionRef,
    required String paymentMethod,
  }) async {
    try {
      log("══════════════════════════════════════════");
      log("📤 CONFIRM PAYMENT");
      log("   Order ID: $orderId");
      log("   Transaction Ref: $transactionRef");
      log("   Payment Method: $paymentMethod");
      log("══════════════════════════════════════════");

      final url = Uri.parse("$baseUrl/api/transactions/success");

      final body = {
        "order_id": orderId,
        "transaction_ref": transactionRef,
        "payment_method": paymentMethod,
      };

      log("URL: $url");
      log("Body: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      log("📥 Response Status: ${response.statusCode}");
      log("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        log("✅ Payment confirmed successfully");
        log("══════════════════════════════════════════");
        return true;
      } else {
        log("❌ Confirm payment failed");
        log("══════════════════════════════════════════");
        return false;
      }
    } catch (e, stackTrace) {
      log("❌ CONFIRM PAYMENT ERROR: $e");
      log("Stack trace: $stackTrace");
      log("══════════════════════════════════════════");
      return false;
    }
  }
 */
  // ========================= ORDERS =========================

  static Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    final url = Uri.parse("$baseUrl/api/orders/$orderId");

    log("📤 GET ORDER DETAILS: $url");

    final res = await http.get(url, headers: headers);

    log("📥 Status: ${res.statusCode}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load order details");
    }
  }

  static Future<List<Map<String, dynamic>>> getUserOrders(int userId) async {
    final url = Uri.parse("$baseUrl/api/orders/user/$userId");

    log("📤 GET USER ORDERS: $url");

    try {
      final res = await http.get(url, headers: headers);

      log("📥 Status: ${res.statusCode}");
      log("Response: ${res.body}");

      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(res.body);

        if (decoded is List) {
          log("✅ Got ${decoded.length} orders");
          return decoded.cast<Map<String, dynamic>>();
        } else if (decoded is Map && decoded.containsKey('orders')) {
          log("Got wrapped response");
          return (decoded['orders'] as List).cast<Map<String, dynamic>>();
        } else {
          log("❌ Unexpected response format");
          throw Exception("Unexpected response format");
        }
      } else {
        log("❌ Failed with status: ${res.statusCode}");
        throw Exception("Failed to load user orders: ${res.statusCode}");
      }
    } catch (e) {
      log("❌ GET USER ORDERS ERROR: $e");
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createOrder({
    required int userId,
    required int addressId,
    required double subtotal,
    required double tax,
    required double shipping,
    required double discount,
    required double total,
    required List<Map<String, dynamic>> items,
  }) async {
    final url = Uri.parse("$baseUrl/api/orders/create");

    log("📤 CREATE ORDER: $url");

    final body = jsonEncode({
      'user_id': userId,
      'address_id': addressId,
      'subtotal': subtotal,
      'tax': tax,
      'shipping': shipping,
      'discount': discount,
      'total': total,
      'items': items,
    });

    log("Body: $body");

    try {
      final res = await http.post(url, headers: headers, body: body);

      log("📥 Status: ${res.statusCode}");
      log("Response: ${res.body}");

      if (res.statusCode == 201 || res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Failed to create order: ${res.statusCode}");
      }
    } catch (e) {
      log("❌ CREATE ORDER ERROR: $e");
      rethrow;
    }
  }

  // ========================= UPI =========================

  Future<void> openUpiWeb() async {
    final upiUrl =
        'upi://pay?pa=sawan00meena@ucobank&pn=Test%20Merchant&am=1&cu=INR';

    final uri = Uri.parse(upiUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      log('❌ Could not launch UPI');
      throw 'Could not launch UPI';
    }
  }
  // ========================= RAZORPAY PAYMENT =========================

  static Future<Map<String, dynamic>?> createRazorpayOrder({
    required int orderId,
    required String transactionRef,
    required double amount,
  }) async {
    try {
      log("══════════════════════════════════════════");
      log("📤 CREATE RAZORPAY ORDER");
      log("   Order ID: $orderId");
      log("   Transaction Ref: $transactionRef");
      log("   Amount: $amount");
      log("══════════════════════════════════════════");

      final url = Uri.parse("$baseUrl/api/payment/razorpay/create");

      final body = {
        "order_id": orderId.toString(),
        "transaction_ref": transactionRef,
        "amount": amount.toInt(),
      };

      log("URL: $url");
      log("Body: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      log("📥 Response Status: ${response.statusCode}");
      log("📥 Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          log("✅ Razorpay order created successfully");
          log("══════════════════════════════════════════");
          return data;
        } else {
          log("❌ Razorpay order creation failed: ${data['error']}");
          log("══════════════════════════════════════════");
          return null;
        }
      } else {
        log("❌ HTTP Error: ${response.statusCode}");
        log("══════════════════════════════════════════");
        return null;
      }
    } catch (e, stackTrace) {
      log("❌ CREATE RAZORPAY ORDER ERROR: $e");
      log("Stack trace: $stackTrace");
      log("══════════════════════════════════════════");
      return null;
    }
  }

  static Future<bool> updateRazorpayPayment({
    required String transactionRef,
    required String status,
    String? razorpayPaymentId,
    required int orderId,
  }) async {
    try {
      log("══════════════════════════════════════════");
      log("📤 UPDATE RAZORPAY PAYMENT");
      log("   Transaction Ref: $transactionRef");
      log("   Status: $status");
      log("   Payment ID: $razorpayPaymentId");
      log("══════════════════════════════════════════");

      final url = Uri.parse("$baseUrl/api/payment/razorpay/update");

      final body = {
        "transaction_ref": transactionRef,
        "status": status,
        "razorpay_payment_id": razorpayPaymentId,
        "order_id": orderId,
      };

      log("URL: $url");
      log("Body: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      log("📥 Response Status: ${response.statusCode}");
      log("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        log("✅ Razorpay payment updated successfully");
        log("══════════════════════════════════════════");
        return true;
      } else {
        log("❌ Update failed");
        log("══════════════════════════════════════════");
        return false;
      }
    } catch (e, stackTrace) {
      log("❌ UPDATE RAZORPAY PAYMENT ERROR: $e");
      log("Stack trace: $stackTrace");
      log("══════════════════════════════════════════");
      return false;
    }
  }

  // Add these payment methods to your existing ApiService class

  // ========================= UPI PAYMENT =========================

  static Future<bool> createTransaction({
    required int orderId,
    required String transactionRef,
    required double amount,
    required String status,
  }) async {
    try {
      log("══════════════════════════════════════════");
      log("📤 CREATE TRANSACTION");
      log("   Order ID: $orderId");
      log("   Transaction Ref: $transactionRef");
      log("   Amount: $amount");
      log("   Status: $status");
      log("══════════════════════════════════════════");

      final url = Uri.parse("$baseUrl/api/transactions/create");

      final body = {
        "order_id": orderId,
        "transaction_ref": transactionRef,
        "amount": amount,
        "status": status,
        "payment_method": "UPI",
      };

      log("URL: $url");
      log("Body: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      log("📥 Response Status: ${response.statusCode}");
      log("📥 Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("✅ Transaction created successfully");
        log("══════════════════════════════════════════");
        return true;
      } else {
        log("❌ Create transaction failed");
        log("══════════════════════════════════════════");
        return false;
      }
    } catch (e, stackTrace) {
      log("❌ CREATE TRANSACTION ERROR: $e");
      log("Stack trace: $stackTrace");
      log("══════════════════════════════════════════");
      return false;
    }
  }

  static Future<String> getTransactionStatus(String transactionRef) async {
    try {
      log("══════════════════════════════════════════");
      log("📤 GET TRANSACTION STATUS");
      log("   Transaction Ref: $transactionRef");
      log("══════════════════════════════════════════");

      final url = Uri.parse('$baseUrl/api/transactions/$transactionRef/status');

      log("URL: $url");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      log("📥 Response Status: ${response.statusCode}");
      log("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'] as String;

        log("✅ Transaction status: \"$status\"");
        log("══════════════════════════════════════════");

        return status;
      } else if (response.statusCode == 404) {
        log("⚠️ Transaction not found");
        log("══════════════════════════════════════════");
        return 'pending';
      } else {
        log("❌ Failed to get transaction status");
        log("══════════════════════════════════════════");
        return 'pending';
      }
    } catch (e, stackTrace) {
      log("❌ GET TRANSACTION STATUS ERROR: $e");
      log("Stack trace: $stackTrace");
      log("══════════════════════════════════════════");
      return 'pending';
    }
  }

  static Future<bool> updateTransaction({
    required String transactionRef,
    required String status,
    required String upiResponse,
  }) async {
    try {
      log("══════════════════════════════════════════");
      log("📤 UPDATE TRANSACTION");
      log("   Transaction Ref: $transactionRef");
      log("   New Status: $status");
      log("   UPI Response: $upiResponse");
      log("══════════════════════════════════════════");

      final url = Uri.parse("$baseUrl/api/transactions/update");

      final body = {
        "transaction_ref": transactionRef,
        "status": status,
        "upi_response": upiResponse,
      };

      log("URL: $url");
      log("Body: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      log("📥 Response Status: ${response.statusCode}");
      log("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        log("✅ Transaction updated successfully");
        log("══════════════════════════════════════════");
        return true;
      } else {
        log("❌ Update transaction failed");
        log("══════════════════════════════════════════");
        return false;
      }
    } catch (e, stackTrace) {
      log("❌ UPDATE TRANSACTION ERROR: $e");
      log("Stack trace: $stackTrace");
      log("══════════════════════════════════════════");
      return false;
    }
  }

  static Future<bool> confirmPayment({
    required int orderId,
    required String transactionRef,
    required String paymentMethod,
  }) async {
    try {
      log("══════════════════════════════════════════");
      log("📤 CONFIRM PAYMENT");
      log("   Order ID: $orderId");
      log("   Transaction Ref: $transactionRef");
      log("   Payment Method: $paymentMethod");
      log("══════════════════════════════════════════");

      final url = Uri.parse("$baseUrl/api/transactions/success");

      final body = {
        "order_id": orderId,
        "transaction_ref": transactionRef,
        "payment_method": paymentMethod,
      };

      log("URL: $url");
      log("Body: ${jsonEncode(body)}");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      log("📥 Response Status: ${response.statusCode}");
      log("📥 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        log("✅ Payment confirmed successfully");
        log("══════════════════════════════════════════");
        return true;
      } else {
        log("❌ Confirm payment failed");
        log("══════════════════════════════════════════");
        return false;
      }
    } catch (e, stackTrace) {
      log("❌ CONFIRM PAYMENT ERROR: $e");
      log("Stack trace: $stackTrace");
      log("══════════════════════════════════════════");
      return false;
    }
  }
}
