import 'dart:convert';
import 'package:demo/data/models/get_cart_item_model.dart';
import 'package:demo/data/services/token_service.dart';
import 'package:demo/utils/app_loger.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../models/product_model.dart';

class ApiService {
  // static const String baseUrl = "http://192.168.1.25:5000"; // office
  static const String baseUrl = "http://192.168.0.104:5000"; // home

  static const headers = {"Content-Type": "application/json"};

  // ========================= AUTH =========================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/auth/register");
    final body = {"name": name, "email": email, "password": password};

    AppLogger.api("REGISTER", url);
    AppLogger.info("Body: ${jsonEncode(body)}");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    return {"status": res.statusCode, "data": jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse("$baseUrl/auth/login");
    final body = {"email": email, "password": password};

    AppLogger.api("LOGIN", url);
    AppLogger.info("Body: ${jsonEncode(body)}");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    return {"status": res.statusCode, "data": jsonDecode(res.body)};
  }

  // ========================= PRODUCTS =========================

  static Future<List<Product>> fetchProducts() async {
    final url = Uri.parse("$baseUrl/api/products");

    AppLogger.api("GET PRODUCTS", url);

    final res = await http.get(url);

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load products");
    }
  }

  static Future<List<Product>> fetchTrending() async {
    final url = Uri.parse("$baseUrl/api/products/trending");

    AppLogger.api("GET TRENDING", url);

    final res = await http.get(url);

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load trending products");
    }
  }

  static Future<Product> getProductById(int id) async {
    final url = Uri.parse("$baseUrl/api/products/$id");

    AppLogger.api("GET PRODUCT BY ID", url);

    final res = await http.get(url);

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    return Product.fromJson(jsonDecode(res.body));
  }

  static Future<List<Product>> searchProducts(String query) async {
    final url = Uri.parse("$baseUrl/api/products/search/$query");

    AppLogger.api("SEARCH PRODUCTS", url);

    final res = await http.get(url);

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    final List data = jsonDecode(res.body);
    return data.map((e) => Product.fromJson(e)).toList();
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

    AppLogger.api("ADD TO CART", url);
    AppLogger.info("Body: ${jsonEncode(body)}");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      AppLogger.success("Cart ID: ${data['cart']['id']}");
      return data['cart']['id'];
    } else {
      AppLogger.error("Add to cart failed");
      throw Exception("Add to cart failed");
    }
  }

  static Future<List<GetCartItemMode>> getCart(int userId) async {
    final url = Uri.parse("$baseUrl/api/cart/$userId");

    AppLogger.api("GET CART", url);

    final res = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      final cartItems = data.map((e) => GetCartItemMode.fromJson(e)).toList();

      for (var item in cartItems) {
        AppLogger.info(
          "CartItem → cartId: ${item.cartId}, productId: ${item.productId}, "
          "title: ${item.title}, price: ${item.price}, qty: ${item.quantity}",
        );
      }

      return cartItems;
    } else {
      AppLogger.error("Failed to load cart");
      throw Exception("Failed to load cart");
    }
  }

  static Future<void> updateCartQuantity({
    required int cartId,
    required int quantity,
  }) async {
    final url = Uri.parse("$baseUrl/api/cart/update");

    final body = {"cart_id": cartId, "quantity": quantity};

    AppLogger.api("UPDATE CART QUANTITY", url);
    AppLogger.info("Body: ${jsonEncode(body)}");

    final res = await http.put(url, headers: headers, body: jsonEncode(body));

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    if (res.statusCode != 200) {
      throw Exception("Update quantity failed");
    }
  }

  static Future<void> removeFromCart(int cartId) async {
    final url = Uri.parse("$baseUrl/api/cart/remove/$cartId");

    AppLogger.api("REMOVE FROM CART", url);

    final res = await http.delete(url);

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");
  }

  static Future<void> updateQuantity({
    required int cartId,
    required int quantity,
  }) async {
    final url = Uri.parse("$baseUrl/api/cart/update");

    final body = {"cart_id": cartId, "quantity": quantity};

    AppLogger.api("UPDATE QUANTITY", url);
    AppLogger.info("Body: ${jsonEncode(body)}");

    final res = await http.put(url, headers: headers, body: jsonEncode(body));

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");
  }

  static Future<List<Product>> getFavorites(int userId) async {
    final url = Uri.parse("$baseUrl/api/favorites/$userId");

    AppLogger.api("GET FAVORITES", url);

    final res = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Product.fromJson(e)).toList();
    } else {
      throw Exception("Failed to load favorites");
    }
  }

  // ========================= FAVORITES =========================

  static Future<bool> toggleFavorite({
    required int userId,
    required int productId,
  }) async {
    final url = Uri.parse("$baseUrl/api/favorites/toggle");

    final body = {"user_id": userId, "product_id": productId};

    AppLogger.api("TOGGLE FAVORITE", url);
    AppLogger.info("Body: ${jsonEncode(body)}");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      return data['favorite'] == true;
    } else {
      throw Exception("Failed to toggle favorite");
    }
  }
