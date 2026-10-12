import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../screens/home_screen.dart';
import '../screens/editor_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'interactive_bounce.dart';

class FloatingBottomBar extends StatelessWidget {
  final int currentTabIndex;

  const FloatingBottomBar({
    super.key,
    required this.currentTabIndex,
  });

  void _onTabTapped(BuildContext context, int index) {
    if (index == currentTabIndex) return;

    Widget targetScreen;
    switch (index) {
      case 0:
        targetScreen = const HistoryScreen();
        break;
      case 1:
        targetScreen = const HomeScreen();
        break;
      case 2:
        targetScreen = EditorScreen(
          initialSlides: AppState.activeSlides,
          selectedTemplate: AppState.selectedTemplate,
        );
        break;
      case 3:
      default:
        targetScreen = const SettingsScreen();
        break;
    }

    Navigator.pushAndRemoveUntil(
      context,
      PageRouteBuilder(
        pageBuilder: (context, anim1, anim2) => targetScreen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (Icons.folder_open_rounded, "Vault"),
      (Icons.add_circle_outline_rounded, "Create"),
      (Icons.slideshow_rounded, "Editor"),
      (Icons.settings_outlined, "Settings"),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0, left: 20.0, right: 20.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.surfaceBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(tabs.length, (index) {
                  final isSelected = index == currentTabIndex;
                  final (icon, label) = tabs[index];
                  return _buildTabItem(context, index, icon, label, isSelected);
                }),
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildTabItem(
    BuildContext context,
    int index,
    IconData icon,
    String label,
    bool isSelected,
  ) {
    return InteractiveBounce(
      scaleFactor: 0.92,
      onTap: () => _onTabTapped(context, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
