import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../widgets/fyt_text_field.dart';
import '../../widgets/fyt_button.dart';
import '../../routing/app_router.dart';
import '../../providers/user_provider.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({super.key});

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isLogin = true;
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final userProvider = context.read<UserProvider>();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    if (_isLogin) {
      await userProvider.login(email: email, password: password);
    } else {
      final name = _nameCtrl.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name.')),
        );
        return;
      }
      await userProvider.register(name: name, email: email, password: password);
    }

    if (userProvider.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userProvider.error!)),
      );
    } else if (userProvider.isLoggedIn && mounted) {
      if (_isLogin) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
      }
    }
  }

  void _useDemoMode() {
    context.read<UserProvider>().setDemoUser();
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<UserProvider>().loading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome to FYT',
                      style: AppTypography.heading(context)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Style with intelligence, every day.',
                    style: AppTypography.body(context),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Toggle login/signup
                  Row(
                    children: [
                      _tabButton('Login', _isLogin, () => setState(() => _isLogin = true)),
                      const SizedBox(width: AppSpacing.sm),
                      _tabButton('Sign Up', !_isLogin, () => setState(() => _isLogin = false)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (!_isLogin) ...[
                    FytTextField(label: 'Name', controller: _nameCtrl),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  FytTextField(
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailCtrl,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  FytTextField(
                    label: 'Password',
                    obscure: true,
                    controller: _passwordCtrl,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (loading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    FytButton(
                      label: _isLogin ? 'Login' : 'Create Account',
                      onPressed: _submit,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FytButton(
                      label: 'Continue as Demo User',
                      primary: false,
                      onPressed: _useDemoMode,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).primaryColor.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: AppTypography.button(context)),
      ),
    );
  }
}