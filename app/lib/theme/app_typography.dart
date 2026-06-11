import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle get displayLarge => GoogleFonts.fredoka(
        fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.ink);

  static TextStyle get headlineMedium => GoogleFonts.fredoka(
        fontSize: 24, fontWeight: FontWeight.w500, color: AppColors.ink);

  static TextStyle get titleMedium => GoogleFonts.fredoka(
        fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.ink);

  static TextStyle get bodyLarge => GoogleFonts.nunito(
        fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.ink);

  static TextStyle get bodyMedium => GoogleFonts.nunito(
        fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.inkSoft);

  static TextStyle get labelLarge => GoogleFonts.nunito(
        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink);

  static TextStyle get labelSmall => GoogleFonts.nunito(
        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.inkSoft);
}
