import 'package:demo/presentation/screens/Auth/auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:demo/data/providers/auth_provider.dart';

/// 🔒 AUTH GUARD - Checks if user is logged in before actions
class AuthGuard {
  /// Require login before performing an action
  static Future<void> requireLogin({
    required BuildContext context,
    required VoidCallback onAuthenticated,
  }) async {
    final authProvider = context.read<AuthProvider>();

    // ✅ User is already logged in
    if (authProvider.isLoggedIn && authProvider.userId != null) {
      onAuthenticated();
      return;
    }

    // ❌ User NOT logged in → Show login screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthScreen(),
      ),
    );

    // ✅ If user logged in successfully, execute the action
    if (result == true && context.mounted) {
      final updatedAuthProvider = context.read<AuthProvider>();
      if (updatedAuthProvider.isLoggedIn) {
        onAuthenticated();
      }
    }
  }

  /// Check if user is logged in
  static bool isLoggedIn(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    return authProvider.isLoggedIn && authProvider.userId != null;
  }

  /// Get current user ID
  static int? getCurrentUserId(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    return authProvider.userId;
  }
}