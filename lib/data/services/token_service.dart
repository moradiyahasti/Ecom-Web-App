import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  // 🔥 CLEANED UP - Single set of keys (removed duplicates)
  static const String _tokenKey = "auth_token";
  static const String _refreshTokenKey = "refresh_token";
  static const String _nameKey = "user_name";
  static const String _emailKey = "user_email";
  static const String _userIdKey = "user_id";
  static const String _keyPaymentInProgress = "payment_in_progress";

  // ═══════════════════════════════════════════════════════════
  // TOKEN METHODS
  // ═══════════════════════════════════════════════════════════

  /// Save token
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    log("✅ TOKEN SAVED");
  }

  /// Get token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    log("🔍 TOKEN: ${token ?? 'null'}");
    return token;
  }

  /// Update token
  static Future<void> updateToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);
    log("✅ TOKEN UPDATED");
  }

  // ═══════════════════════════════════════════════════════════
  // REFRESH TOKEN METHODS
  // ═══════════════════════════════════════════════════════════

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // ═══════════════════════════════════════════════════════════
  // USER DATA METHODS
  // ═══════════════════════════════════════════════════════════

  /// Save user ID
  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
    log("✅ USER ID SAVED: $userId");
  }

  /// Get user ID
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);
    log("🔍 USER ID: ${userId ?? 'null'}");
    return userId;
  }

  /// Save name
  static Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    log("✅ NAME SAVED: $name");
  }

  /// Get name
  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  /// Save email
  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    log("✅ EMAIL SAVED: $email");
  }

  /// Get email
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // ═══════════════════════════════════════════════════════════
  // COMBINED SAVE METHOD
  // ═══════════════════════════════════════════════════════════

  /// Save all login data (refreshToken is optional)
  static Future<void> saveLoginData({
    required String token,
    String? refreshToken,
    required String name,
    required String email,
    required int userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_tokenKey, token);
    
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
    
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    await prefs.setInt(_userIdKey, userId);

    log("✅ LOGIN DATA SAVED - User ID: $userId, Name: $name");
  }

  // ═══════════════════════════════════════════════════════════
  // AUTHENTICATION METHODS
  // ═══════════════════════════════════════════════════════════

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Clear all data (logout)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    log("❌ ALL DATA CLEARED - User logged out");
  }

  // ═══════════════════════════════════════════════════════════
  // 🔥 PAYMENT FLAG METHODS (CRITICAL FOR CART PERSISTENCE)
  // ═══════════════════════════════════════════════════════════

  /// Set payment in progress flag (persists across app restarts AND screen reloads)
  static Future<void> setPaymentInProgress(bool inProgress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyPaymentInProgress, inProgress);
      
      // 🔥 VERIFY it was saved
      final saved = prefs.getBool(_keyPaymentInProgress);
      
      print("═══════════════════════════════════════════");
      print("💾 PAYMENT FLAG SAVED");
      print("Value set: $inProgress");
      print("Value verified: $saved");
      print("Match: ${saved == inProgress}");
      print("═══════════════════════════════════════════");
      
      log("💾 Payment flag saved: $inProgress (verified: $saved)");
    } catch (e) {
      log("❌ ERROR saving payment flag: $e");
      print("❌ ERROR saving payment flag: $e");
    }
  }

  /// Get payment in progress flag
  static Future<bool> isPaymentInProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final flag = prefs.getBool(_keyPaymentInProgress) ?? false;
      
      print("═══════════════════════════════════════════");
      print("🔍 PAYMENT FLAG RETRIEVED");
      print("Value: $flag");
      print("═══════════════════════════════════════════");
      
      log("🔍 Payment flag retrieved: $flag");
      return flag;
    } catch (e) {
      log("❌ ERROR retrieving payment flag: $e");
      print("❌ ERROR retrieving payment flag: $e");
      return false;
    }
  }

  /// Clear payment flag (use after payment success/failure)
  static Future<void> clearPaymentFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPaymentInProgress);
      
      print("═══════════════════════════════════════════");
      print("🗑️ PAYMENT FLAG CLEARED");
      print("═══════════════════════════════════════════");
      
      log("🗑️ Payment flag cleared");
    } catch (e) {
      log("❌ ERROR clearing payment flag: $e");
      print("❌ ERROR clearing payment flag: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════
  // 🔥 DEBUG METHOD - Check all stored values
  // ═══════════════════════════════════════════════════════════

  /// Debug method to print all stored values
  static Future<void> debugPrintAll() async {
    final prefs = await SharedPreferences.getInstance();
    
    print("═══════════════════════════════════════════");
    print("📊 ALL STORED VALUES:");
    print("Token: ${prefs.getString(_tokenKey)}");
    print("User ID: ${prefs.getInt(_userIdKey)}");
    print("Name: ${prefs.getString(_nameKey)}");
    print("Email: ${prefs.getString(_emailKey)}");
    print("Payment In Progress: ${prefs.getBool(_keyPaymentInProgress)}");
    print("═══════════════════════════════════════════");
  }
}