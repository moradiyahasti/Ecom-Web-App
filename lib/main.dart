import 'package:demo/presentation/screens/Auth/auth.dart';
import 'package:demo/presentation/screens/Auth/dashboard_screen.dart';
import 'package:demo/presentation/screens/Auth/splash_screen.dart';
import 'package:demo/data/providers/auth_provider.dart';
import 'package:demo/data/providers/cart_provider.dart';
import 'package:demo/data/services/provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    /// 🔥 MULTI PROVIDER - Proper order is crucial
    MultiProvider(
      providers: [
        /// 1️⃣ AUTH PROVIDER - Always first (others depend on it)
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),

        /// 2️⃣ CART PROVIDER - Don't load cart here, load after login
        ChangeNotifierProvider(create: (_) => CartProvider()),

        /// 3️⃣ FAVORITES PROVIDER - Don't load favorites here, load after login
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
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
        title: "Shree Nails",
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

    if (!mounted) return;

    // 🔥 Get AuthProvider
    final authProvider = context.read<AuthProvider>();

    // Wait for auth initialization if not already done
    if (!authProvider.isInitialized) {
      await authProvider.initialize();
    }

    if (!mounted) return;

    // 🔥 Check if user is logged in using AuthProvider
    if (authProvider.isLoggedIn && authProvider.userId != null) {
      /// ✅ USER LOGGED IN → Load user data and go to main layout
      final userId = authProvider.userId!;

      // Load cart and favorites for logged-in user
      if (mounted) {
        context.read<CartProvider>().loadCart(userId);
        context.read<FavoritesProvider>().loadFavorites(userId);
      }

      // Navigate to main layout
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          _createRoute(const MainLayout()),
          (_) => false,
        );
      }
    } else {
      /// ❌ USER NOT LOGGED IN → AUTH
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          _createRoute(const AuthScreen()),
          (_) => false,
        );
      }
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