/* 
 static Future<Map<String, dynamic>?> updateProfile({
  required String token,
  required String name,
  required String email,
}) async {
  try {
    final url = Uri.parse("$baseUrl/auth/update-profile");

    AppLogger.api("UPDATE PROFILE", url);
    AppLogger.info("Request Headers: Authorization Bearer [TOKEN]");
    AppLogger.info("Request Body: {name: $name, email: $email}");

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // 🔥 This is correct
      },
      body: jsonEncode({
        "name": name,
        "email": email,
      }),
    );

    AppLogger.info("Status: ${response.statusCode}");
    AppLogger.info("Response: ${response.body}");

    // 🔥 BETTER ERROR HANDLING
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Check if 'user' key exists in response
      if (data.containsKey('user')) {
        AppLogger.success("Profile updated successfully");
        return data['user'];
      } else {
        AppLogger.error("Invalid response structure: ${response.body}");
        return null;
      }
    } else {
      // 🔥 LOG DETAILED ERROR
      AppLogger.error("Profile update failed - Status: ${response.statusCode}");
      AppLogger.error("Error Response: ${response.body}");
      
      // Try to parse error message
      try {
        final errorData = jsonDecode(response.body);
        AppLogger.error("Error Message: ${errorData['error'] ?? 'Unknown error'}");
      } catch (e) {
        AppLogger.error("Could not parse error response");
      }
      
      return null;
    }
  } catch (e) {
    AppLogger.error("Exception in updateProfile", e);
    return null;
  }
}
 */
  static Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    required String token,
  }) async {
    try {
      if (token.isEmpty) return false;

      final url = Uri.parse("$baseUrl/auth/change-password");

      AppLogger.api("CHANGE PASSWORD", url);

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
        AppLogger.success("Password changed successfully");
        return true;
      } else {
        AppLogger.error("Change password failed: ${response.body}");
        return false;
      }
    } catch (e) {
      AppLogger.error("Exception in changePassword", e);
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

    AppLogger.api("SAVE ADDRESS", url);
    AppLogger.info("Body: ${jsonEncode(body)}");

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    AppLogger.info("Status: ${response.statusCode}");
    AppLogger.info("Response: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      AppLogger.success("Address saved with ID: ${data["address_id"]}");
      return data["address_id"];
    } else {
      AppLogger.error("Address save failed");
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

    AppLogger.api("CREATE TRANSACTION", url);
    AppLogger.info("Body: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(body),
      );

      AppLogger.info("Status: ${response.statusCode}");
      AppLogger.info("Response: ${response.body}");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      AppLogger.error("Create transaction error", e);
      return false;
    }
  }

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

    AppLogger.api("UPDATE TRANSACTION", url);
    AppLogger.info("Body: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      AppLogger.info("Status: ${response.statusCode}");
      AppLogger.info("Response: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error("Update transaction error", e);
      return false;
    }
  }

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

    AppLogger.api("CONFIRM PAYMENT", url);
    AppLogger.info("Body: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      AppLogger.info("Status: ${response.statusCode}");
      AppLogger.info("Response: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error("Confirm payment error", e);
      return false;
    }
  }

  // ========================= ORDERS =========================

  static Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    final url = Uri.parse("$baseUrl/api/orders/$orderId");

    AppLogger.api("GET ORDER DETAILS", url);

    final res = await http.get(
      url,
      headers: {"Content-Type": "application/json"},
    );

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Failed to load order details");
    }
  }

  // ========================= CART CLEAR =========================

  static Future<void> clearCart(int userId) async {
    final url = Uri.parse("$baseUrl/api/cart/clear/$userId");

    AppLogger.api("CLEAR CART", url);

    final res = await http.delete(url);

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

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
      AppLogger.error('Could not launch UPI');
      throw 'Could not launch UPI';
    }
  }

  static Future<Product> getProductDetails({
    required int productId,
    int? userId,
  }) async {
    final url = userId != null
        ? Uri.parse("$baseUrl/api/products/$productId?user_id=$userId")
        : Uri.parse("$baseUrl/api/products/$productId");

    AppLogger.api("GET PRODUCT DETAILS", url);

    final res = await http.get(url);

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    if (res.statusCode == 200) {
      return Product.fromJson(jsonDecode(res.body));
    } else {
      throw Exception("Failed to load product details");
    }
  }

  static Future<String> getTransactionStatus(String transactionRef) async {
    try {
      final url = Uri.parse('$baseUrl/transactions/$transactionRef/status');

      AppLogger.api("GET TRANSACTION STATUS", url);

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'];
      }
      return 'pending';
    } catch (e) {
      AppLogger.error("Get transaction status error", e);
      return 'pending';
    }
  }
  // ========================= FORGOT PASSWORD =========================

  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    final url = Uri.parse("$baseUrl/auth/forgot-password");
    final body = {"email": email};

    AppLogger.api("FORGOT PASSWORD", url);
    AppLogger.info("Body: ${jsonEncode(body)}");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    return {"status": res.statusCode, "data": jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    final url = Uri.parse("$baseUrl/auth/verify-otp");
    final body = {"email": email, "otp": otp};

    AppLogger.api("VERIFY OTP", url);
    AppLogger.info("Body: ${jsonEncode(body)}");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    return {"status": res.statusCode, "data": jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final url = Uri.parse("$baseUrl/auth/reset-password");
    final body = {"email": email, "otp": otp, "newPassword": newPassword};

    AppLogger.api("RESET PASSWORD", url);
    AppLogger.info("Body: ${jsonEncode(body)}");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    return {"status": res.statusCode, "data": jsonDecode(res.body)};
  }

  static Future<Map<String, dynamic>> resendOTP({required String email}) async {
    final url = Uri.parse("$baseUrl/auth/resend-otp");
    final body = {"email": email};

    AppLogger.api("RESEND OTP", url);
    AppLogger.info("Body: ${jsonEncode(body)}");

    final res = await http.post(url, headers: headers, body: jsonEncode(body));

    AppLogger.info("Status: ${res.statusCode}");
    AppLogger.info("Response: ${res.body}");

    return {"status": res.statusCode, "data": jsonDecode(res.body)};
  }
   static Future<String?> refreshToken() async {
    try {
      final refreshToken = await TokenService.getRefreshToken();
      
      if (refreshToken == null) return null;

      final url = Uri.parse("$baseUrl/auth/refresh-token");
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({"refreshToken": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['token'];
        
        // Save new token
        await TokenService.updateToken(newToken);
        
        AppLogger.success("Token refreshed successfully");
        return newToken;
      }
      
      return null;
    } catch (e) {
      AppLogger.error("Token refresh failed", e);
      return null;
    }
  }

  // 🔥 UPDATED UPDATE PROFILE with auto-retry
  static Future<Map<String, dynamic>?> updateProfile({
    required String token,
    required String name,
    required String email,
  }) async {
    try {
      final url = Uri.parse("$baseUrl/auth/update-profile");

      AppLogger.api("UPDATE PROFILE", url);

      final response = await http.put(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"name": name, "email": email}),
      );

      AppLogger.info("Status: ${response.statusCode}");

      // 🔥 IF TOKEN EXPIRED, REFRESH AND RETRY
      if (response.statusCode == 401) {
        AppLogger.info("Token expired, attempting refresh...");
        
        final newToken = await refreshToken();
        
        if (newToken != null) {
          // Retry with new token
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
              AppLogger.success("Profile updated successfully (after refresh)");
              return data['user'];
            }
          }
        }
        
        return null;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('user')) {
          AppLogger.success("Profile updated successfully");
          return data['user'];
        }
      }

      return null;
    } catch (e) {
      AppLogger.error("Exception in updateProfile", e);
      return null;
    }
  }

}
