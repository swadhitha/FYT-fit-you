import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../design/app_colors.dart';
import '../../widgets/fyt_card.dart';
import '../../design/responsive.dart';
import '../../routing/app_router.dart';
import '../../providers/recommendation_provider.dart';

class OccasionSelectionScreen extends StatelessWidget {
  const OccasionSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final occasions = [
      {'name': 'College', 'icon': Icons.school_rounded},
      {'name': 'Office', 'icon': Icons.work_rounded},
      {'name': 'Wedding', 'icon': Icons.celebration_rounded},
      {'name': 'Casual', 'icon': Icons.weekend_rounded},
      {'name': 'Date', 'icon': Icons.favorite_rounded},
      {'name': 'Presentation', 'icon': Icons.present_to_all_rounded},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Occasion Mode')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What\'s the occasion?',
                  style: AppTypography.heading(context)),
              const SizedBox(height: AppSpacing.sm),
              Text('FYT will style you for the moment.',
                  style: AppTypography.body(context)),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: GridView.count(
                  crossAxisCount:
                      Responsive.sizeOf(context) == DeviceSize.tablet ? 3 : 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  children: occasions
                      .map((o) => FytCard(
                            onTap: () {
                              context
                                  .read<RecommendationProvider>()
                                  .setOccasion(o['name'] as String);
                              Navigator.pushNamed(
                                context,
                                AppRoutes.moodConfidence,
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.accentLavender
                                        .withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(o['icon'] as IconData,
                                      color: AppColors.textPrimary, size: 24),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  o['name'] as String,
                                  style: AppTypography.subheading(context),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}