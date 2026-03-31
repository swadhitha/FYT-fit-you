import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../design/app_colors.dart';
import '../../widgets/fyt_button.dart';
import '../../routing/app_router.dart';
import '../../providers/user_provider.dart';
import '../../providers/recommendation_provider.dart';

class MoodConfidenceScreen extends StatefulWidget {
  const MoodConfidenceScreen({super.key});

  @override
  State<MoodConfidenceScreen> createState() => _MoodConfidenceScreenState();
}

class _MoodConfidenceScreenState extends State<MoodConfidenceScreen> {
  final _notesCtrl = TextEditingController();
  String _selectedMood = 'Confident';

  final _moods = ['Relaxed', 'Confident', 'Bold', 'Minimal', 'Playful'];

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _getRecommendations() async {
    final recProvider = context.read<RecommendationProvider>();
    final userId = context.read<UserProvider>().userId;

    recProvider.setMood(_selectedMood);
    if (_notesCtrl.text.trim().isNotEmpty) {
      recProvider.setAdditionalNotes(_notesCtrl.text.trim());
    }

    await recProvider.fetchRecommendations(userId);

    if (mounted) {
      if (recProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(recProvider.error!)),
        );
      } else {
        Navigator.pushNamed(context, AppRoutes.outfitRecommendation);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final occasion = context.watch<RecommendationProvider>().selectedOccasion;
    final loading = context.watch<RecommendationProvider>().loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Tune Your Look')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (occasion != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.accentLavender.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Styling for: $occasion',
                      style: AppTypography.label(context)),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],
              Text('How do you want to feel?',
                  style: AppTypography.heading(context)),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _moods
                    .map((m) => ChoiceChip(
                          label: Text(m),
                          selected: _selectedMood == m,
                          onSelected: (_) =>
                              setState(() => _selectedMood = m),
                          selectedColor:
                              AppColors.accentLavender.withOpacity(0.4),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Any other specifications?',
                  style: AppTypography.subheading(context)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  hintText:
                      'e.g. prefer bright colors, no prints, cotton only...',
                ),
                minLines: 1,
                maxLines: 3,
              ),
              const Spacer(),
              if (loading)
                const Center(child: CircularProgressIndicator())
              else
                FytButton(
                  label: 'Get My Outfit',
                  onPressed: _getRecommendations,
                ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
