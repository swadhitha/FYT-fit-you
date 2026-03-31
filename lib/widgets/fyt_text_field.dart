import 'package:flutter/material.dart';
import '../design/app_typography.dart';

class FytTextField extends StatelessWidget {
  final String label;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextEditingController? controller;

  const FytTextField({
    super.key,
    required this.label,
    this.obscure = false,
    this.keyboardType,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label(context)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
        ),
      ],
    );
  }
}