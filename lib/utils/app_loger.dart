import 'dart:developer';
import 'package:flutter/foundation.dart';

class AppLogger {
  static void api(String msg, Uri url) {
    if (kDebugMode) log("🌐 $msg", level: 500);
  }

  static void info(String msg) {
    if (kDebugMode) log("ℹ️ $msg", level: 800);
  }

  static void success(String msg) {
    if (kDebugMode) log("✅ $msg", level: 700);
  }

  static void warning(String msg) {
    if (kDebugMode) log("⚠️ $msg", level: 900);
  }

  static void error(String msg, [Object? e]) {
    log(
      "❌ $msg",
      level: 1000,
      error: e,
      stackTrace: StackTrace.current,
    );
  }
}
