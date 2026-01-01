import 'package:flutter/material.dart';

class AuthLayout extends StatelessWidget {
  final String title, subtitle, buttonText, bottomText, bottomAction;
  final VoidCallback onBottomTap;
  final Widget child;

  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.bottomText,
    required this.bottomAction,
    required this.onBottomTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff5A5DE8), Color(0xff7F82FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 80),
            const Text(
              "Jobsly",
              style: TextStyle(color: Colors.white, fontSize: 26),
            ),
            const SizedBox(height: 40),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(subtitle,
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 30),

                      child,

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff6C6FF5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: () {},
                          child: Text(buttonText),
                        ),
                      ),

                      const SizedBox(height: 20),
                      if (bottomText.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(bottomText),
                            TextButton(
                              onPressed: onBottomTap,
                              child: Text(bottomAction),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
