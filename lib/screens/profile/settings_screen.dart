import 'package:flutter/material.dart';
import 'package:my_flutter_app/design/app_spacing.dart';
import 'package:my_flutter_app/design/app_typography.dart';
import 'package:my_flutter_app/design/app_colors.dart';
import 'package:my_flutter_app/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _activeBackendUrl = ApiService.baseUrl;

  Future<void> _changeBackendUrl() async {
    final controller =
        TextEditingController(text: ApiService.customBaseUrl ?? '');

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Backend URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'http://192.168.x.x:8000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, '__RESET__'),
            child: const Text('Use Default'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result == null) return;

    if (result == '__RESET__') {
      await ApiService.setCustomBaseUrl(null);
    } else {
      await ApiService.setCustomBaseUrl(result);
    }

    if (!mounted) return;
    setState(() => _activeBackendUrl = ApiService.baseUrl);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Backend URL set to: $_activeBackendUrl')),
    );
  }

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
                subtitle: _activeBackendUrl,
                onTap: _changeBackendUrl,
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
    VoidCallback? onTap,
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
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSub),
      onTap: onTap,
    );
  }
}
