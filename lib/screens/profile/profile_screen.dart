import 'package:flutter/material.dart';
import 'package:my_flutter_app/design/app_spacing.dart';
import 'package:my_flutter_app/design/app_typography.dart';
import 'package:my_flutter_app/design/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: ListView(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accentLavender,
                  child: Text('U', style: AppTypography.subheading(context)),
                ),
                title: Text('User', style: AppTypography.subheading(context)),
                subtitle: Text('Minimal • Tropical climate',
                    style: AppTypography.body(context)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Body Blueprint', style: AppTypography.label(context)),
              const SizedBox(height: AppSpacing.xs),
              Text('Not yet scanned',
                  style: AppTypography.body(context)),
              const SizedBox(height: AppSpacing.lg),
              Text('Wardrobe Efficiency', style: AppTypography.label(context)),
              const SizedBox(height: AppSpacing.xs),
              Text('Add wardrobe items to see efficiency.',
                  style: AppTypography.body(context)),
              const SizedBox(height: AppSpacing.lg),
              Text('Saved Outfits', style: AppTypography.label(context)),
              const SizedBox(height: AppSpacing.xs),
              Text('0 looks saved', style: AppTypography.body(context)),
              const SizedBox(height: AppSpacing.lg),
              Text('Preferences', style: AppTypography.label(context)),
              const SizedBox(height: AppSpacing.xs),
              Text('Preferences will be learned from your interactions.',
                  style: AppTypography.body(context)),
              const SizedBox(height: AppSpacing.xl),
              Text('Settings', style: AppTypography.label(context)),
              const SizedBox(height: AppSpacing.sm),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Account', style: AppTypography.body(context)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title:
                    Text('Notifications', style: AppTypography.body(context)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}