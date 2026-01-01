import 'package:demo/screens/splash_screen.dart';
import 'package:demo/services/provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'screens/auth.dart';
import 'screens/dashboard_screen.dart';
import 'services/token_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenService.getToken();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => FavoritesProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Demo App",
        theme: ThemeData(
          scaffoldBackgroundColor: const Color(0xFFF9F9FB),
          primaryColor: Colors.deepPurple,
        ),
        home: const SplashDecider(),
      ),
    );
  }
}

/// 🔑 SPLASH + AUTH DECIDER
class SplashDecider extends StatefulWidget {
  const SplashDecider({super.key});

  @override
  State<SplashDecider> createState() => _SplashDeciderState();
}

class _SplashDeciderState extends State<SplashDecider> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    // Premium splash delay for animations
    await Future.delayed(const Duration(milliseconds: 2500));

    final token = await TokenService.getToken();
    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      /// ✅ USER LOGGED IN → MAIN LAYOUT
      Navigator.pushAndRemoveUntil(
        context,
        _createRoute(const MainLayout()),
        (_) => false,
      );
    } else {
      /// ❌ USER NOT LOGGED IN → AUTH
      Navigator.pushAndRemoveUntil(
        context,
        _createRoute(const AuthScreen()),
        (_) => false,
      );
    }
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));

        var fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(child: Center(child: PremiumSplashView())),
    );
  }
}
