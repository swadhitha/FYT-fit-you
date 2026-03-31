import 'package:flutter/material.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_1_scan.dart';
import '../screens/onboarding/onboarding_2_occasion.dart';
import '../screens/onboarding/onboardin_3_chat.dart';
import '../screens/auth/login_signup_screen.dart';
import '../screens/auth/profile_setup_screen.dart';
import '../screens/home/home_dashboard_screen.dart';
import '../screens/body_blueprint/body_blueprint_intro_screen.dart';
import '../screens/body_blueprint/body_scan_screen.dart';
<<<<<<< HEAD
=======
import '../screens/body_blueprint/body_measurement_screen.dart';
>>>>>>> feature/body-metric-module-clean
import '../screens/body_blueprint/body_analysis_screen.dart';
import '../screens/body_blueprint/body_profile_result_screen.dart';
import '../screens/occasion/occasion_selection_screen.dart';
import '../screens/occasion/mood_confidence_screen.dart';
import '../screens/occasion/outfit_recommendation_screen.dart';
import '../screens/stylist_chat/ai_stylist_chat_screen.dart';
import '../screens/smart_closet/smart_closet_dashboard_screen.dart';
import '../screens/smart_closet/add_wardrobe_item_screen.dart';
import '../screens/profile/profile_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding1 = '/onboarding1';
  static const onboarding2 = '/onboarding2';
  static const onboarding3 = '/onboarding3';
  static const login = '/login';
  static const profileSetup = '/profile-setup';
  static const home = '/home';

  static const bodyIntro = '/body-intro';
  static const bodyScan = '/body-scan';
<<<<<<< HEAD
=======
  static const bodyMeasurement = '/body-measurement';
>>>>>>> feature/body-metric-module-clean
  static const bodyAnalysis = '/body-analysis';
  static const bodyResult = '/body-result';

  static const occasionSelection = '/occasion-selection';
  static const moodConfidence = '/mood-confidence';
  static const outfitRecommendation = '/outfit-recommendation';

  static const aiChat = '/ai-chat';

  static const smartCloset = '/smart-closet';
  static const addWardrobeItem = '/add-wardrobe-item';

  static const profile = '/profile';
}

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    case AppRoutes.splash:
      return _fade(const SplashScreen());
    case AppRoutes.onboarding1:
      return _slide(const OnboardingScanScreen());
    case AppRoutes.onboarding2:
      return _slide(const OnboardingOccasionScreen());
    case AppRoutes.onboarding3:
      return _slide(const OnboardingChatScreen());
    case AppRoutes.login:
      return _slide(const LoginSignupScreen());
    case AppRoutes.profileSetup:
      return _slide(const ProfileSetupScreen());
    case AppRoutes.home:
      return _fade(const HomeDashboardScreen());

    case AppRoutes.bodyIntro:
      return _slide(const BodyBlueprintIntroScreen());
    case AppRoutes.bodyScan:
      return _slide(const BodyScanScreen());
<<<<<<< HEAD
=======
    case AppRoutes.bodyMeasurement:
      return _slide(const BodyMeasurementScreen());
>>>>>>> feature/body-metric-module-clean
    case AppRoutes.bodyAnalysis:
      return _fade(const BodyAnalysisScreen());
    case AppRoutes.bodyResult:
      return _slide(const BodyProfileResultScreen());

    case AppRoutes.occasionSelection:
      return _slide(const OccasionSelectionScreen());
    case AppRoutes.moodConfidence:
      return _slide(const MoodConfidenceScreen());
    case AppRoutes.outfitRecommendation:
      return _slide(const OutfitRecommendationScreen());

    case AppRoutes.aiChat:
      return _slide(const AiStylistChatScreen());

    case AppRoutes.smartCloset:
      return _slide(const SmartClosetDashboardScreen());
    case AppRoutes.addWardrobeItem:
      return _slide(const AddWardrobeItemScreen());

    case AppRoutes.profile:
      return _slide(const ProfileScreen());

    default:
      return _fade(const SplashScreen());
  }
}

PageRoute _fade(Widget child) {
  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => child,
    transitionsBuilder: (_, animation, __, widget) {
      return FadeTransition(opacity: animation, child: widget);
    },
  );
}

PageRoute _slide(Widget child) {
  return PageRouteBuilder(
    pageBuilder: (_, __, ___) => child,
    transitionsBuilder: (_, animation, __, widget) {
      final offset =
          Tween(begin: const Offset(0.05, 0), end: Offset.zero)
              .animate(animation);
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(position: offset, child: widget),
      );
    },
  );
<<<<<<< HEAD
}
=======
}
>>>>>>> feature/body-metric-module-clean
