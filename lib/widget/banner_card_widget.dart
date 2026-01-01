// import 'package:flutter/material.dart';

// Widget bannerCard({
//   required String image,
//   required String title,
//   required String subtitle,
// }) {
//   return Container(
//     width: double.infinity, // ✅ FULL WIDTH
//     height: 260,
//     padding: const EdgeInsets.only(right: 25, left: 25),
//     decoration: BoxDecoration(
//       color: const Color(0xffF5EFE6),
//       borderRadius: BorderRadius.circular(24),
//       image: DecorationImage(
//         image: NetworkImage(image),
//         fit: BoxFit.cover,
//         alignment: Alignment.centerRight,
//       ),
//     ),
//     child: Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Text(
//           subtitle,
//           style: const TextStyle(
//             fontSize: 12,
//             letterSpacing: 1.2,
//             color: Colors.black54,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           title,
//           style: const TextStyle(
//             fontSize: 28,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         const SizedBox(height: 16),
//         TextButton(
//           onPressed: () {},
//           child: const Text("Shop Now"),
//         )
//       ],
//     ),
//   );
// }



import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Widget bannerCard({
  required String image,
  required String title,
  required String subtitle,
}) {
  return AnimatedBannerCard(
    image: image,
    title: title,
    subtitle: subtitle,
  );
}

class AnimatedBannerCard extends StatefulWidget {
  final String image;
  final String title;
  final String subtitle;

  const AnimatedBannerCard({
    super.key,
    required this.image,
    required this.title,
    required this.subtitle,
  });

  @override
  State<AnimatedBannerCard> createState() => _AnimatedBannerCardState();
}

class _AnimatedBannerCardState extends State<AnimatedBannerCard>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.02),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: () {
          // Add navigation logic
        },
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _isHovered
                        ? Colors.deepPurple.withOpacity(0.3)
                        : Colors.black.withOpacity(0.1),
                    blurRadius: _isHovered ? 25 : 15,
                    offset: Offset(0, _isHovered ? 10 : 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background Image
                    Image.network(
                      widget.image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.grey.shade300,
                                Colors.grey.shade400,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),

                    // Gradient Overlay
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            _isHovered
                                ? Colors.black.withOpacity(0.7)
                                : Colors.black.withOpacity(0.5),
                          ],
                        ),
                      ),
                    ),

                    // Content
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.subtitle,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                widget.title,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              
                              // Animated Arrow Button
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: _isHovered
                                        ? [
                                            Colors.deepPurple.shade400,
                                            Colors.purple.shade500,
                                          ]
                                        : [
                                            Colors.white.withOpacity(0.2),
                                            Colors.white.withOpacity(0.1),
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_forward,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Pulse Effect on Hover
                    if (_isHovered)
                      Positioned.fill(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          builder: (context, value, child) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: RadialGradient(
                                  center: Alignment.center,
                                  radius: value * 2,
                                  colors: [
                                    Colors.white.withOpacity(0.1 * (1 - value)),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}