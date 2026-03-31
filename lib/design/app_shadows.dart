import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppShadows {
  static List<BoxShadow> softCard = [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.04),
      blurRadius: 18,
      spreadRadius: 1,
      offset: const Offset(0, 8),
    ),
  ];
}