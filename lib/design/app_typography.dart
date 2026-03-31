import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Display styles with Playfair Display
  static TextStyle displayLarge(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 390;
    final fontSize = (32 * scale.clamp(0.9, 1.2)).toDouble();
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle headlineMedium(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 390;
    final fontSize = (24 * scale.clamp(0.9, 1.2)).toDouble();
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle titleLarge(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 390;
    final fontSize = (20 * scale.clamp(0.9, 1.15)).toDouble();
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    );
  }

  // Body styles with Inter
  static TextStyle bodyLarge(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 390;
    final fontSize = (16 * scale.clamp(0.9, 1.1)).toDouble();
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.textSecondary,
    );
  }

  static TextStyle bodyMedium(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 390;
    final fontSize = (14 * scale.clamp(0.9, 1.1)).toDouble();
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: AppColors.textSecondary,
    );
  }

  static TextStyle bodySmall(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 390;
    final fontSize = (12 * scale.clamp(0.9, 1.1)).toDouble();
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: AppColors.textSecondary,
    );
  }

  static TextStyle labelLarge(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 390;
    final fontSize = (14 * scale.clamp(0.9, 1.1)).toDouble();
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    );
  }

  static TextStyle labelMedium(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 390;
    final fontSize = (12 * scale.clamp(0.9, 1.1)).toDouble();
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
    );
  }

  // Legacy methods for compatibility
  static TextStyle heading(BuildContext context) {
    return headlineMedium(context);
  }

  static TextStyle subheading(BuildContext context) {
    return titleLarge(context);
  }

  static TextStyle body(BuildContext context) {
    return bodyMedium(context);
  }

  static TextStyle label(BuildContext context) {
    return labelMedium(context);
  }

  static TextStyle button(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 390;
    final fontSize = (15 * scale.clamp(0.9, 1.1)).toDouble();
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.3,
      color: AppColors.textPrimary,
    );
  }
}