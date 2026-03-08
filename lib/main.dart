import 'package:demo/presentation/screens/Auth/dashboard_screen.dart';
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
        home: const MainLayout(), // 🔥 DIRECTLY TO DASHBOARD (GUEST MODE)
      ),
    );
  }
}
