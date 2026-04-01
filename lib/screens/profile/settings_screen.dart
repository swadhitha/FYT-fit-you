import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_flutter_app/design/app_spacing.dart';
import 'package:my_flutter_app/design/app_typography.dart';
import 'package:my_flutter_app/design/app_colors.dart';
import 'package:my_flutter_app/models/api_models.dart';
import 'package:my_flutter_app/providers/user_provider.dart';
import 'package:my_flutter_app/routing/app_router.dart';
import 'package:my_flutter_app/services/api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _prefNotifications = 'settings_notifications_enabled';
  static const _prefPrivacyMode = 'settings_privacy_mode';

  String _activeBackendUrl = ApiService.baseUrl;
  bool _notificationsEnabled = true;
  bool _privacyMode = true;
  bool _checkingConnection = false;
  String _connectionStatus = 'Not checked';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _activeBackendUrl = ApiService.baseUrl;
      _notificationsEnabled = prefs.getBool(_prefNotifications) ?? true;
      _privacyMode = prefs.getBool(_prefPrivacyMode) ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefNotifications, value);
    if (!mounted) return;
    setState(() => _notificationsEnabled = value);
  }

  Future<void> _togglePrivacyMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefPrivacyMode, value);
    if (!mounted) return;
    setState(() => _privacyMode = value);
  }

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
            hintText: 'https://<tunnel>.trycloudflare.com',
            helperText: 'Use only the root URL (no /healthz, /docs, or /api).',
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

  Future<void> _checkBackendConnection() async {
    setState(() {
      _checkingConnection = true;
      _connectionStatus = 'Checking...';
    });
    try {
      final response = await ApiService.checkBackendHealth();
      if (!mounted) return;
      setState(() {
        _connectionStatus =
            'Connected: ${response['service'] ?? 'Backend'} (${response['status'] ?? 'ok'})';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _connectionStatus =
            'Connection failed: ${e.toString().replaceAll('Exception: ', '')}';
      });
    } finally {
      if (mounted) {
        setState(() => _checkingConnection = false);
      }
    }
  }

  Future<void> _editAccount() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.name);
    String style = user.stylePreference;
    String climate = user.climateRegion;

    const styles = ['Minimal', 'Classic', 'Bold', 'Casual', 'Formal'];
    const climates = ['Tropical', 'Temperate', 'Dry', 'Cold', 'Warm'];

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit Account'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: style,
                      decoration: const InputDecoration(labelText: 'Style'),
                      items: styles
                          .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) =>
                          setStateDialog(() => style = v ?? style),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: climate,
                      decoration:
                          const InputDecoration(labelText: 'Climate Region'),
                      items: climates
                          .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setStateDialog(() => climate = v ?? climate),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;

    final ok = await userProvider.updateProfile(
      name: nameCtrl.text.trim().isEmpty ? user.name : nameCtrl.text.trim(),
      stylePreference: style,
      climateRegion: climate,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(ok
              ? 'Account updated'
              : (userProvider.error ?? 'Update failed'))),
    );
  }

  Future<void> _editPreferenceWeights() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;

    UserPreferences prefs;
    try {
      prefs = await ApiService.getPreferences(user.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
      return;
    }

    double comfort = prefs.comfortPriority;
    double confidence = prefs.confidencePriority;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Style Priorities'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Comfort (${comfort.toStringAsFixed(2)})'),
              Slider(
                value: comfort,
                onChanged: (v) => setStateDialog(() => comfort = v),
              ),
              Text('Confidence (${confidence.toStringAsFixed(2)})'),
              Slider(
                value: confidence,
                onChanged: (v) => setStateDialog(() => confidence = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    try {
      await ApiService.updatePreferences(
        userId: user.id,
        comfortPriority: comfort,
        confidencePriority: confidence,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preference weights updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  void _logout() {
    context.read<UserProvider>().logout();
    Navigator.pushNamedAndRemoveUntil(
        context, AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;

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
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Connection Status',
                    style: AppTypography.subheading(context)),
                subtitle: Text(_connectionStatus,
                    style: AppTypography.label(context)),
                trailing: _checkingConnection
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: _checkBackendConnection,
                        child: const Text('Test'),
                      ),
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _notificationsEnabled,
                onChanged: _toggleNotifications,
                title: Text('Notifications',
                    style: AppTypography.subheading(context)),
                subtitle: Text(
                  _notificationsEnabled ? 'Enabled' : 'Disabled',
                  style: AppTypography.label(context),
                ),
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _privacyMode,
                onChanged: _togglePrivacyMode,
                title: Text('Privacy Mode',
                    style: AppTypography.subheading(context)),
                subtitle: Text(
                  _privacyMode
                      ? 'Hide sensitive profile summaries'
                      : 'Show full profile summaries',
                  style: AppTypography.label(context),
                ),
              ),
              const Divider(),
              _settingsTile(
                context,
                icon: Icons.person_outline,
                title: 'Account',
                subtitle: user == null
                    ? 'Not signed in'
                    : '${user.name} • ${user.stylePreference} • ${user.climateRegion}',
                onTap: _editAccount,
              ),
              const Divider(),
              _settingsTile(
                context,
                icon: Icons.tune,
                title: 'Style Priorities',
                subtitle: 'Comfort and confidence weights',
                onTap: _editPreferenceWeights,
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
                  onPressed: _logout,
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
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right_rounded, color: AppColors.textSub),
      onTap: onTap,
    );
  }
}
