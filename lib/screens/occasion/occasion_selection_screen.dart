// ...existing code...
import 'package:flutter/material.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../widgets/fyt_card.dart';
import '../../design/responsive.dart';
import '../../routing/app_routes.dart';

class OccasionSelectionScreen extends StatelessWidget {
  const OccasionSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final occasions = [
      'College',
      'Office',
      'Wedding',
      'Casual',
      'Date',
      'Presentation',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Occasion Mode')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: GridView.count(
            crossAxisCount:
                Responsive.sizeOf(context) == DeviceSize.tablet ? 3 : 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            children: occasions
                .map((o) => FytCard(
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.moodConfidence,
                        arguments: o,
                      ),
                      child: Center(
                        child: Text(
                          o,
                          style: AppTypography.subheading(context),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}
// ...existing code...