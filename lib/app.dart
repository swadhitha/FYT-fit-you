// lib/app.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'design/app_theme.dart';
import 'routing/app_router.dart';
import 'providers/user_provider.dart';
import 'providers/wardrobe_provider.dart';
import 'providers/recommendation_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/body_metric_provider.dart';

class FytApp extends StatelessWidget {
  const FytApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => WardrobeProvider()),
        ChangeNotifierProvider(create: (_) => RecommendationProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => BodyMetricProvider()),
      ],
      child: MaterialApp(
        title: 'FYT — Fit You',
        debugShowCheckedModeBanner: false,
        theme: buildFytTheme(),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: onGenerateRoute,
      ),
    );
  }
}