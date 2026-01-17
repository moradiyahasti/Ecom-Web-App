import 'package:demo/data/services/token_service.dart';
import 'package:demo/widget/feture_item_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 🔍 SEARCH FIELD - માટે MainLayout use કરી શકે
Widget searchField({
  TextEditingController? controller,
  FocusNode? focusNode,
  Function(String)? onChanged,
  VoidCallback? onTap,
  bool isSearching = false,
  bool showClearButton = false,
  VoidCallback? onClear,
}) {
  return Container(
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
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onTap: onTap,
      style: GoogleFonts.poppins(fontSize: 14),
      cursorColor: Colors.deepPurple,
      decoration: InputDecoration(
        hintText: "Search products...",
        hintStyle: GoogleFonts.poppins(
          color: Colors.deepPurple.withOpacity(0.45),
          fontSize: 13,
        ),

        // 🔍 ICON or LOADING
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 12, right: 6),
          child: isSearching
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
        suffixIcon: showClearButton
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20),
                color: Colors.grey,
                onPressed: onClear,
              )
            : null,

        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}

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
        /// PROFILE IMAGE
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 26,
            backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=3"),
          ),
        ),

        const SizedBox(width: 14),

        /// USER INFO
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
