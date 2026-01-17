import 'dart:developer';
import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const String _tokenKey = "auth_token";
    static const String _refreshTokenKey = "refresh_token"; // 🔥 ADD

  static const String _nameKey = "user_name";
  static const String _emailKey = "user_email";
  static const String _userIdKey = "user_id"; // 🔥 ADD THIS

  /// 🔥 SAVE ALL LOGIN DATA (Updated to include userId)
  // static Future<void> saveLoginData({
  //   required String token,
  //       required String refreshToken, // 🔥 ADD

  //   required String name,
  //   required String email,
  //   required int userId, // 🔥 ADD THIS PARAMETER
  // }) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   await prefs.setString(_tokenKey, token);
  //       await prefs.setString(_refreshTokenKey, refreshToken); // 🔥 SAVE

  //   await prefs.setString(_nameKey, name);
  //   await prefs.setString(_emailKey, email);
  //   await prefs.setInt(_userIdKey, userId); // 🔥 SAVE USER ID

  //   log("✅ LOGIN DATA SAVED - User ID: $userId, Name: $name");
  // }

 static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }
 static Future<void> updateToken(String newToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, newToken);
    log("✅ TOKEN UPDATED");
  }

  /// 🔥 GET TOKEN
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    log("🔍 TOKEN: ${token ?? 'null'}");
    
    return token;
  }

  /// 🔥 GET USER ID (NEW METHOD)
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_userIdKey);
    log("🔍 USER ID: ${userId ?? 'null'}");
    return userId;
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
    log("❌ ALL DATA CLEARED - User logged out");
  }

  /// UPDATE NAME
  static Future<void> saveName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    log("✅ NAME UPDATED: $name");
  }

  /// UPDATE EMAIL
  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
    log("✅ EMAIL UPDATED: $email");
  }
  /// 🔥 SAVE ALL LOGIN DATA (refreshToken is optional)
static Future<void> saveLoginData({
  required String token,
  String? refreshToken, // 🔥 Made optional
  required String name,
  required String email,
  required int userId,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_tokenKey, token);
  
  if (refreshToken != null) {
    await prefs.setString(_refreshTokenKey, refreshToken); // 🔥 Only save if provided
  }
  
  await prefs.setString(_nameKey, name);
  await prefs.setString(_emailKey, email);
  await prefs.setInt(_userIdKey, userId);

  log("✅ LOGIN DATA SAVED - User ID: $userId, Name: $name");
}
}
