import 'package:flutter/material.dart';
import 'routing/app_router.dart';
import 'routing/app_routes.dart';
import 'design/app_theme.dart';

class FytApp extends StatelessWidget {
  const FytApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FYT',
      debugShowCheckedModeBanner: false,
      theme: buildFytTheme(),
      initialRoute: AppRoutes.login,
      onGenerateRoute: onGenerateRoute,
    );
  }
}
