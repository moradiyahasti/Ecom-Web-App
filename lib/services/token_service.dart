import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = "auth_token";
  static const String _nameKey = "user_name";
  static const String _emailKey = "user_email";

  /// SAVE ALL LOGIN DATA
  static Future<void> saveLoginData({
    required String token,
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);

    log("✅ LOGIN DATA SAVED");
  }

  /// ✅ GET TOKEN (🔥 THIS FIXES YOUR ERROR)
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    log("🔍 TOKEN: $token");
    return token;
  }

  /// GET NAME
  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  /// GET EMAIL
  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  /// CLEAR ALL (LOGOUT)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    log("❌ ALL DATA CLEARED");
  }
}
