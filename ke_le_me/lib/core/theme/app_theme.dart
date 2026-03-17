import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Backgrounds
  static const bgMain = Color(0xFFF5F8FF);
  static const bgCard = Color(0xFFFFFFFF);
  static const bgSection = Color(0xFFEFF4FB);

  // Blue (primary)
  static const blue = Color(0xFF29B6F6);
  static const blueDark = Color(0xFF0288D1);
  static const blueLight = Color(0xFFE3F2FD);
  static const blueBorder = Color(0xFFBBDEFB);

  // Semantic
  static const green = Color(0xFF4CAF50);
  static const greenLight = Color(0xFFE8F5E9);
  static const orange = Color(0xFFFF9800);
  static const orangeLight = Color(0xFFFFF3E0);
  static const red = Color(0xFFEF5350);
  static const purple = Color(0xFF9C77E8);

  // Text
  static const textPrimary = Color(0xFF1A2340);
  static const textSecondary = Color(0xFF546E7A);
  static const textHint = Color(0xFF90A4AE);

  // Divider / Shadow
  static const divider = Color(0xFFE8EFF5);
  static const shadow = Color(0x0F000000);

  static TextStyle monoStyle(Color color) => GoogleFonts.spaceMono(
        color: color,
        fontWeight: FontWeight.w700,
      );

  // Legacy aliases (keep screens compiling)
  static const bgDeep = bgMain;
  static const bgDark = bgSection;
  static const bgCard2 = bgSection;
  static const blueGlow = blueLight;
  static const textWhite = textPrimary;
  static const textLight = textSecondary;
  static const textMuted = textHint;
  static const textDim = divider;
  static const greenGlow = greenLight;
  static const orangeGlow = orangeLight;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgMain,
      colorScheme: const ColorScheme.light(
        primary: AppColors.blue,
        secondary: AppColors.orange,
        surface: AppColors.bgCard,
      ),
      textTheme: GoogleFonts.notoSansScTextTheme(
        const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
          bodyLarge: TextStyle(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          bodySmall: TextStyle(
            fontSize: 11,
            color: AppColors.textHint,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        shadowColor: AppColors.shadow,
        foregroundColor: AppColors.textPrimary,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        shadowColor: AppColors.shadow,
      ),
      dividerColor: AppColors.divider,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
          shadowColor: AppColors.blue.withValues(alpha: 0.35),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.blue,
        inactiveTrackColor: AppColors.blueLight,
        thumbColor: AppColors.blue,
        overlayColor: Color(0x2029B6F6),
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.blue;
          return const Color(0xFFCFD8DC);
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      );
  }

  static TextStyle get monoStyle => GoogleFonts.spaceMono(
        color: AppColors.blue,
        fontWeight: FontWeight.w700,
      );
}
