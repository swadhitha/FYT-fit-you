import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design/app_colors.dart';
import '../../design/app_typography.dart';
import '../../design/app_spacing.dart';
import '../../routing/app_routes.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  String _selectedStyle = 'Classic';
  String _selectedClimate = 'Temperate';
  List<String> _selectedColors = ['Black', 'White'];
  bool _isLoading = false;

  final List<String> _styles = [
    'Classic', 'Trendy', 'Minimalist', 'Bohemian', 'Streetwear', 'Ethnic', 'Glam'
  ];

  final List<String> _climates = [
    'Tropical', 'Temperate', 'Cold', 'Arid'
  ];

  final List<String> _colors = [
    'Black', 'White', 'Navy', 'Beige', 'Red', 'Pink', 'Green', 
    'Blue', 'Brown', 'Grey', 'Purple', 'Yellow'
  ];

  final Map<String, Color> _colorMap = {
    'Black': Colors.black,
    'White': Colors.white,
    'Navy': Colors.indigo[900]!,
    'Beige': const Color(0xFFF5E1A4),
    'Red': Colors.red,
    'Pink': Colors.pink,
    'Green': Colors.green,
    'Blue': Colors.blue,
    'Brown': Colors.brown,
    'Grey': Colors.grey,
    'Purple': Colors.purple,
    'Yellow': Colors.yellow,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Let\'s personalize FYT',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Style Preference',
                style: AppTypography.titleLarge(context),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _styles.length,
                  itemBuilder: (context, index) {
                    final style = _styles[index];
                    final isSelected = style == _selectedStyle;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedStyle = style),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          style,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              Text(
                'Climate',
                style: AppTypography.titleLarge(context),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _climates.map((climate) {
                  final isSelected = climate == _selectedClimate;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedClimate = climate),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        climate,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 24),
              Text(
                'Preferred Colors',
                style: AppTypography.titleLarge(context),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _colors.map((color) {
                  final isSelected = _selectedColors.contains(color);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedColors.remove(color);
                        } else {
                          _selectedColors.add(color);
                        }
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _colorMap[color] ?? Colors.grey,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 40),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _completeProfileSetup(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Let\'s Go',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeProfileSetup() async {
    setState(() => _isLoading = true);
    
    try {
      // Here you would save to Firestore via UserProfileProvider
      // For now, just navigate to home
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
