import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized application color palette and theme definition
/// Derived from the brand orange logo with true deep neutrals (no generic dark-blue).
class AppColors {
  // Brand Orange Accent Palette (Derived directly from app logo)
  static const Color primary = Color(0xFFFF5722); // Deep Brand Orange
  static const Color primaryLight = Color(0xFFFF7A47); // Lighter Warm Orange
  static const Color primaryDark = Color(0xFFE64A19); // Rich Dark Orange
  static const Color primaryContainer = Color(0xFFFFF0EB); // Warm Soft Peach Tint (5% Orange)
  static const Color primaryBorder = Color(0xFFFFCCBC); // Soft Peach-Orange Border
  static const Color secondary = Color(0xFFFF8A50); // Coral Accent

  // Crisp Editorial White & Pure Neutrals
  static const Color background = Color(0xFFF8F9FA); // Crisp Porcelain White Scaffold
  static const Color surface = Color(0xFFFFFFFF); // Pure Crisp White Card Surface
  static const Color surfaceElevated = Color(0xFFFFFFFF); // Modal, Dialog & Floating Capsule
  static const Color surfaceBorder = Color(0xFFE2E8F0); // Subtle Slate-200 Border
  static const Color surfaceBorderSubtle = Color(0xFFF1F5F9); // Light Slate-100 Border
  static const Color inputFill = Color(0xFFF8FAFC); // Slate-50 Clean Soft Input Fill

  // High-End Gradients
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orangeGlowGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassCardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // High-Contrast Typography (Crisp Slate Neutrals)
  static const Color textPrimary = Color(0xFF0F172A); // Slate-900 / Deep Slate Headline
  static const Color textSecondary = Color(0xFF475569); // Slate-600 / Subtitle
  static const Color textMuted = Color(0xFF94A3B8); // Slate-400 / Captions & Placeholders

  // Status & Utility
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        surface: AppColors.surface,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      scaffoldBackgroundColor: AppColors.background,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.outfit(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceElevated,
        elevation: 16,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        hintStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceBorder,
        thickness: 1,
        space: 1,
      ),
    );
  }

  // Backward compatibility alias
  static ThemeData get darkTheme => lightTheme;
}
