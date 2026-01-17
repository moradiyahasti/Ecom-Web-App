import 'dart:async';
import 'package:demo/data/models/product_model.dart';
import 'package:demo/data/services/api_service.dart';
import 'package:demo/data/services/token_service.dart';
import 'package:demo/widget/feture_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 🔥 SEARCH FIELD WITH RESULTS
class SearchFieldWithResults extends StatefulWidget {
  const SearchFieldWithResults({super.key});

  @override
  State<SearchFieldWithResults> createState() => _SearchFieldWithResultsState();
}

class _SearchFieldWithResultsState extends State<SearchFieldWithResults> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<Product> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  Timer? _debounce;
  String _errorMessage = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // 🔍 SEARCH FUNCTION
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
        _errorMessage = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = '';
    });

    try {
      final results = await ApiService.searchProducts(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
        _showResults = true;
        
        // જો કોઈ results નથી
        if (results.isEmpty) {
          _errorMessage = 'No products found for "$query"';
        }
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _errorMessage = 'Error searching products';
      });
    }
  }

  // 🕐 DEBOUNCED SEARCH (0.5 second delay)
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // SEARCH FIELD
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.deepPurple.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            style: GoogleFonts.poppins(fontSize: 14),
            cursorColor: Colors.deepPurple,
            onChanged: _onSearchChanged,
            onTap: () {
              // જ્યારે search field click કરો ત્યારે results બતાવો
              if (_controller.text.isNotEmpty) {
                setState(() => _showResults = true);
              }
            },
            decoration: InputDecoration(
              hintText: "Search products...",
              hintStyle: GoogleFonts.poppins(
                color: Colors.deepPurple.withOpacity(0.45),
                fontSize: 13,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 12, right: 6),
                child: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.deepPurple,
                        ),
                      )
                    : const Icon(Icons.search, color: Colors.deepPurple, size: 22),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              
              // 🔥 CLEAR BUTTON
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      color: Colors.grey,
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _searchResults = [];
                          _showResults = false;
                          _errorMessage = '';
                        });
                      },
                    )
                  : null,
              
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),

        // 🔥 SEARCH RESULTS DROPDOWN
        if (_showResults) _buildSearchResults(),
      ],
    );
  }

  // 📋 SEARCH RESULTS WIDGET
  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _errorMessage.isEmpty
                      ? 'Found ${_searchResults.length} products'
                      : 'Search Results',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.deepPurple,
                  onPressed: () {
                    setState(() => _showResults = false);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // RESULTS LIST or ERROR MESSAGE
          Flexible(
            child: _errorMessage.isNotEmpty
                ? _buildNoResults()
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  // ❌ NO RESULTS MESSAGE
  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 60,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
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

  // ✅ RESULTS LIST
  Widget _buildResultsList() {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return _buildSearchResultItem(product);
      },
    );
  }

  // 📦 SEARCH RESULT ITEM
  Widget _buildSearchResultItem(Product product) {
    return InkWell(
      onTap: () {
        // Close search results
        setState(() => _showResults = false);
        _focusNode.unfocus();
        
        // Navigate to product details
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(
        //     builder: (_) => EnhancedNailProductDetails(
        //       productId: product.id,
        //       title: product.title,
        //       // ... other params
        //     ),
        //   ),
        // );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // PRODUCT IMAGE
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

            // PRODUCT INFO
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

            // ARROW ICON
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

// 🔥 SIMPLE SEARCH FIELD (તમારો original function)
Widget searchField() {
  return const SearchFieldWithResults();
}

// ================= OTHER WIDGETS (તમારા original) =================

Widget drawerProfileHeader() {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.deepPurpleAccent, Colors.deepPurple.shade400],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
    child: Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 26,
            backgroundImage: NetworkImage(
              "https://i.pravatar.cc/150?img=3",
            ),
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Riya Patel",
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "riya.patel@email.com",
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ],
    ),
  );
}

bool isMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < 900;
}

class UserInfoSection extends StatefulWidget {
  const UserInfoSection({super.key});

  @override
  State<UserInfoSection> createState() => _UserInfoSectionState();
}

class _UserInfoSectionState extends State<UserInfoSection> {
  String name = "";
  String email = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  void loadUser() async {
    final n = await TokenService.getName();
    final e = await TokenService.getEmail();

    setState(() {
      name = n ?? "";
      email = e ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurpleAccent, Colors.deepPurple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.isEmpty ? "User" : name,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Widget featuresSection() {
  return LayoutBuilder(
    builder: (context, constraints) {
      bool isMobile = constraints.maxWidth < 768;
      return Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Why Choose Us",
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 4,
                          width: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepPurple.shade400,
                                Colors.purple.shade400,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          GridView.count(
            padding: const EdgeInsets.all(20),
            crossAxisCount: isMobile ? 2 : 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 15,
            childAspectRatio: isMobile ? 1.2 : 2.8,
            children: [
              FeatureItem(
                iconAsset: "assets/credit-card.svg",
                title: "SECURE PAYMENT",
                desc: "Encrypt financial data to guarantee secure transactions",
              ),
              FeatureItem(
                iconAsset: "assets/lowest-price.svg",
                title: "LOWEST PRICE",
                desc: "Best-in-class products at budget-friendly rates",
              ),
              FeatureItem(
                iconAsset: "assets/add-to-bag1.svg",
                title: "SMOOTH CHECKOUT",
                desc: "Quick and hassle-free payment process",
              ),
            ],
          ),
        ],
      );
    },
  );
}