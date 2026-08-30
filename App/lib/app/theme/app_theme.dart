// lib/app/theme/app_theme.dart
// Complete design system for Local Ecosystem — premium utility aesthetic.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Tokens ─────────────────────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Core brand
  static const Color accent      = Color(0xFF5B8DEF);  // calm blue
  static const Color accentLight = Color(0xFF8AB4F8);
  static const Color success     = Color(0xFF34C759);
  static const Color warning     = Color(0xFFFF9500);
  static const Color danger      = Color(0xFFFF3B30);
  static const Color online      = Color(0xFF34C759);
  static const Color offline     = Color(0xFF636366);

  // Dark theme
  static const Color darkBg          = Color(0xFF0F0F12);
  static const Color darkSurface     = Color(0xFF1C1C1F);
  static const Color darkSurface2    = Color(0xFF2C2C2F);
  static const Color darkDivider     = Color(0xFF3A3A3C);
  static const Color darkTextPrimary = Color(0xFFEEEEF0);
  static const Color darkTextSecond  = Color(0xFF8E8E93);
  static const Color darkTextMuted   = Color(0xFF636366);

  // Light theme
  static const Color lightBg          = Color(0xFFF2F2F7);
  static const Color lightSurface     = Color(0xFFFFFFFF);
  static const Color lightSurface2    = Color(0xFFF2F2F7);
  static const Color lightDivider     = Color(0xFFD1D1D6);
  static const Color lightTextPrimary = Color(0xFF1C1C1E);
  static const Color lightTextSecond  = Color(0xFF6D6D72);
  static const Color lightTextMuted   = Color(0xFFAEAEB2);
}

// ─── Typography ───────────────────────────────────────────────────────────────

class AppTypography {
  AppTypography._();

  static TextTheme buildTextTheme(bool isDark) {
    final base = GoogleFonts.interTextTheme();
    final color = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondary = isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond;

    return base.copyWith(
      displayLarge:  base.displayLarge?.copyWith(
        fontSize: 32, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 26, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.3),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 22, fontWeight: FontWeight.w600, color: color, letterSpacing: -0.2),
      headlineMedium:base.headlineMedium?.copyWith(
        fontSize: 18, fontWeight: FontWeight.w600, color: color),
      titleLarge:    base.titleLarge?.copyWith(
        fontSize: 17, fontWeight: FontWeight.w600, color: color),
      titleMedium:   base.titleMedium?.copyWith(
        fontSize: 15, fontWeight: FontWeight.w500, color: color),
      titleSmall:    base.titleSmall?.copyWith(
        fontSize: 13, fontWeight: FontWeight.w500, color: secondary),
      bodyLarge:     base.bodyLarge?.copyWith(
        fontSize: 16, fontWeight: FontWeight.w400, color: color),
      bodyMedium:    base.bodyMedium?.copyWith(
        fontSize: 14, fontWeight: FontWeight.w400, color: color),
      bodySmall:     base.bodySmall?.copyWith(
        fontSize: 12, fontWeight: FontWeight.w400, color: secondary),
      labelLarge:    base.labelLarge?.copyWith(
        fontSize: 14, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.1),
      labelSmall:    base.labelSmall?.copyWith(
        fontSize: 11, fontWeight: FontWeight.w500, color: secondary, letterSpacing: 0.5),
    );
  }
}

// ─── Theme Builder ────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData dark() => _build(isDark: true);
  static ThemeData light() => _build(isDark: false);

  static ThemeData _build({required bool isDark}) {
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final surface2 = isDark ? AppColors.darkSurface2 : AppColors.lightSurface2;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecond = isDark ? AppColors.darkTextSecond : AppColors.lightTextSecond;

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: AppColors.accent,
        onPrimary: Colors.white,
        primaryContainer: AppColors.accent.withValues(alpha: 0.2),
        onPrimaryContainer: AppColors.accentLight,
        secondary: AppColors.accentLight,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.accentLight.withValues(alpha: 0.15),
        onSecondaryContainer: AppColors.accent,
        tertiary: AppColors.success,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.success.withValues(alpha: 0.15),
        onTertiaryContainer: AppColors.success,
        error: AppColors.danger,
        onError: Colors.white,
        errorContainer: AppColors.danger.withValues(alpha: 0.15),
        onErrorContainer: AppColors.danger,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: surface2,
        onSurfaceVariant: textSecond,
        outline: divider,
        outlineVariant: divider.withValues(alpha: 0.5),
        shadow: Colors.black,
        scrim: Colors.black54,
        inverseSurface: isDark ? AppColors.lightSurface : AppColors.darkSurface,
        onInverseSurface: isDark ? AppColors.lightTextPrimary : AppColors.darkTextPrimary,
        inversePrimary: AppColors.accent,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: AppTypography.buildTextTheme(isDark),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        shadowColor: divider,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        iconTheme: IconThemeData(color: textPrimary, size: 22),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.accent, size: 22);
          }
          return IconThemeData(color: textSecond, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent);
          }
          return GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w500, color: textSecond);
        }),
        height: 60,
        elevation: 0,
        shadowColor: divider,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: AppColors.accent.withValues(alpha: 0.15),
        selectedIconTheme: const IconThemeData(color: AppColors.accent, size: 22),
        unselectedIconTheme: IconThemeData(color: textSecond, size: 22),
        selectedLabelTextStyle: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accent),
        unselectedLabelTextStyle: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w500, color: textSecond),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: divider, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(color: divider, thickness: 0.5, space: 0),
      listTileTheme: ListTileThemeData(
        tileColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: divider, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: divider, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: textSecond),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: textSecond),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? AppColors.accent : surface2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface2,
        selectedColor: AppColors.accent.withValues(alpha: 0.15),
        labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        side: BorderSide(color: divider, width: 0.5),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        showDragHandle: true,
        dragHandleColor: divider,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14, color: textSecond),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkSurface2 : AppColors.darkSurface,
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ─── Motion ───────────────────────────────────────────────────────────────────

class AppMotion {
  AppMotion._();
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration page = Duration(milliseconds: 300);
  static const Curve curve = Curves.easeInOut;
  static const Curve spring = Curves.elasticOut;
}

// ─── Spacing ──────────────────────────────────────────────────────────────────

class AppSpacing {
  AppSpacing._();
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double base= 16;
  static const double lg  = 20;
  static const double xl  = 24;
  static const double xxl = 32;
  static const double xxxl= 48;
}
