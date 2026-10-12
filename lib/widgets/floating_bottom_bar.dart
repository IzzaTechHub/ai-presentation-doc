import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/editor_screen.dart';
import '../screens/history_screen.dart';
import '../screens/settings_screen.dart';
import '../services/app_state.dart';

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

    // Navigate to target screen without transitions to make it feel like a tab switch
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12.0, left: 16.0, right: 16.0),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabItem(context, 0, Icons.folder_open_rounded),
              _buildTabItem(context, 1, Icons.add_circle_rounded),
              _buildTabItem(context, 2, Icons.slideshow_rounded),
              _buildTabItem(context, 3, Icons.settings_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(BuildContext context, int index, IconData icon) {
    final isSelected = index == currentTabIndex;

    return GestureDetector(
      onTap: () => _onTabTapped(context, index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : const Color(0xFF9E9E9E),
          size: 24,
        ),
      ),
    );
  }
}
