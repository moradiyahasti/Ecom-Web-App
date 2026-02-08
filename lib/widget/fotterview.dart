import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart';

// ==================== MAIN WIDGET ====================
// આ widget તમારા HomePage માં use કરો
class FooterWithContactSection extends StatelessWidget {
  final String? userEmail;
  final String? userName;

  const FooterWithContactSection({super.key, this.userEmail, this.userName});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 👇 Contact Form Section
        ContactFormSection(userEmail: userEmail, userName: userName),
        // 👇 Footer Section
        const FooterView(),
      ],
    );
  }
}

// ==================== CONTACT FORM SECTION ====================
class ContactFormSection extends StatefulWidget {
  final String? userEmail;
  final String? userName;

  const ContactFormSection({super.key, this.userEmail, this.userName});

  @override
  State<ContactFormSection> createState() => _ContactFormSectionState();
}

class _ContactFormSectionState extends State<ContactFormSection> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _queryController = TextEditingController();
  bool _isSubmitting = false;

  // 🔥 YOUR API ENDPOINT
  // static const String API_URL =
  static const String API_URL =
      "https://shreenails.com/routes/contact.php"; // static const String API_URL = 'http://192.168.29.212:5000/api/contact';

  @override
  void initState() {
    super.initState();
    // Auto-fill logged-in user info
    if (widget.userEmail != null) {
      _emailController.text = widget.userEmail!;
    }
    if (widget.userName != null) {
      _nameController.text = widget.userName!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      print('📤 Sending request to: $API_URL');
      print(
        '📤 Data: ${json.encode({'name': _nameController.text.trim(), 'email': _emailController.text.trim(), 'address': _addressController.text.trim(), 'query': _queryController.text.trim()})}',
      );

      final response = await http
          .post(
            Uri.parse(API_URL),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'address': _addressController.text.trim(),
              'query': _queryController.text.trim(),
            }),
          )
          .timeout(
            const Duration(seconds: 30), // Increased timeout
            onTimeout: () {
              throw Exception(
                'Connection timeout - Server took too long to respond',
              );
            },
          );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          _showSuccessDialog();
          _formKey.currentState!.reset();
          _nameController.clear();
          _emailController.clear();
          _addressController.clear();
          _queryController.clear();
        } else {
          _showErrorSnackbar(data['message'] ?? 'Failed to send message');
        }
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body);
        _showErrorSnackbar(data['message'] ?? 'Invalid data');
      } else if (response.statusCode == 500) {
        _showErrorSnackbar('Server error. Please contact support.');
      } else {
        _showErrorSnackbar('Unexpected error (${response.statusCode})');
      }
    } on SocketException catch (e) {
      print('❌ Network Error: $e');
      if (mounted) {
        _showErrorSnackbar(
          'No internet connection. Please check your network.',
        );
      }
    } on TimeoutException catch (e) {
      print('❌ Timeout Error: $e');
      if (mounted) {
        _showErrorSnackbar('Request timeout. Server is not responding.');
      }
    } on FormatException catch (e) {
      print('❌ JSON Error: $e');
      if (mounted) {
        _showErrorSnackbar('Invalid response from server.');
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        _showErrorSnackbar('Failed to connect: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.deepPurple.shade400,
                  size: 60,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Message Sent! 🎉',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Thank you for contacting us!\nWe\'ll get back to you soon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple.shade400,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.deepPurple.shade50, Colors.purple.shade50],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 60,
        vertical: isMobile ? 40 : 80,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: isMobile ? _mobileLayout() : _desktopLayout(),
        ),
      ),
    );
  }

  Widget _desktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: _leftSection()),
        const SizedBox(width: 60),
        Expanded(flex: 5, child: _formSection()),
      ],
    );
  }

  Widget _mobileLayout() {
    return Column(
      children: [_leftSection(), const SizedBox(height: 40), _formSection()],
    );
  }

  Widget _leftSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '✨ GET IN TOUCH',
            style: TextStyle(
              color: Colors.deepPurple,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'તમારો સંપર્ક,\nઅમારો આનંદ',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.bold,
            height: 1.2,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'તમને કોઈપણ પ્રશ્ન હોય અથવા માર્ગદર્શનની જરૂર હોય તો કૃપા કરીને અમને સંદેશ મોકલો. અમારી ટીમ શક્ય તેટલી વહેલી તકે આપને પ્રતિસાદ આપશે.',
          style: TextStyle(
            fontSize: 16,
            height: 1.7,
            color: Colors.grey.shade700,
          ),
        ),

        const SizedBox(height: 30),
        _infoCard(
          icon: Icons.location_on_rounded,
          title: 'Visit Us',
          subtitle: 'Mota varachha, Surat - 394105',
          color: Colors.deepPurple,
        ),
        const SizedBox(height: 16),
        _infoCard(
          icon: Icons.phone_rounded,
          title: 'Call Us',
          subtitle: '+91 9925503530',
          color: Colors.purple,
        ),
        const SizedBox(height: 16),
        _infoCard(
          icon: Icons.email_rounded,
          title: 'Email Us',
          subtitle: 'shreenailsoff@gmail.com',
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _formSection() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Send us a Message',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill out the form below and we\'ll get back to you soon',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _nameController,
              label: 'Your Name',
              hint: 'Enter your full name',
              icon: Icons.person_outline_rounded,
              enabled: widget.userName == null,
              validator: (val) =>
                  val?.trim().isEmpty ?? true ? 'Name is required' : null,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'your.email@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              enabled: widget.userEmail == null,
              validator: (val) {
                if (val?.trim().isEmpty ?? true) return 'Email is required';
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(val!)) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _addressController,
              label: 'Address',
              hint: 'Your address',
              icon: Icons.home_outlined,
              validator: (val) =>
                  val?.trim().isEmpty ?? true ? 'Address is required' : null,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _queryController,
              label: 'Your Message',
              hint: 'Tell us how we can help you...',
              icon: Icons.message_outlined,
              maxLines: 5,
              validator: (val) => val?.trim().isEmpty ?? true
                  ? 'Please enter your message'
                  : null,
            ),
            const SizedBox(height: 32),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: Colors.deepPurple.shade300),
            filled: true,
            fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade200,
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
              borderSide: BorderSide(
                color: Colors.deepPurple.shade300,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitForm,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple.shade400,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Send Message',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 8),
                Icon(Icons.send_rounded, size: 20),
              ],
            ),
    );
  }
}

