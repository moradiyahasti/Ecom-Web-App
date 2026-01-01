import 'package:flutter/material.dart';

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

  // ---------------- DESKTOP ----------------
  Widget _desktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _aboutSection()),
        SizedBox(width: 30),
        Expanded(child: _quickLinks()),
        Expanded(child: _services()),
        Expanded(child: _contactInfo()),
      ],
    );
  }

  // ---------------- MOBILE ----------------
  Widget _mobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _aboutSection(),
        const SizedBox(height: 24),

        /// 👇 QUICK LINKS + SERVICES in 2 columns
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

  // ---------------- SECTIONS ----------------

  Widget _aboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Shope Name",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12),
        Text(
          "Discover smart, stylish and affordable solutions for your home and kitchen. "
          "We’re here to make modern living easier with practical, innovative and valuable products all in one place.",
          style: TextStyle(color: Colors.grey, height: 1.6),
        ),
      ],
    );
  }

  Widget _quickLinks() {
    return _linkColumn("QUICK LINKS", [
      "Product Number 1",
      "Product Number 2",
      "Product Number 3",
      "Product Number 4",
      "Product Number 5",
      "Product Number 6",
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
    crossAxisAlignment:
        center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
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

      Text("Phone:",
          style: const TextStyle(color: Colors.white),
          textAlign: center ? TextAlign.center : TextAlign.start),
      const SizedBox(height: 4),
      Text("+91 1234567890",
          style: const TextStyle(color: Colors.grey),
          textAlign: center ? TextAlign.center : TextAlign.start),

      const SizedBox(height: 12),

      Text("Email:",
          style: const TextStyle(color: Colors.white),
          textAlign: center ? TextAlign.center : TextAlign.start),
      const SizedBox(height: 4),
      Text("support@gmail.com",
          style: const TextStyle(color: Colors.grey),
          textAlign: center ? TextAlign.center : TextAlign.start),

      const SizedBox(height: 16),

      Column(
        crossAxisAlignment:
            center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text("Follow us:",
              style: const TextStyle(color: Colors.white),
              textAlign: center ? TextAlign.center : TextAlign.start),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment:
                center ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              _socialIcon(
                icon: Icons.camera_alt,
                color: Colors.white,
                onTap: () {},
              ),
              const SizedBox(width: 12),
              _socialIcon(
                icon: Icons.wifi_password,
                color: Colors.white,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    ],
  );
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

  // ---------------- BOTTOM BAR ----------------

  Widget _bottomBar(bool isMobile) {
    return isMobile
        ? Column(
            children: const [
              Text("© 2025 By Ind2c", style: TextStyle(color: Colors.grey)),
              SizedBox(height: 10),
              _PaymentIcons(),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "© 2025 By shope name",
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.credit_card, color: Colors.white),
        SizedBox(width: 8),
        Icon(Icons.payment, color: Colors.white),
        SizedBox(width: 8),
        Icon(Icons.account_balance_wallet, color: Colors.white),
      ],
    );
  }
}
