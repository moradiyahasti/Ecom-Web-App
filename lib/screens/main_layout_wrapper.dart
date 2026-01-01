import 'package:demo/screens/add_to_cart.dart';
import 'package:demo/screens/favorite.dart';
import 'package:demo/screens/Settings/setting_screen.dart';
import 'package:demo/widget/all_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/svg.dart';

// ✅ આ layout બધી screens માં વાપરો
class MainLayoutWrapper extends StatefulWidget {
  final Widget child; // જે પણ content હોય તે આમાં પાસ કરો
  final String title; // AppBar નું title
  final int selectedIndex; // કયું menu item selected છે

  const MainLayoutWrapper({
    super.key,
    required this.child,
    required this.title,
    this.selectedIndex = -1,
  });

  @override
  State<MainLayoutWrapper> createState() => _MainLayoutWrapperState();
}

class _MainLayoutWrapperState extends State<MainLayoutWrapper> {
  String? selectedSubItem;

  bool get isProductsSelected =>
      selectedSubItem == "Men" ||
      selectedSubItem == "Women" ||
      selectedSubItem == "Kids";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),

      // ✅ DRAWER - ફક્ત MOBILE માટે
      drawer: isMobile(context) ? _buildDrawer() : null,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: isMobile(context),

        // ✅ Menu Icon - ફક્ત MOBILE માટે
        leading: isMobile(context)
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.deepPurple),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                ),
              )
            : null,

        title: isMobile(context)
            ? searchField()
            : SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Text(
                      widget.title,
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
              ),

        actions: [
          _appBarIcon(
            context,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoriteScreen()),
              );
            },
            asset: "assets/favorite.svg",
          ),
          _appBarIcon(
            context,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
            asset: "assets/add-to-cart (1).svg",
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: Row(
        children: [
          // ✅ LEFT SIDEBAR - ફક્ત WEB માટે (હંમેશા દેખાશે)
          if (!isMobile(context)) _buildSidebar(),

          // ✅ MAIN CONTENT
          Expanded(
            child: widget.child, // જે પણ page content હોય
          ),
        ],
      ),
    );
  }

  // ✅ SIDEBAR CONTENT (Web + Mobile બંને માટે)
  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: Colors.white,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (!isMobile(context)) const SizedBox(height: 12),
          if (isMobile(context)) UserInfoSection(),
          if (isMobile(context)) const SizedBox(height: 12),

          _sidebarItem(
            icon: Icons.dashboard_outlined,
            title: "Dashboard",
            index: 0,
            onTap: () {
              _closeMobileDrawer();
              Navigator.pushNamed(context, '/dashboard');
            },
          ),

          _sidebarItem(
            icon: Icons.receipt_long_outlined,
            title: "Orders",
            index: 1,
            onTap: () {
              _closeMobileDrawer();
              Navigator.pushNamed(context, '/orders');
            },
          ),

          ExpansionTile(
            key: const PageStorageKey("products"),
            initiallyExpanded: isProductsSelected,
            leading: Icon(
              Icons.shopping_bag_outlined,
              size: 20,
              color: isProductsSelected
                  ? Colors.deepPurpleAccent
                  : Colors.black54,
            ),
            title: Text(
              "Products",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isProductsSelected
                    ? FontWeight.w600
                    : FontWeight.w400,
                color: isProductsSelected
                    ? Colors.deepPurpleAccent
                    : Colors.black87,
              ),
            ),
            childrenPadding: const EdgeInsets.only(left: 32),
            children: [
              _sidebarSubItem(title: "Men"),
              _sidebarSubItem(title: "Women"),
              _sidebarSubItem(title: "Kids"),
            ],
          ),

          _sidebarItem(
            icon: Icons.shopping_cart_outlined,
            title: "Cart",
            index: 3,
            onTap: () {
              _closeMobileDrawer();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              );
            },
          ),

          _sidebarItem(
            icon: Icons.favorite_outline,
            title: "Favorites",
            index: 4,
            onTap: () {
              _closeMobileDrawer();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoriteScreen()),
              );
            },
          ),

          _sidebarItem(
            icon: Icons.settings_outlined,
            title: "Settings",
            index: 5,
            onTap: () {
              _closeMobileDrawer();
              // Navigator.pushNamed(context, '/settings');
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // ✅ DRAWER (Mobile માટે)
  Widget _buildDrawer() {
    return Drawer(
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: SafeArea(
          child: Container(color: Colors.white, child: _buildSidebar()),
        ),
      ),
    );
  }

  // Mobile માં drawer બંધ કરવા માટે
  void _closeMobileDrawer() {
    if (isMobile(context)) {
      Navigator.pop(context);
    }
  }

  // Main Sidebar Item
  Widget _sidebarItem({
    required IconData icon,
    required String title,
    required int index,
    required VoidCallback onTap,
  }) {
    bool isSelected = widget.selectedIndex == index;

    return InkWell(
      onTap: () {
        setState(() {
          selectedSubItem = null;
        });
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffF3F4FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.deepPurpleAccent
                    : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.deepPurpleAccent : Colors.black54,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.deepPurpleAccent : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Subcategory Item
  Widget _sidebarSubItem({required String title}) {
    bool isSelected = selectedSubItem == title;

    return InkWell(
      onTap: () {
        setState(() {
          selectedSubItem = title;
        });
        _closeMobileDrawer();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffF3F4FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.deepPurpleAccent
                    : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.circle,
              size: 8,
              color: isSelected ? Colors.deepPurpleAccent : Colors.black54,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? Colors.deepPurpleAccent : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _appBarIcon(
    BuildContext context, {
    required VoidCallback onTap,
    required String asset,
  }) {
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
            fit: BoxFit.contain,
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

// ✅ હવે તમારા બધા screens માં આ રીતે વાપરો:

// 📄 HomeScreen Example:
class HomeScreenWithLayout extends StatelessWidget {
  const HomeScreenWithLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutWrapper(
      title: "Shop Name",
      selectedIndex: 0, // Dashboard selected
      child: SingleChildScrollView(
        child: Column(
          children: [
            // તમારું સંપૂર્ણ home screen content અહીં આવશે
            Container(
              height: 200,
              color: Colors.deepPurple,
              child: Center(
                child: Text(
                  "Big Sale 🔥 Up to 50% OFF",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // ... બાકીનું content
          ],
        ),
      ),
    );
  }
}

// 📄 CartScreen Example:
class CartScreenWithLayout extends StatelessWidget {
  const CartScreenWithLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutWrapper(
      title: "My Cart",
      selectedIndex: 3, // Cart selected
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "Your Cart Items",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // ... cart items
            ],
          ),
        ),
      ),
    );
  }
}

// 📄 FavoriteScreen Example:
class FavoriteScreenWithLayout extends StatelessWidget {
  const FavoriteScreenWithLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutWrapper(
      title: "My Favorites",
      selectedIndex: 4, // Favorites selected
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "Your Favorite Items",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // ... favorite items
            ],
          ),
        ),
      ),
    );
  }
}

// 📄 SettingsScreen Example:
class SettingsScreenWithLayout extends StatelessWidget {
  const SettingsScreenWithLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayoutWrapper(
      title: "Settings",
      selectedIndex: 5, // Settings selected
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                "App Settings",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // ... settings options
            ],
          ),
        ),
      ),
    );
  }
}
