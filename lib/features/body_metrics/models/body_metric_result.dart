class BodyMetricResult {
  final String bodyType;
  final double bmi;
  final String bmiCategory;
  final double shoulderToHipRatio;
  final double waistToHipRatio;
  final double legToHeightRatio;
  final String proportionSummary;
  final List<String> stylingSuggestions;

  const BodyMetricResult({
    required this.bodyType,
    required this.bmi,
    required this.bmiCategory,
    required this.shoulderToHipRatio,
    required this.waistToHipRatio,
    required this.legToHeightRatio,
    required this.proportionSummary,
    required this.stylingSuggestions,
  });
}
