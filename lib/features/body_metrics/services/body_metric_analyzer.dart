import '../models/body_measurement_input.dart';
import '../models/body_metric_result.dart';

class BodyMetricAnalyzer {
  const BodyMetricAnalyzer();

  BodyMetricResult analyze(BodyMeasurementInput input) {
    final heightM = input.heightCm / 100;
    final bmi = input.weightKg / (heightM * heightM);
    final waistToHipRatio = input.waistCm / input.hipCm;
    final shoulderToHipRatio = input.shoulderCm / input.hipCm;
    final legToHeightRatio = input.inseamCm / input.heightCm;

    final bodyType = _detectBodyType(
      shoulderToHipRatio: shoulderToHipRatio,
      waistCm: input.waistCm,
      shoulderCm: input.shoulderCm,
      hipCm: input.hipCm,
      chestCm: input.chestCm,
    );

    return BodyMetricResult(
      bodyType: bodyType,
      bmi: bmi,
      bmiCategory: _bmiCategory(bmi),
      shoulderToHipRatio: shoulderToHipRatio,
      waistToHipRatio: waistToHipRatio,
      legToHeightRatio: legToHeightRatio,
      proportionSummary: _buildSummary(
        bodyType: bodyType,
        shoulderToHipRatio: shoulderToHipRatio,
        waistToHipRatio: waistToHipRatio,
        legToHeightRatio: legToHeightRatio,
      ),
      stylingSuggestions: _suggestionsFor(bodyType),
    );
  }

  String _detectBodyType({
    required double shoulderToHipRatio,
    required double waistCm,
    required double shoulderCm,
    required double hipCm,
    required double chestCm,
  }) {
    final waistReference = shoulderCm < hipCm ? shoulderCm : hipCm;
    final hasDefinedWaist = waistCm <= waistReference * 0.75;
    final chestToHipRatio = chestCm / hipCm;

    if (hasDefinedWaist && shoulderToHipRatio >= 0.95 && shoulderToHipRatio <= 1.05) {
      return 'Hourglass';
    }
    if (shoulderToHipRatio > 1.05 || chestToHipRatio > 1.05) {
      return 'Inverted Triangle';
    }
    if (shoulderToHipRatio < 0.95 || chestToHipRatio < 0.95) {
      return 'Triangle';
    }
    return 'Rectangle';
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    }
    if (bmi < 25) {
      return 'Healthy';
    }
    if (bmi < 30) {
      return 'Overweight';
    }
    return 'Obese';
  }

  String _buildSummary({
    required String bodyType,
    required double shoulderToHipRatio,
    required double waistToHipRatio,
    required double legToHeightRatio,
  }) {
    final shoulderHipText = shoulderToHipRatio > 1.05
        ? 'Shoulders read broader than hips'
        : shoulderToHipRatio < 0.95
            ? 'Hips read broader than shoulders'
            : 'Shoulders and hips are balanced';

    final waistHipText = waistToHipRatio <= 0.8
        ? 'with a defined waistline'
        : 'with a softer waist transition';

    final legText = legToHeightRatio >= 0.46
        ? 'Leg proportion is longer relative to total height.'
        : 'Torso proportion is slightly longer relative to legs.';

    return '$bodyType profile. $shoulderHipText, $waistHipText. $legText';
  }

  List<String> _suggestionsFor(String bodyType) {
    switch (bodyType) {
      case 'Hourglass':
        return const [
          'Highlight the waist with structured or wrap silhouettes.',
          'Choose balanced shoulder and hip detailing.',
          'Prefer mid to high-rise bottoms for proportion continuity.',
        ];
      case 'Inverted Triangle':
        return const [
          'Use softer shoulder lines and avoid heavy shoulder pads.',
          'Add visual weight in bottoms with pleats or fuller cuts.',
          'Keep necklines open to reduce upper-body width emphasis.',
        ];
      case 'Triangle':
        return const [
          'Add structure or detail to the upper body and shoulders.',
          'Use darker, cleaner lines for bottoms.',
          'A-line and fit-and-flare shapes keep visual balance.',
        ];
      default:
        return const [
          'Create shape with belted layers and tailored jackets.',
          'Use monochrome columns to visually elongate the frame.',
          'Mix texture strategically at waist level for definition.',
        ];
    }
  }
}
