import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:my_flutter_app/design/app_spacing.dart';
import 'package:my_flutter_app/design/app_typography.dart';
import 'package:my_flutter_app/features/body_metrics/models/body_measurement_input.dart';
import 'package:my_flutter_app/features/body_metrics/models/body_metric_result.dart';
import 'package:my_flutter_app/routing/app_router.dart';
import 'package:my_flutter_app/providers/body_metric_provider.dart';
import 'package:my_flutter_app/providers/user_provider.dart';

class BodyAnalysisScreen extends StatefulWidget {
  const BodyAnalysisScreen({super.key});

  @override
  State<BodyAnalysisScreen> createState() => _BodyAnalysisScreenState();
}

class _BodyAnalysisScreenState extends State<BodyAnalysisScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final userId = context.read<UserProvider>().userId;
    final bodyProvider = context.read<BodyMetricProvider>();

    bool success = false;

    if (args is Map<String, dynamic>) {
      // It's a scan result
      success = await bodyProvider.saveProfileFromScan(
        userId: userId,
        scanResult: args,
      );
    } else if (args is BodyMeasurementInput) {
      // Manual input
      success = await bodyProvider.saveProfile(
        userId: userId,
        heightCm: args.heightCm,
        weightKg: args.weightKg,
        shoulderCm: args.shoulderCm,
        chestCm: args.chestCm,
        waistCm: args.waistCm,
        hipCm: args.hipCm,
        inseamCm: args.inseamCm,
      );
    }

    if (!mounted) return;

    if (success && bodyProvider.profile != null) {
      final p = bodyProvider.profile!;
      final result = BodyMetricResult(
        bodyType: p.bodyType,
        bmi: p.bmi,
        bmiCategory: p.bmiCategory,
        shoulderToHipRatio: p.shoulderToHipRatio,
        waistToHipRatio: p.waistToHipRatio,
        legToHeightRatio: p.legToHeightRatio,
        proportionSummary: p.proportionSummary,
        stylingSuggestions: p.stylingSuggestions,
      );

      Navigator.pushReplacementNamed(
        context,
        AppRoutes.bodyResult,
        arguments: result,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(bodyProvider.error ?? 'Analysis failed')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSpacing.lg),
                Text('FYT Intelligence at work...',
                    style: AppTypography.subheading(context)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Processing proportions to build your body metric profile.',
                  style: AppTypography.body(context),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
