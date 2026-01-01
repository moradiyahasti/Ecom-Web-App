import 'package:demo/widget/app_text_styles.dart';
import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AuthInput extends StatelessWidget {
  final String hint;
  final bool obscure;
  final Widget? suffix;

  const AuthInput({
    super.key,
    required this.hint,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscure,
      style: AppTextStyles.input,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:  BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
