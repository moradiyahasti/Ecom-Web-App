import 'package:demo/screens/dashboard_screen.dart';
import 'package:demo/services/api_service.dart';
import 'package:demo/services/token_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum AuthView { login, register, forgot }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  AuthView currentView = AuthView.login;
  bool showPassword = false;
  bool rememberMe = false;
  bool isLoading = false;

  late AnimationController _formController;
  late AnimationController _imageController;
  late Animation<double> _formFadeAnimation;
  late Animation<Offset> _formSlideAnimation;
  late Animation<double> _imageScaleAnimation;

  final TextEditingController loginEmail = TextEditingController();
  final TextEditingController loginPassword = TextEditingController();
  final TextEditingController regName = TextEditingController();
  final TextEditingController regEmail = TextEditingController();
  final TextEditingController regPassword = TextEditingController();
  final TextEditingController forgotEmail = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Form animation
    _formController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _formFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _formController, curve: Curves.easeOut));

    _formSlideAnimation =
        Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _formController, curve: Curves.easeOutCubic),
        );

    // Image animation
    _imageController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _imageScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _imageController, curve: Curves.elasticOut),
    );

    _formController.forward();
    _imageController.forward();
  }

  @override
  void dispose() {
    _formController.dispose();
    _imageController.dispose();
    loginEmail.dispose();
    loginPassword.dispose();
    regName.dispose();
    regEmail.dispose();
    regPassword.dispose();
    forgotEmail.dispose();
    super.dispose();
  }

  void _showCustomSnackBar({required String message, required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isSuccess ? "Success!" : "Error",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess
            ? Colors.green.shade600
            : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
        elevation: 8,
      ),
    );
  }

  void onLogin() async {
    if (loginEmail.text.trim().isEmpty || loginPassword.text.trim().isEmpty) {
      _showCustomSnackBar(message: "Please fill all fields", isSuccess: false);
      return;
    }

    setState(() => isLoading = true);

    final res = await ApiService.login(
      email: loginEmail.text.trim(),
      password: loginPassword.text.trim(),
    );

    setState(() => isLoading = false);

    if (res["status"] == 200) {
      final data = res["data"];
      await TokenService.saveLoginData(
        token: data["token"],
        name: data["user"]["name"],
        email: data["user"]["email"],
      );

      _showCustomSnackBar(
        message: "Welcome back ${data["user"]["name"]}!",
        isSuccess: true,
      );

      await Future.delayed(const Duration(milliseconds: 500));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainLayout()),
      );
    } else {
      _showCustomSnackBar(
        message: res["data"]["message"] ?? "Login failed",
        isSuccess: false,
      );
    }
  }

  void onRegister() async {
    if (regName.text.trim().isEmpty ||
        regEmail.text.trim().isEmpty ||
        regPassword.text.trim().isEmpty) {
      _showCustomSnackBar(message: "Please fill all fields", isSuccess: false);
      return;
    }

    setState(() => isLoading = true);

    final res = await ApiService.register(
      name: regName.text.trim(),
      email: regEmail.text.trim(),
      password: regPassword.text.trim(),
    );

    setState(() => isLoading = false);

    _showCustomSnackBar(
      message: res["data"]["message"] ?? "Registration successful!",
      isSuccess: res["status"] == 200,
    );

    if (res["status"] == 200) {
      await Future.delayed(const Duration(milliseconds: 1500));
      setState(() => currentView = AuthView.login);
    }
  }

  void _switchView(AuthView view) {
    _formController.reverse().then((_) {
      setState(() => currentView = view);
      _formController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              bool isMobile = constraints.maxWidth < 800;

              if (isMobile) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xff5B3DF5).withOpacity(0.05),
                        Colors.white,
                        const Color(0xffE6E0FF).withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Center(
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              children: [
                                _buildAnimatedLogo(),
                                const SizedBox(height: 40),
                                _buildAnimatedForm(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            const Color(0xff5B3DF5).withOpacity(0.02),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 80),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: _buildAnimatedForm(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xffE6E0FF),
                            const Color(0xff5B3DF5).withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Stack(
                        children: [
                          _buildFloatingCircles(),
                          Center(
                            child: ScaleTransition(
                              scale: _imageScaleAnimation,
                              child: SvgPicture.asset(
                                "assets/login.svg",
                                width: 420,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Loading Overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xff5B3DF5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Please wait...",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFloatingCircles() {
    return Stack(
      children: [
        _buildAnimatedCircle(size: 200, top: -50, right: -50, duration: 3000),
        _buildAnimatedCircle(size: 150, bottom: -30, left: -30, duration: 4000),
        _buildAnimatedCircle(size: 100, top: 100, left: 50, duration: 3500),
      ],
    );
  }

  Widget _buildAnimatedCircle({
    required double size,
    double? top,
    double? bottom,
    double? left,
    double? right,
    required int duration,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.2),
        duration: Duration(milliseconds: duration),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.white.withOpacity(0.3), Colors.transparent],
                ),
              ),
            ),
          );
        },
        onEnd: () => setState(() {}),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xff5B3DF5), const Color(0xff7C3AED)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff5B3DF5).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.shopping_bag,
              size: 40,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedForm() {
    return SlideTransition(
      position: _formSlideAnimation,
      child: FadeTransition(
        opacity: _formFadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    switch (currentView) {
      case AuthView.login:
        return _loginView();
      case AuthView.register:
        return _registerView();
      case AuthView.forgot:
        return _forgotView();
    }
  }

  Widget _loginView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("Welcome Back 👋", "Login to access your dashboard"),
        const SizedBox(height: 28),
        _label("Email"),
        _animatedInput(
          "Enter your email",
          controller: loginEmail,
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 20),
        _label("Password"),
        _animatedPasswordInput(controller: loginPassword),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: rememberMe
                        ? const Color(0xff5B3DF5)
                        : Colors.transparent,
                    border: Border.all(
                      color: rememberMe ? const Color(0xff5B3DF5) : Colors.grey,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Checkbox(
                    value: rememberMe,
                    onChanged: (v) => setState(() => rememberMe = v!),
                    activeColor: Colors.transparent,
                    checkColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text("Remember me", style: GoogleFonts.poppins(fontSize: 13)),
              ],
            ),
            _link("Forgot password?", () => _switchView(AuthView.forgot)),
          ],
        ),
        _animatedButton("Login", onTap: onLogin, icon: Icons.login),
        const SizedBox(height: 16),
        _bottomText(
          "Don't have an account? ",
          "Register",
          () => _switchView(AuthView.register),
        ),
      ],
    );
  }

  Widget _registerView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("Create Account", "Sign up to get started"),
        const SizedBox(height: 28),
        _label("Full Name"),
        _animatedInput(
          "Enter your name",
          controller: regName,
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 20),
        _label("Email"),
        _animatedInput(
          "Enter your email",
          controller: regEmail,
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 20),
        _label("Password"),
        _animatedPasswordInput(controller: regPassword),
        _animatedButton(
          "Create Account",
          onTap: onRegister,
          icon: Icons.person_add,
        ),
        const SizedBox(height: 16),
        _bottomText(
          "Already have an account? ",
          "Login",
          () => _switchView(AuthView.login),
        ),
      ],
    );
  }

  Widget _forgotView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title("Forgot Password?", "Enter your email to reset"),
        const SizedBox(height: 28),
        _label("Email"),
        _animatedInput(
          "Enter your email",
          controller: forgotEmail,
          icon: Icons.email_outlined,
        ),
        _animatedButton(
          "Send Reset Link",
          onTap: () {
            _showCustomSnackBar(
              message: "Reset link sent to your email!",
              isSuccess: true,
            );
          },
          icon: Icons.send,
        ),
        const SizedBox(height: 16),
        _bottomText(
          "Remember password? ",
          "Login",
          () => _switchView(AuthView.login),
        ),
      ],
    );
  }

  Widget _title(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xff1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: const Color(0xff6B7280),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xff374151),
        ),
      ),
    );
  }

  Widget _animatedInput(
    String hint, {
    required TextEditingController controller,
    required IconData icon,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff5B3DF5).withOpacity(0.1 * value),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  icon,
                  color: const Color(0xff5B3DF5),
                  size: 20,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xff5B3DF5),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _animatedPasswordInput({required TextEditingController controller}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff5B3DF5).withOpacity(0.1 * value),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              obscureText: !showPassword,
              style: GoogleFonts.poppins(fontSize: 14),
              decoration: InputDecoration(
                hintText: "Enter your password",
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Color(0xff5B3DF5),
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    size: 20,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xff5B3DF5),
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _animatedButton(
    String text, {
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff5B3DF5), Color(0xff7C3AED)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff5B3DF5).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      text,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _link(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xff5B3DF5),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _bottomText(String text, String action, VoidCallback onTap) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            children: [
              TextSpan(text: text),
              TextSpan(
                text: action,
                style: const TextStyle(
                  color: Color(0xff5B3DF5),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
