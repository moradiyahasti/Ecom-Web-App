import 'package:demo/widget/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AuthButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const AuthButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
        ),
        onPressed: onTap,
        child: Text(text, style: AppTextStyles.button),
      ),
    );
  }
}
