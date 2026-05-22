import 'package:flutter/material.dart';

class AppColors {

  // ════════════════════════════════════════════════════════
  //  LIGHT MODE — Warm Pink/Rose
  // ════════════════════════════════════════════════════════

  static const Color lightBg           = Color(0xFFFBF3EE);
  static const Color lightCard         = Color(0xFFFFF0F5);
  static const Color lightSurface      = Color(0xFFFFE4EE);

  static const Color lightPrimary      = Color(0xFFC2687A);
  static const Color lightPrimaryDark  = Color(0xFFA8506A);
  static const Color lightPrimaryLight = Color(0xFFE8A0B0);

  static const Color lightTextMain     = Color(0xFF2D1A22);
  static const Color lightTextSub      = Color(0xFF7A4A58);
  static const Color lightTextHint     = Color(0xFFB08090);

  static const Color lightBorder       = Color(0xFFE8C8C8);

  // ════════════════════════════════════════════════════════
  //  DARK MODE — Deep Rose/Mauve
  // ════════════════════════════════════════════════════════

  static const Color darkBg            = Color(0xFF160E12);
  static const Color darkCard          = Color(0xFF221520);
  static const Color darkSurface       = Color(0xFF2E1A26);

  static const Color darkPrimary       = Color(0xFFF0A0B8);
  static const Color darkPrimaryDark   = Color(0xFFD4748A);
  static const Color darkPrimaryLight  = Color(0xFFFFCCDD);

  static const Color darkTextMain      = Color(0xFFF5E0E8);
  static const Color darkTextSub       = Color(0xFFCCA0B0);
  static const Color darkTextHint      = Color(0xFF8A6070);

  static const Color darkBorder        = Color(0xFF4A2838);

  // ════════════════════════════════════════════════════════
  //  SHARED / STATUS COLORS
  // ════════════════════════════════════════════════════════

  static const Color success           = Color(0xFF6DBF8A);
  static const Color warning           = Color(0xFFE8B84B);
  static const Color error             = Color(0xFFE07070);
  static const Color info              = Color(0xFF7ABCDC);

  static const Color micActive         = Color(0xFF6DBF8A);
  static const Color micInactive       = Color(0xFFE07070);
  static const Color timerWarning      = Color(0xFFE8B84B);
  static const Color timerDanger       = Color(0xFFE07070);

  // ════════════════════════════════════════════════════════
  //  LEGACY aliases — doosri screens break na hon
  // ════════════════════════════════════════════════════════

  static const Color primary           = darkPrimary;
  static const Color primaryDark       = darkPrimaryDark;
  static const Color primaryLight      = darkPrimaryLight;
  static const Color accentPink        = Color(0xFFFFB6C8);
  static const Color accentLilac       = Color(0xFFDDA0DD);

  static const Color textWhite         = Color(0xFFF5E0E8);
  static const Color textGrey          = Color(0xFFCCA0B0);
  static const Color textDark          = Color(0xFF2D1A22);
  static const Color textSubtle        = Color(0xFF8A6070);

  // ════════════════════════════════════════════════════════
  //  THEME-AWARE HELPERS
  // ════════════════════════════════════════════════════════

  static Color bg(BuildContext context) =>
      _isDark(context) ? darkBg : lightBg;

  static Color card(BuildContext context) =>
      _isDark(context) ? darkCard : lightCard;

  static Color surface(BuildContext context) =>
      _isDark(context) ? darkSurface : lightSurface;

  static Color prim(BuildContext context) =>
      _isDark(context) ? darkPrimary : lightPrimary;

  static Color text(BuildContext context) =>
      _isDark(context) ? darkTextMain : lightTextMain;

  static Color subText(BuildContext context) =>
      _isDark(context) ? darkTextSub : lightTextSub;

  static Color hintText(BuildContext context) =>
      _isDark(context) ? darkTextHint : lightTextHint;

  static Color border(BuildContext context) =>
      _isDark(context) ? darkBorder : lightBorder;

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // ════════════════════════════════════════════════════════
  //  GRADIENTS
  // ════════════════════════════════════════════════════════

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE8A0B0), Color(0xFFF0C0A0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient lightGradient = LinearGradient(
    colors: [Color(0xFFFBF3EE), Color(0xFFFFF0F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient lightBgGradient = LinearGradient(
    colors: [Color(0xFFFBF3EE), Color(0xFFFFF0F5)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF160E12), Color(0xFF221520)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient darkBgGradient = LinearGradient(
    colors: [Color(0xFF160E12), Color(0xFF221520)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const List<Color> chartColors = [
    Color(0xFFC2687A),
    Color(0xFFE8A0B0),
    Color(0xFFDDA0DD),
    Color(0xFFFFB6C8),
    Color(0xFFF0C0A0),
  ];
}