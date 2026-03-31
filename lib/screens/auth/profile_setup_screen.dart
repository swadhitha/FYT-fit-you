import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../widgets/fyt_text_field.dart';
import '../../widgets/fyt_button.dart';
import '../../routing/app_router.dart';
import '../../providers/user_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  String _selectedStyle = 'Minimal';
  String _climateRegion = 'Tropical';

  final _styles = ['Minimal', 'Classic', 'Bold'];
  final _climates = ['Temperate', 'Tropical', 'Dry', 'Cold'];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Setup')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user != null
                      ? 'Welcome, ${user.name}!'
                      : 'Tell FYT about you',
                  style: AppTypography.heading(context),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text('Style preference',
                    style: AppTypography.label(context)),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: _styles
                      .map((s) => ChoiceChip(
                            label: Text(s),
                            selected: _selectedStyle == s,
                            onSelected: (_) =>
                                setState(() => _selectedStyle = s),
                          ))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text('Climate region',
                    style: AppTypography.label(context)),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(),
                  value: _climateRegion,
                  items: _climates
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _climateRegion = v ?? 'Tropical'),
                ),
                const Spacer(),
                FytButton(
                  label: 'Continue',
                  onPressed: () => Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.home,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}