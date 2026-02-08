import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

/// 🌸 PREMIUM SPLASH VIEW
class PremiumSplashView extends StatefulWidget {
  const PremiumSplashView({super.key});

  @override
  State<PremiumSplashView> createState() => _PremiumSplashViewState();
}

class _PremiumSplashViewState extends State<PremiumSplashView>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _progressController;
  late AnimationController _particleController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotateAnimation;
  late Animation<double> _textFadeAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoRotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _textSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _textController.forward();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _progressController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _progressController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.deepPurple.shade50,
            Colors.white,
            Colors.purple.shade50,
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated particles background
          ...List.generate(15, (index) => _buildParticle(index)),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                _buildAnimatedLogo(),
                const SizedBox(height: 30),

                // Animated text
                _buildAnimatedText(),

                const SizedBox(height: 40),

                // Animated progress
                _buildAnimatedProgress(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticle(int index) {
    final random = (index * 17) % 100;
    final size = 4.0 + (random % 8);
    final top = (random * 7.0) % MediaQuery.of(context).size.height;
    final left = (random * 11.0) % MediaQuery.of(context).size.width;

    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = _particleController.value;
        final newTop = top + (progress * 100) - 50;
        final opacity = (1 - progress).clamp(0.0, 0.4);

        return Positioned(
          top: newTop % MediaQuery.of(context).size.height,
          left: left,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.deepPurple.withOpacity(opacity),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScaleAnimation.value,
          child: Transform.rotate(
            angle: _logoRotateAnimation.value * 0.2,
            child: Container(
              height: 110,
              width: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.deepPurple.shade400,
                    Colors.deepPurple.shade600,
                    Colors.purple.shade700,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 15),
                  ),
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: -5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Shine effect
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(
                                  0.3 * _logoScaleAnimation.value,
                                ),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Icon
                  Center(
                    child:/*  Image.asset(
                      height: 250,
                      width: 250,
                      "assets/shree nails.png",
                      fit: BoxFit.cover,
                      color: Colors.white,
                    ) */ Icon(
                      FontAwesomeIcons.bagShopping,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  Text("Sonali Jivani")
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedText() {
    return SlideTransition(
      position: _textSlideAnimation,
      child: FadeTransition(
        opacity: _textFadeAnimation,
        child: Column(
          children: [
            // App name with gradient
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [Colors.deepPurple.shade700, Colors.purple.shade500],
              ).createShader(bounds),
              child: Text(
                "Shree Nails",
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              "Premium Nails experience",
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 12),

            // Features
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFeatureBadge(Icons.verified, "Trusted"),
                const SizedBox(width: 12),
                _buildFeatureBadge(Icons.local_shipping, "Fast"),
                const SizedBox(width: 12),
                _buildFeatureBadge(Icons.security, "Secure"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade50, Colors.purple.shade50],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.deepPurple.shade200, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: Colors.deepPurple.shade700),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedProgress() {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        return Column(
          children: [
            // Custom animated progress bar
            Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
              child: Stack(
                children: [
                  // Progress fill
                  FractionallySizedBox(
                    widthFactor: _progressController.value,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.deepPurple.shade400,
                            Colors.purple.shade500,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurple.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Loading text
            FadeTransition(
              opacity: _textFadeAnimation,
              child: Text(
                "Loading...",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.deepPurple.shade400,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
