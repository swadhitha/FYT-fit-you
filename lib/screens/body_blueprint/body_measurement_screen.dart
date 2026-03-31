import 'package:flutter/material.dart';
import 'package:my_flutter_app/design/app_spacing.dart';
import 'package:my_flutter_app/design/app_typography.dart';
import 'package:my_flutter_app/features/body_metrics/models/body_measurement_input.dart';
import 'package:my_flutter_app/routing/app_router.dart';
import 'package:my_flutter_app/widgets/fyt_button.dart';

class BodyMeasurementScreen extends StatefulWidget {
  const BodyMeasurementScreen({super.key});

  @override
  State<BodyMeasurementScreen> createState() => _BodyMeasurementScreenState();
}

class _BodyMeasurementScreenState extends State<BodyMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();

  final _heightCtrl = TextEditingController(text: '170');
  final _weightCtrl = TextEditingController(text: '68');
  final _shoulderCtrl = TextEditingController(text: '42');
  final _chestCtrl = TextEditingController(text: '92');
  final _waistCtrl = TextEditingController(text: '78');
  final _hipCtrl = TextEditingController(text: '94');
  final _inseamCtrl = TextEditingController(text: '79');

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _shoulderCtrl.dispose();
    _chestCtrl.dispose();
    _waistCtrl.dispose();
    _hipCtrl.dispose();
    _inseamCtrl.dispose();
    super.dispose();
  }

  void _continueToAnalysis() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final input = BodyMeasurementInput(
      heightCm: double.parse(_heightCtrl.text.trim()),
      weightKg: double.parse(_weightCtrl.text.trim()),
      shoulderCm: double.parse(_shoulderCtrl.text.trim()),
      chestCm: double.parse(_chestCtrl.text.trim()),
      waistCm: double.parse(_waistCtrl.text.trim()),
      hipCm: double.parse(_hipCtrl.text.trim()),
      inseamCm: double.parse(_inseamCtrl.text.trim()),
    );

    Navigator.pushNamed(
      context,
      AppRoutes.bodyAnalysis,
      arguments: input,
    );
  }

  String? _validateMeasurement(String? value, {required double min, required double max}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Required';
    }

    final parsed = double.tryParse(text);
    if (parsed == null) {
      return 'Enter a valid number';
    }

    if (parsed < min || parsed > max) {
      return 'Use $min - $max';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Body Measurements')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text('Enter your measurements', style: AppTypography.heading(context)),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Use centimeters and kilograms. These values are only used to create your body profile.',
                  style: AppTypography.body(context),
                ),
                const SizedBox(height: AppSpacing.lg),
                _field(
                  label: 'Height (cm)',
                  controller: _heightCtrl,
                  min: 120,
                  max: 230,
                ),
                _field(
                  label: 'Weight (kg)',
                  controller: _weightCtrl,
                  min: 30,
                  max: 250,
                ),
                _field(
                  label: 'Shoulder Width (cm)',
                  controller: _shoulderCtrl,
                  min: 25,
                  max: 70,
                ),
                _field(
                  label: 'Chest/Bust (cm)',
                  controller: _chestCtrl,
                  min: 55,
                  max: 180,
                ),
                _field(
                  label: 'Waist (cm)',
                  controller: _waistCtrl,
                  min: 45,
                  max: 180,
                ),
                _field(
                  label: 'Hip (cm)',
                  controller: _hipCtrl,
                  min: 55,
                  max: 200,
                ),
                _field(
                  label: 'Inseam/Leg Length (cm)',
                  controller: _inseamCtrl,
                  min: 45,
                  max: 120,
                ),
                const SizedBox(height: AppSpacing.xl),
                FytButton(
                  label: 'Analyze My Body Metrics',
                  onPressed: _continueToAnalysis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required double min,
    required double max,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) => _validateMeasurement(value, min: min, max: max),
        decoration: InputDecoration(
          labelText: label,
        ),
      ),
    );
  }
}
