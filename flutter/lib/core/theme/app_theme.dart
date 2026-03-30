import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 与 `web/app/globals.css`（`:root` light）中 `--radius` 阶梯对齐（逻辑像素取整）。
abstract final class AppRadius {
  static const double sm = 9.6;
  static const double md = 12.8;
  static const double lg = 16;
  static const double xl = 22.4;
  static const double x2l = 28.8;
  static const double x3l = 35.2;
  static const double x4l = 41.6;
}

/// 与官网 GlassCard / 顶栏阴影意图一致的 `BoxShadow` 近似（非像素级一致）。
abstract final class AppShadows {
  /// `shadow-[0_2px_12px_rgba(0,0,0,0.06)]`
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 2)),
  ];

  /// 顶栏/轻分割条（略轻于 card）
  static const List<BoxShadow> bar = [
    BoxShadow(color: Color(0x0C000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
}

/// 复用与 GlassCard / 顶栏一致的装饰，减少各屏魔法数字。
abstract final class AppDecorations {
  /// 首页、设置等顶部白条区域（非全圆角卡片）
  static const BoxDecoration topBar = BoxDecoration(
    color: AppColors.bgCard,
    boxShadow: AppShadows.bar,
  );
}

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

  /// `--kelem-sky-bright`
  static const skyBright = Color(0xFF4FC3F7);

  // Semantic
  static const green = Color(0xFF4CAF50);
  static const greenDark = Color(0xFF43A047);
  static const greenLight = Color(0xFFE8F5E9);
  static const greenSoft = Color(0xFF66BB6A);
  static const orange = Color(0xFFFF9800);
  static const orangeWarm = Color(0xFFFFA726);
  static const orangeLight = Color(0xFFFFF3E0);
  static const orangeFire = Color(0xFFFF6D00);
  static const red = Color(0xFFEF5350);
  static const redDeep = Color(0xFFE64A6A);
  static const purple = Color(0xFF9C77E8);
  static const purpleSoft = Color(0xFFAB47BC);

  // Pink (community accent)
  static const pink = Color(0xFFFF6B9D);
  static const pinkDark = Color(0xFFC62A6B);
  static const pinkLight = Color(0xFFF48FB1);
  static const pinkBg = Color(0x15FF6B9D);
  static const pinkBgMedium = Color(0x20FF6B9D);
  static const pinkBorder = Color(0x50FF6B9D);

  // Text（与 `--foreground` / `--muted-foreground` 等对齐）
  static const textPrimary = Color(0xFF1A2340);
  static const textSecondary = Color(0xFF546E7A);
  static const textHint = Color(0xFF90A4AE);
  static const textDark = Color(0xFF455A64);

  /// 与 `textPrimary`（`--foreground`）一致，避免与官网正文色分叉。
  static const textBody = Color(0xFF1A2340);

  // Neutral
  static const grey = Color(0xFFBDBDBD);
  static const greyLight = Color(0xFFE0E0E0);
  static const greyWarm = Color(0xFFB0BEC5);
  static const greyBlue = Color(0xFFCFD8DC);
  static const greySection = Color(0xFFF5F5F5);
  static const yellowLight = Color(0xFFFFF8E1);
  static const white = Color(0xFFFFFFFF);

  // Divider / Shadow / Glass
  static const divider = Color(0xFFE8EFF5);
  static const shadow = Color(0x0F000000);

  /// `border-white/60`（浅底上的玻璃边）
  static const glassBorder = Color(0x99FFFFFF);

  static TextStyle monoStyle(Color color) =>
      GoogleFonts.spaceMono(color: color, fontWeight: FontWeight.w700);

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
  /// 仅 light；与官网 light token 对齐（不对齐 `.dark`）。
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: false,
      scaffoldBackgroundColor: AppColors.bgMain,
      colorScheme: const ColorScheme.light(
        primary: AppColors.blue,
        onPrimary: Colors.white,
        secondary: AppColors.blueLight,
        onSecondary: AppColors.blueDark,
        surface: AppColors.bgCard,
        onSurface: AppColors.textPrimary,
        error: AppColors.red,
        onError: Colors.white,
        outline: AppColors.divider,
        secondaryContainer: AppColors.blueLight,
        onSecondaryContainer: AppColors.blueDark,
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
          bodyLarge: TextStyle(fontSize: 14, color: AppColors.textPrimary),
          bodyMedium: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          bodySmall: TextStyle(fontSize: 11, color: AppColors.textHint),
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
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.blue,
        unselectedItemColor: AppColors.textHint,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        elevation: 0,
        shadowColor: AppColors.shadow,
      ),
      // 实色底：避免 [AlertDialog] 继承透明后底层页面（按钮、列表）透出叠层。
      // [AppDialogScaffold] 仍对 [Dialog] 使用 `backgroundColor: Colors.transparent` 自绘卡片。
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.bgCard,
        elevation: 8,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.x2l),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.x2l)),
        ),
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
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
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

  /// 历史命名：与 [lightTheme] 相同，应用仅使用 light 外观。
  static ThemeData get darkTheme => lightTheme;

  static TextStyle get monoStyle =>
      GoogleFonts.spaceMono(color: AppColors.blue, fontWeight: FontWeight.w700);
}
