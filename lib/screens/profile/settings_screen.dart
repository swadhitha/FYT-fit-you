import 'package:flutter/material.dart';
import 'package:my_flutter_app/design/app_spacing.dart';
import 'package:my_flutter_app/design/app_typography.dart';
import 'package:my_flutter_app/design/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: ListView(
            children: [
              Text('App Settings', style: AppTypography.heading(context)),
              const SizedBox(height: AppSpacing.lg),
              _settingsTile(
                context,
                icon: Icons.cloud_outlined,
                title: 'Backend URL',
                subtitle: 'http://localhost:8000',
              ),
              const Divider(),
              _settingsTile(
                context,
                icon: Icons.palette_outlined,
                title: 'Theme',
                subtitle: 'Light',
              ),
              const Divider(),
              _settingsTile(
                context,
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Enabled',
              ),
              const Divider(),
              _settingsTile(
                context,
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy',
                subtitle: 'Body data stored locally',
              ),
              const Divider(),
              _settingsTile(
                context,
                icon: Icons.info_outline,
                title: 'About FYT',
                subtitle: 'Version 1.0.0 — AI Personal Styling',
              ),
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    'Log Out',
                    style: AppTypography.body(context)
                        .copyWith(color: Colors.redAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _settingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.accentLavender.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
      title: Text(title, style: AppTypography.subheading(context)),
      subtitle: Text(subtitle, style: AppTypography.label(context)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.textSub),
      onTap: () {},
    );
  }
}
