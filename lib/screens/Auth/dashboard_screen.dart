

import 'package:demo/screens/Auth/auth.dart';
import 'package:demo/screens/add_to_cart.dart';
import 'package:demo/screens/favorite.dart';
import 'package:demo/screens/home_screen.dart';
import 'package:demo/screens/Settings/setting_screen.dart';
import 'package:demo/services/cart_provider.dart';
import 'package:demo/services/token_service.dart';
import 'package:demo/widget/all_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int selectedIndex = 0;
  String name = "";
  String email = "";

  void loadUser() async {
    final n = await TokenService.getName();
    final e = await TokenService.getEmail();

    setState(() {
      name = n ?? "";
      email = e ?? "";
    });
  }


  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();

    pages = [
      const HomeScreen(),
      const CartScreen(), // ✅ કોઈ key નથી જોઈતું
      const FavoriteScreen(),
      const SettingsScreen(),
    ];
    loadUser();
  }

  /// ✅ UPDATED PAGE CHANGE
  void _changePage(int index) {
    if (index < 0 || index >= pages.length) return;

    setState(() => selectedIndex = index);

    // 🔥 Cart tab ખુલ્યે ત્યારે fresh data load કરો
    if (index == 1) {
      context.read<CartProvider>().loadCart(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: isMobile(context) ? Drawer(child: _drawerItems()) : null,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: isMobile(context)
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.deepPurple),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,

        title: isMobile(context)
            ? searchField()
            : Row(
                children: [
                  Text(
                    "Shop Name",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  SizedBox(width: 350, child: searchField()),
                  const Spacer(),
                ],
              ),

        actions: [
          _appBarIcon(
            onTap: () => _changePage(2),
            asset: "assets/favorite.svg",
          ),

          // 🔥 Cart Icon with Badge
          _cartIconWithBadge(),

          const SizedBox(width: 8),
        ],
      ),

      body: Row(
        children: [
          if (!isMobile(context)) SizedBox(width: 250, child: _drawerItems()),

          /// ✅ INDEXEDSTACK
          Expanded(
            child: IndexedStack(
              index: selectedIndex.clamp(0, pages.length - 1),
              children: pages,
            ),
          ),
        ],
      ),
    );
  }

  // 🛒 CART ICON WITH BADGE
  Widget _cartIconWithBadge() {
    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final itemCount = cartProvider.totalItems;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _appBarIcon(
              onTap: () => _changePage(1),
              asset: "assets/add-to-cart (1).svg",
            ),

            // 🔥 Badge
            if (itemCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Center(
                    child: Text(
                      itemCount > 99 ? '99+' : itemCount.toString(),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // ================= DRAWER =================

  Widget _drawerItems() {
    return Container(
      color: const Color(0xffF8F9FF),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ===== HEADER =====
          InkWell(
              onTap: () async {
            // OPTIONAL: drawer header click → open profile
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
            // drawer open પછી name/email refresh
            loadUser();
          },
            child: Container(
              height: 85,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.deepPurple),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    email,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          _menuItem("Home", Icons.home_rounded, 0),
          _menuItemWithBadge("Cart", Icons.shopping_cart_rounded, 1),
          _menuItem("Favorites", Icons.favorite_rounded, 2),
          _menuItem("Settings", Icons.settings_rounded, 3,),

          _menuItem("Logout", Icons.logout_rounded, -1),
        ],
      ),
    );
  }

  // 🛒 MENU ITEM WITH CART BADGE
  Widget _menuItemWithBadge(String title, IconData icon, int index) {
    bool selected = selectedIndex == index;

    return Consumer<CartProvider>(
      builder: (context, cartProvider, child) {
        final itemCount = cartProvider.totalItems;

        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            _changePage(index);
            if (isMobile(context)) {
              Navigator.pop(context);
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? Colors.deepPurple : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: selected ? Colors.white : Colors.deepPurple,
                    ),

                    // 🔥 Badge
                    if (itemCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Colors.deepPurple
                                  : Colors.white,
                              width: 1.5,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              itemCount > 99 ? '99+' : itemCount.toString(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected ? Colors.white : Colors.deepPurple,
                  ),
                ),

                // 🔥 Badge (alternative - right side)
                if (itemCount > 0) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      itemCount.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.deepPurple : Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _menuItem(String title, IconData icon, int index) {
    bool selected = selectedIndex == index;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        // 🔥 LOGOUT
        if (index == -1) {
          await TokenService.clearAll();
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFF6C5CE7),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You have been logged out successfully',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF6C5CE7),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 600));

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => AuthScreen(key: UniqueKey())),
            (route) => false,
          );
          return;
        }

        // ✅ NORMAL MENU NAVIGATION
        _changePage(index);

        // 📱 Mobile ma drawer close
        if (isMobile(context)) {
          Navigator.pop(context);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Colors.deepPurple : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? Colors.white : Colors.deepPurple,
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= APP BAR ICON =================

  Widget _appBarIcon({required VoidCallback onTap, required String asset}) {
    return IconButton(
      onPressed: onTap,
      icon: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.deepPurple.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: SvgPicture.asset(
            asset,
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
              Colors.deepPurple,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
