<<<<<<< HEAD
// ...existing code...
import 'package:flutter/material.dart';
import 'package:my_flutter_app/design/app_spacing.dart';
import 'package:my_flutter_app/design/app_typography.dart';
import 'package:my_flutter_app/widgets/fyt_button.dart';
import 'package:my_flutter_app/routing/app_router.dart';
=======
import 'package:flutter/material.dart';
import 'package:my_flutter_app/design/app_spacing.dart';
import 'package:my_flutter_app/design/app_typography.dart';
import 'package:my_flutter_app/features/body_metrics/models/body_metric_result.dart';
import 'package:my_flutter_app/routing/app_router.dart';
import 'package:my_flutter_app/widgets/fyt_button.dart';
>>>>>>> feature/body-metric-module-clean

class BodyProfileResultScreen extends StatelessWidget {
  const BodyProfileResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    // Example static data.
=======
    final args = ModalRoute.of(context)?.settings.arguments;
    final result = args is BodyMetricResult ? args : _fallbackResult();

>>>>>>> feature/body-metric-module-clean
    return Scaffold(
      appBar: AppBar(title: const Text('Your Body Blueprint')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: ListView(
            children: [
<<<<<<< HEAD
              Text('Body Type: Soft Rectangle',
                  style: AppTypography.subheading(context)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Proportion summary',
                style: AppTypography.label(context),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Balanced shoulders and hips with a gentle waistline. Legs slightly longer than torso.',
                style: AppTypography.body(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Styling suggestions',
                style: AppTypography.label(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              _bullet(context, 'Softly structured jackets that define the waist.'),
              _bullet(context, 'Mid-rise bottoms that keep balance between torso and legs.'),
              _bullet(context, 'Monochrome outfits to elongate your frame.'),
=======
              Text('Body Type: ${result.bodyType}',
                  style: AppTypography.subheading(context)),
              const SizedBox(height: AppSpacing.sm),
              Text('Metric summary', style: AppTypography.label(context)),
              const SizedBox(height: AppSpacing.xs),
              Text(result.proportionSummary, style: AppTypography.body(context)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'BMI: ${result.bmi.toStringAsFixed(1)} (${result.bmiCategory})',
                style: AppTypography.body(context),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Shoulder:Hip ratio: ${result.shoulderToHipRatio.toStringAsFixed(2)}',
                style: AppTypography.body(context),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Waist:Hip ratio: ${result.waistToHipRatio.toStringAsFixed(2)}',
                style: AppTypography.body(context),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Leg:Height ratio: ${result.legToHeightRatio.toStringAsFixed(2)}',
                style: AppTypography.body(context),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Styling suggestions', style: AppTypography.label(context)),
              const SizedBox(height: AppSpacing.sm),
              for (final item in result.stylingSuggestions) _bullet(context, item),
>>>>>>> feature/body-metric-module-clean
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: FytButton(
                      label: 'Back to Home',
                      onPressed: () => Navigator.popUntil(
                        context,
                        ModalRoute.withName(AppRoutes.home),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FytButton(
<<<<<<< HEAD
                      label: 'Save',
                      primary: false,
                      onPressed: () {},
=======
                      label: 'Retake',
                      primary: false,
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.bodyScan,
                        ModalRoute.withName(AppRoutes.home),
                      ),
>>>>>>> feature/body-metric-module-clean
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  '),
=======
  BodyMetricResult _fallbackResult() {
    return const BodyMetricResult(
      bodyType: 'Rectangle',
      bmi: 23.5,
      bmiCategory: 'Healthy',
      shoulderToHipRatio: 1.0,
      waistToHipRatio: 0.82,
      legToHeightRatio: 0.46,
      proportionSummary:
          'Rectangle profile. Shoulders and hips are balanced, with a softer waist transition. Leg proportion is longer relative to total height.',
      stylingSuggestions: [
        'Create shape with belted layers and tailored jackets.',
        'Use monochrome columns to visually elongate the frame.',
        'Mix texture strategically at waist level for definition.',
      ],
    );
  }

  Widget _bullet(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('- '),
>>>>>>> feature/body-metric-module-clean
          Expanded(child: Text(text, style: AppTypography.body(context))),
        ],
      ),
    );
  }
}
<<<<<<< HEAD
// ...existing code...
=======
>>>>>>> feature/body-metric-module-clean