// ==================== FOOTER VIEW ====================
class FooterView extends StatelessWidget {
  const FooterView({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Container(
      width: double.infinity,
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          isMobile ? _mobileLayout() : _desktopLayout(),
          const SizedBox(height: 30),
          const Divider(color: Colors.grey),
          const SizedBox(height: 12),
          _bottomBar(isMobile),
        ],
      ),
    );
  }

  Widget _desktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _aboutSection()),
        const SizedBox(width: 30),
        Expanded(child: _quickLinks()),
        Expanded(child: _services()),
        Expanded(child: _contactInfo()),
      ],
    );
  }

  Widget _mobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _aboutSection(),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _quickLinks()),
            const SizedBox(width: 24),
            Expanded(child: _services()),
          ],
        ),
        const SizedBox(height: 24),
        _contactInfo(),
      ],
    );
  }

  Widget _aboutSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Shree Nails",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Text(
          "Discover stylish, trendy and affordable nail services designed to enhance your beauty. "
          "We’re here to create flawless nails with modern designs, expert care and premium-quality products all in one place.",
          style: TextStyle(color: Colors.grey, height: 1.6),
        ),
      ],
    );
  }

  Widget _quickLinks() {
    return _linkColumn("QUICK LINKS", [
      "Nail Art Designs",
      "Gel Nails",
      "Acrylic Nails",
      "Nail Extensions",
      "Bridal Nail Art",
      "Nail Care Services",
    ]);
  }

  Widget _services() {
    return _linkColumn("SERVICES", [
      "About Us",
      "Contact Us",
      "Privacy Policy",
      "Shipping Policy",
      "Terms & Condition",
      "Return & Refund Policy",
      "FAQs",
      "Blog",
    ]);
  }

  Widget _contactInfo({bool center = false}) {
    return Column(
      crossAxisAlignment: center
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          "CONTACT INFO",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 16),

        Text(
          "Email:",
          style: const TextStyle(color: Colors.white),
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 4),
        Text(
          "shreenailsoff@gmail.com",
          style: const TextStyle(color: Colors.grey),
          textAlign: center ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: center
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              "Follow us:",
              style: const TextStyle(color: Colors.white),
              textAlign: center ? TextAlign.center : TextAlign.start,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: center
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                _socialIcon(
                  icon: FontAwesomeIcons.instagram, // Instagram-like icon
                  color: Colors.white,
                  onTap: _openInstagram,
                ),
                const SizedBox(width: 12),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openInstagram() async {
    final Uri instagramUrl = Uri.parse(
      "https://www.instagram.com/shreenailco_official/",
    );

    if (await canLaunchUrl(instagramUrl)) {
      await launchUrl(instagramUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch Instagram';
    }
  }

  Widget _socialIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _linkColumn(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(e, style: const TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(bool isMobile) {
    return isMobile
        ? const Column(
            children: [
              Text(
                "© 2025 By Shree Nails",
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 10),
              _PaymentIcons(),
            ],
          )
        : const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "© 2025 By Shree Nails",
                style: TextStyle(color: Colors.grey),
              ),
              _PaymentIcons(),
            ],
          );
  }
}

class _PaymentIcons extends StatelessWidget {
  const _PaymentIcons();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.credit_card, color: Colors.white),
        SizedBox(width: 8),
        Icon(Icons.payment, color: Colors.white),
        SizedBox(width: 8),
        Icon(Icons.account_balance_wallet, color: Colors.white),
      ],
    );
  }
}
