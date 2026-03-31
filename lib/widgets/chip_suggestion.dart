import 'package:flutter/material.dart';

class ChipSuggestion extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool selected;

  const ChipSuggestion({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFFD8D4F2),
      onSelected: (_) => onTap(),
    );
  }
}
