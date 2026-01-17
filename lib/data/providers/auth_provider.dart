import 'dart:developer';
import 'package:demo/data/services/token_service.dart';
import 'package:flutter/foundation.dart';

/// 🔐 AUTHENTICATION PROVIDER
/// Manages user authentication state across the app
class AuthProvider with ChangeNotifier {
  int? _userId;
  String? _userName;
  String? _userEmail;
  String? _token;
  bool _isInitialized = false;

  // Getters
  int? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get token => _token;
  bool get isLoggedIn => _userId != null && _token != null;
  bool get isInitialized => _isInitialized;

  /// 🚀 INITIALIZE - Load saved auth data on app start
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      log("🔄 Initializing AuthProvider...");

      _userId = await TokenService.getUserId();
      _userName = await TokenService.getName();
      _userEmail = await TokenService.getEmail();
      _token = await TokenService.getToken();

      _isInitialized = true;

      if (isLoggedIn) {
        log("✅ User already logged in - ID: $_userId, Name: $_userName");
      } else {
        log("ℹ️ No saved login found");
      }

      notifyListeners();
    } catch (e) {
      log("❌ Error initializing auth: $e");
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// 🔑 LOGIN - Save user credentials
  Future<void> login({
    required int userId,  
    required String name,
    required String email,
    required String token,
  }) async {
    try {
      log("🔑 Logging in user: $name (ID: $userId)");

      // Save to local storage
      await TokenService.saveLoginData(
        token: token,
        name: name,
        email: email,
        userId: userId,
      );

      // Update state
      _userId = userId;
      _userName = name;
      _userEmail = email;
      _token = token;
      _isInitialized = true;

      log("✅ Login successful - User ID: $_userId");
      notifyListeners();
    } catch (e) {
      log("❌ Error during login: $e");
      rethrow;
    }
  }

  /// 🚪 LOGOUT - Clear all user data
  Future<void> logout() async {
    try {
      log("🚪 Logging out user: $_userName (ID: $_userId)");

      // Clear local storage
      await TokenService.clearAll();

      // Clear state
      _userId = null;
      _userName = null;
      _userEmail = null;
      _token = null;

      log("✅ Logout successful");
      notifyListeners();
    } catch (e) {
      log("❌ Error during logout: $e");
      rethrow;
    }
  }

  /// 🔄 UPDATE USER INFO
  Future<void> updateUserInfo({String? name, String? email}) async {
    try {
      if (name != null) {
        await TokenService.saveName(name);
        _userName = name;
      }

      if (email != null) {
        await TokenService.saveEmail(email);
        _userEmail = email;
      }

      notifyListeners();
      log("✅ User info updated");
    } catch (e) {
      log("❌ Error updating user info: $e");
      rethrow;
    }
  }

  /// 🔍 CHECK AUTH STATUS
  Future<bool> checkAuthStatus() async {
    try {
      final userId = await TokenService.getUserId();
      final token = await TokenService.getToken();

      return userId != null && token != null;
    } catch (e) {
      log("❌ Error checking auth status: $e");
      return false;
    }
  }
}
