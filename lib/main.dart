import 'package:flutter/material.dart';

void main() {
  runApp(const DemoWebPage());
}

class DemoWebPage extends StatelessWidget {
  const DemoWebPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Client Demo Page',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatelessWidget {
  const DemoHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Header(),
            const HeroSection(),
            const FeaturesSection(),
            const Footer(),
          ],
        ),
      ),
    );
  }
}

// ------------------ Header ------------------
class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '🌟 MyDemoApp',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              TextButton(onPressed: () {}, child: const Text('Home')),
              TextButton(onPressed: () {}, child: const Text('Features')),
              TextButton(onPressed: () {}, child: const Text('Contact')),
              const SizedBox(width: 12),
              ElevatedButton(onPressed: () {}, child: const Text('Get Started')),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------ Hero Section ------------------
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
      color: Colors.deepPurple[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Welcome to My Demo Page',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'This is a clean and modern Flutter web page you can customize for your client project.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16)),
            child: const Text('Explore Now'),
          ),
        ],
      ),
    );
  }
}

// ------------------ Features Section ------------------
class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        children: [
          const Text(
            'Amazing Features',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: const [
              FeatureCard(
                icon: Icons.speed,
                title: 'Fast Performance',
                description: 'Optimized for speed and smooth UI rendering.',
              ),
              FeatureCard(
                icon: Icons.mobile_friendly,
                title: 'Responsive Design',
                description: 'Looks great on mobile, tablet and desktop.',
              ),
              FeatureCard(
                icon: Icons.security,
                title: 'Secure & Reliable',
                description: 'Built with security and best practices in mind.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const FeatureCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.deepPurple),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ------------------ Footer ------------------
class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.deepPurple,
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Text(
          '© 2025 MyDemoApp. All rights reserved.',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}