import 'package:demo/utils/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
class AppTextStyles {
  static final title = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static final subtitle = GoogleFonts.poppins(
    fontSize: 14,
    color: AppColors.textSecondary,
  );

  static final label = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  static final input = GoogleFonts.poppins(
    fontSize: 14,
    height: 1.2,
  );

  static final button = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
}
