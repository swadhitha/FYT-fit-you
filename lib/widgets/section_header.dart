import 'package:flutter/material.dart';
import '../design/app_spacing.dart';
import '../design/app_typography.dart';

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: AppTypography.label(context).copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}