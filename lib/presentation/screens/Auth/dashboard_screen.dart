import 'dart:async';
import 'package:demo/data/models/product_model.dart';
import 'package:demo/data/services/api_service.dart';
import 'package:demo/presentation/screens/Auth/auth.dart';
import 'package:demo/presentation/screens/cart/add_to_cart.dart';
import 'package:demo/presentation/screens/favorite/favorite.dart';
import 'package:demo/presentation/screens/home/home_screen.dart';
import 'package:demo/presentation/screens/product/product_details_screen.dart';
import 'package:demo/presentation/screens/Settings/setting_screen.dart';
import 'package:demo/data/providers/cart_provider.dart';
import 'package:demo/data/services/token_service.dart';
import 'package:demo/widget/all_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class MainLayout extends StatefulWidget {
  final int initialIndex;

  const MainLayout({super.key, this.initialIndex = 0});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  late int selectedIndex;
  String name = "";
  String email = "";

  // 🔍 SEARCH VARIABLES (for desktop)
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Product> _searchResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;
  Timer? _searchDebounce;
  String _searchErrorMessage = '';

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

    selectedIndex = widget.initialIndex;

    pages = [
      const HomeScreen(),
      const CartScreen(),
      const FavoriteScreen(),
      const SettingsScreen(),
    ];
    loadUser();

    if (selectedIndex == 1) {
      Future.microtask(() {
        if (mounted) {
          context.read<CartProvider>().loadCart(1);
        }
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _changePage(int index) {
    if (index < 0 || index >= pages.length) return;

    setState(() => selectedIndex = index);

    if (index == 1) {
      context.read<CartProvider>().loadCart(1);
    }
  }

  // 🔍 SEARCH FUNCTION
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _searchErrorMessage = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchErrorMessage = '';
    });

    try {
      final results = await ApiService.searchProducts(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
        _showSearchResults = true;

        if (results.isEmpty) {
          _searchErrorMessage = 'No products found for "$query"';
        }
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchErrorMessage = 'Error searching products';
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
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
                  // 🔍 DESKTOP SEARCH with RESULTS
                  SizedBox(
                    width: 350,
                    child: Column(
                      children: [
                        searchField(
                          controller: _searchController,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchChanged,
                          onTap: () {
                            if (_searchController.text.isNotEmpty) {
                              setState(() => _showSearchResults = true);
                            }
                          },
                          isSearching: _isSearching,
                          showClearButton: _searchController.text.isNotEmpty,
                          onClear: () {
                            _searchController.clear();
                            setState(() {
                              _searchResults = [];
                              _showSearchResults = false;
                              _searchErrorMessage = '';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
        actions: [
          _appBarIcon(
            onTap: () => _changePage(2),
            asset: "assets/favorite.svg",
          ),
          _cartIconWithBadge(),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Row(
            children: [
              if (!isMobile(context))
                SizedBox(width: 250, child: _drawerItems()),
              Expanded(
                child: IndexedStack(
                  index: selectedIndex.clamp(0, pages.length - 1),
                  children: pages,
                ),
              ),
            ],
          ),

          // 🔍 DESKTOP SEARCH RESULTS OVERLAY
          if (_showSearchResults && !isMobile(context))
            _buildSearchResultsOverlay(),
        ],
      ),
    );
  }

  // 🔍 SEARCH RESULTS OVERLAY (Desktop)
  Widget _buildSearchResultsOverlay() {
    return GestureDetector(
      onTap: () {
        setState(() => _showSearchResults = false);
        _searchFocusNode.unfocus();
      },
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Center(
          child: Container(
            width: 500,
            margin: const EdgeInsets.only(top: 70),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // HEADER
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade50,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _searchErrorMessage.isEmpty
                            ? 'Found ${_searchResults.length} products'
                            : 'Search Results',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: Colors.deepPurple,
                        onPressed: () {
                          setState(() => _showSearchResults = false);
                        },
                      ),
                    ],
                  ),
                ),

                // RESULTS
                Flexible(
                  child: _searchErrorMessage.isNotEmpty
                      ? _buildNoResults()
                      : ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(12),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            return _buildSearchResultItem(
                              _searchResults[index],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ❌ NO RESULTS
  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            _searchErrorMessage,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  // 📦 SEARCH RESULT ITEM
  Widget _buildSearchResultItem(Product product) {
    return InkWell(
      onTap: () {
        setState(() => _showSearchResults = false);
        _searchFocusNode.unfocus();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EnhancedNailProductDetails(
              productId: product.id,
              title: product.title,
              mainImage: product.image,
              productImages: product.productImages.isNotEmpty
                  ? product.productImages
                  : [product.image],
              oldPrice: product.oldPrice,
              review: product.reviews,
              price: product.price,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                product.image,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image, size: 30),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹${product.price}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${product.oldPrice}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

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

  Widget _drawerItems() {
    return Container(
      color: const Color(0xffF8F9FF),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
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
          _menuItem("Settings", Icons.settings_rounded, 3),
          _menuItem("Logout", Icons.logout_rounded, -1),
        ],
      ),
    );
  }

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
