import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Headings (Plus Jakarta Sans, Bold, letter-spacing -0.5)
  static TextStyle heading1({required bool isDark}) => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
        height: 1.2,
      );

  static TextStyle heading2({required bool isDark}) => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
        height: 1.25,
      );

  static TextStyle heading3({required bool isDark}) => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
        height: 1.3,
      );

  static TextStyle title({required bool isDark}) => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
      );

  static TextStyle titleMedium({required bool isDark}) => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
      );

  // Body text (Regular, 15sp, line-height 1.6)
  static TextStyle body({required bool isDark}) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.normal,
        height: 1.6,
        color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary,
      );

  static TextStyle bodyBold({required bool isDark}) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        height: 1.6,
        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
      );

  static TextStyle bodyMuted({required bool isDark}) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        height: 1.5,
        color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
      );

  // Labels (Medium, 12sp, letter-spacing 1.2, UPPERCASE)
  static TextStyle label({required bool isDark}) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.2,
        color: isDark ? AppColors.textMuted : AppColors.lightTextMuted,
      );

  // Numbers (DM Mono for stats and confidence %)
  static TextStyle number({required bool isDark, double fontSize = 16, FontWeight fontWeight = FontWeight.normal}) =>
      GoogleFonts.dmMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
      );
}
