import 'package:flutter/material.dart';
import 'package:my_flutter_app/routing/app_router.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.microtask(() async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (Navigator.canPop(context) == false) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
<<<<<<< HEAD
            'FYT',
=======
            'FYT (fit+you)',
>>>>>>> feature/body-metric-module-clean
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
      ),
    );
  }
}