import 'package:flutter/material.dart';
import '../../design/app_spacing.dart';
import '../../design/app_typography.dart';
import '../../design/app_colors.dart';
import '../../design/responsive.dart';
import '../../widgets/fyt_card.dart';
import '../../widgets/fyt_bottom_nav.dart';
import '../../routing/app_router.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  FytTab _tab = FytTab.home;
<<<<<<< HEAD
  final String userName = 'Niru';
=======
  final String userName = 'Ramesh Sir';
>>>>>>> feature/body-metric-module-clean

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.homeGridColumns(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppSpacing.screenPadding,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: Responsive.maxContentWidth(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
<<<<<<< HEAD
                  Text('Good Morning, $userName ☀️',
=======
                  Text('Good Afternoon, $userName ☀️',
>>>>>>> feature/body-metric-module-clean
                      style: AppTypography.heading(context)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'What would you like to do today?',
                    style: AppTypography.body(context),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: columns,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      children: [
                        _HomeCard(
                          icon: Icons.person_outline_rounded,
                          title: 'Body Blueprint',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.bodyIntro,
                          ),
                        ),
                        _HomeCard(
                          icon: Icons.calendar_month_rounded,
                          title: 'Occasion Mode',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.occasionSelection,
                          ),
                        ),
                        _HomeCard(
                          icon: Icons.chat_bubble_rounded,
                          title: 'Ask Your Stylist',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.aiChat,
                          ),
                        ),
                        _HomeCard(
                          icon: Icons.checkroom_rounded,
                          title: 'Smart Closet',
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.smartCloset,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: FytBottomNav(
        current: _tab,
        onChanged: (tab) {
          setState(() => _tab = tab);
          if (tab == FytTab.profile) {
            Navigator.pushNamed(context, AppRoutes.profile);
          }
          // Settings tab would route to settings screen if added.
        },
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FytCard(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: AppColors.textPrimary),
          const SizedBox(height: AppSpacing.sm),
          Text(title,
              style: AppTypography.subheading(context),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
