import 'package:flutter/material.dart';

/// Contexta App Theme
/// Design Philosophy: Calm, paper-like warmth, intellectual tone
/// Colors: Beige, Charcoal, Ink Blue with warm paper-like dark mode
class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────────────────────────────
  // LIGHT MODE COLORS
  // ─────────────────────────────────────────────────────────────────
  static const Color beige = Color(0xFFF5F1E8); // Warm beige background
  static const Color beigeDarker = Color(0xFFE8E2D5);
  static const Color paper = Color(0xFFFFFFFF); // Pure white paper
  static const Color charcoal = Color(0xFF2D2D2D); // Primary text
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textMuted = Color(0xFF9B9B9B);
  static const Color inkBlue = Color(0xFF1A4B7C); // Accent
  static const Color inkBluePressed = Color(0xFF143A5F);
  static const Color inkBlueHover = Color(0xFF1E5A8F);
  static const Color border = Color(0xFFD4CFC0);
  static const Color overlay = Color.fromRGBO(0, 0, 0, 0.05);
  static const Color error = Color(0xFFB54B4B);
  static const Color success = Color(0xFF4B8B5E);

  // ─────────────────────────────────────────────────────────────────
  // DARK MODE COLORS (Paper-warm night reading)
  // Philosophy: Old paper, ink absorbed into parchment, quiet concentration
  // ─────────────────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF1E1B18); // Deep brown-black
  static const Color darkBackgroundElevated = Color(
    0xFF252220,
  ); // Slightly lifted
  static const Color darkPaper = Color(0xFF2A2520); // Dark parchment
  static const Color darkPaperElevated = Color(0xFF332E28); // Cards, sheets
  static const Color darkPaperHighest = Color(0xFF3B3530); // Highest elevation
  static const Color darkTextPrimary = Color(0xFFEDE6D8); // Warm off-white
  static const Color darkTextSecondary = Color(0xFFB5AD9E); // Muted taupe
  static const Color darkTextMuted = Color(0xFF8A847A); // Hints, timestamps
  static const Color darkInkBlue = Color(0xFF6C7A9A); // Desaturated for night
  static const Color darkInkBluePressed = Color(0xFF5A6685); // Pressed state
  static const Color darkInkBlueHover = Color(0xFF7D8AA8); // Hover state
  static const Color darkBorder = Color(0xFF3D3832); // Soft dividers
  static const Color darkBorderSubtle = Color(0xFF332E28); // Even softer
  static const Color darkOverlay = Color.fromRGBO(
    237,
    230,
    216,
    0.05,
  ); // Warm overlay
  static const Color darkOverlayPressed = Color.fromRGBO(237, 230, 216, 0.08);
  static const Color darkError = Color(0xFFCF6B6B); // Muted error
  static const Color darkSuccess = Color(0xFF6BAB7E); // Muted success

  // ─────────────────────────────────────────────────────────────────
  // ANIMATION DURATIONS
  // ─────────────────────────────────────────────────────────────────
  static const Duration buttonPressDuration = Duration(milliseconds: 120);
  static const Duration cardPressDuration = Duration(milliseconds: 200);
  static const Duration fadeInDuration = Duration(milliseconds: 700);
  static const Duration sheetAnimDuration = Duration(milliseconds: 200);
  static const Duration dialogAnimDuration = Duration(milliseconds: 200);
  static const Duration listItemDuration = Duration(milliseconds: 150);
  static const Duration themeTransitionDuration = Duration(milliseconds: 300);

  // ─────────────────────────────────────────────────────────────────
  // SCALE VALUES
  // ─────────────────────────────────────────────────────────────────
  static const double buttonPressedScale = 0.97;
  static const double cardPressedScale = 0.98;
  static const double cardHoverScale = 1.01;
  static const double fabPressedScale = 0.95;

  // ─────────────────────────────────────────────────────────────────
  // BORDER RADIUS
  // ─────────────────────────────────────────────────────────────────
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXLarge = 24.0;
  static const double radiusSheet = 28.0;

  // ─────────────────────────────────────────────────────────────────
  // LIGHT THEME
  // ─────────────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: beige,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.light(
      primary: inkBlue,
      onPrimary: beige,
      primaryContainer: inkBlueHover,
      secondary: textSecondary,
      onSecondary: paper,
      surface: paper,
      onSurface: charcoal,
      error: error,
      onError: paper,
      outline: border,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: beige,
      foregroundColor: charcoal,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: paper,
      elevation: 4,
      shadowColor: charcoal.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 1),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: inkBlue,
      foregroundColor: beige,
      elevation: 6,
      highlightElevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: inkBlue,
        foregroundColor: beige,
        disabledBackgroundColor: inkBlue.withValues(alpha: 0.4),
        disabledForegroundColor: beige.withValues(alpha: 0.6),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: inkBlue,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: inkBlue,
        side: const BorderSide(color: inkBlue),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: paper,
      hintStyle: TextStyle(fontStyle: FontStyle.italic, color: textMuted),
      errorStyle: const TextStyle(color: error),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: inkBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: error, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: border.withValues(alpha: 0.5)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: paper,
      modalBackgroundColor: paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusSheet)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXLarge),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: charcoal,
      contentTextStyle: const TextStyle(color: beige),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Serif',
        color: charcoal,
        fontSize: 56,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Serif',
        color: charcoal,
        fontSize: 48,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Serif',
        color: charcoal,
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Serif',
        color: charcoal,
        fontSize: 28,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Serif',
        color: charcoal,
        fontSize: 24,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Serif',
        color: charcoal,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        color: charcoal,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        color: charcoal,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(fontFamily: 'Inter', color: charcoal, fontSize: 16),
      bodyMedium: TextStyle(fontFamily: 'Inter', color: charcoal, fontSize: 14),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        color: textSecondary,
        fontSize: 12,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        color: charcoal,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        color: textSecondary,
        fontSize: 12,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        color: textMuted,
        fontSize: 11,
        letterSpacing: 1.2,
      ),
    ),
    iconTheme: const IconThemeData(color: charcoal, size: 24),
    hintColor: textMuted,
  );

  // ─────────────────────────────────────────────────────────────────
  // DARK THEME
  // ─────────────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    fontFamily: 'Inter',
    colorScheme: const ColorScheme.dark(
      primary: darkInkBlue,
      onPrimary: darkTextPrimary,
      primaryContainer: darkInkBlueHover,
      secondary: darkTextSecondary,
      onSecondary: darkPaper,
      surface: darkPaper,
      onSurface: darkTextPrimary,
      error: darkError,
      onError: darkPaper,
      outline: darkBorder,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      color: darkPaper,
      elevation: 0, // Remove shadows, rely on color layering
      shadowColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: darkBorder.withValues(alpha: 0.7), // Softer dividers
      thickness: 1,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: darkInkBlue,
      foregroundColor: darkTextPrimary,
      elevation: 2, // Reduced from 6
      highlightElevation: 4, // Reduced from 8
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkInkBlue,
        foregroundColor: darkTextPrimary,
        disabledBackgroundColor: darkInkBlue.withValues(alpha: 0.4),
        disabledForegroundColor: darkTextPrimary.withValues(alpha: 0.6),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: darkInkBlue,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: darkInkBlue,
        side: const BorderSide(color: darkInkBlue),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusXLarge),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkPaperElevated,
      hintStyle: TextStyle(fontStyle: FontStyle.italic, color: darkTextMuted),
      errorStyle: const TextStyle(color: darkError),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: darkInkBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: darkError),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: darkError, width: 2),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: BorderSide(color: darkBorder.withValues(alpha: 0.5)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: darkPaper,
      modalBackgroundColor: darkPaper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusSheet)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkPaper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusXLarge),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkTextPrimary,
      contentTextStyle: const TextStyle(color: darkBackground),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Serif',
        color: darkTextPrimary,
        fontSize: 56,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Serif',
        color: darkTextPrimary,
        fontSize: 48,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Serif',
        color: darkTextPrimary,
        fontSize: 32,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Serif',
        color: darkTextPrimary,
        fontSize: 28,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Serif',
        color: darkTextPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Serif',
        color: darkTextPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        color: darkTextPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        color: darkTextPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        color: darkTextPrimary,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        color: darkTextPrimary,
        fontSize: 14,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        color: darkTextSecondary,
        fontSize: 12,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        color: darkTextPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        color: darkTextSecondary,
        fontSize: 12,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        color: darkTextMuted,
        fontSize: 11,
        letterSpacing: 1.2,
      ),
    ),
    iconTheme: const IconThemeData(color: darkTextPrimary, size: 24),
    hintColor: darkTextMuted,
  );

  // ─────────────────────────────────────────────────────────────────
  // HELPER EXTENSIONS
  // ─────────────────────────────────────────────────────────────────

  /// Get appropriate ink blue based on brightness
  static Color getInkBlue(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkInkBlue
        : inkBlue;
  }

  /// Get appropriate paper color based on brightness
  static Color getPaper(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? darkPaper : paper;
  }

  /// Get elevated paper color (for cards, sheets)
  static Color getPaperElevated(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkPaperElevated
        : paper;
  }

  /// Get highest elevation surface color
  static Color getSurfaceHighest(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkPaperHighest
        : beigeDarker;
  }

  /// Get appropriate border color based on brightness
  static Color getBorder(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorder
        : border;
  }

  /// Get subtle border color (even softer separation)
  static Color getBorderSubtle(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBorderSubtle
        : border.withValues(alpha: 0.5);
  }

  /// Get appropriate primary text color based on brightness
  static Color getTextPrimary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : charcoal;
  }

  /// Get appropriate muted text color based on brightness
  static Color getTextMuted(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextMuted
        : textMuted;
  }

  /// Get appropriate secondary text color based on brightness
  static Color getTextSecondary(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : textSecondary;
  }

  /// Get overlay color for press/hover states
  static Color getOverlay(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkOverlay
        : overlay;
  }

  /// Get pressed overlay color (slightly stronger)
  static Color getOverlayPressed(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkOverlayPressed
        : const Color.fromRGBO(0, 0, 0, 0.08);
  }

  /// Check if dark mode is active
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  /// Get card shadow (reduced in dark mode)
  static List<BoxShadow> getCardShadow(BuildContext context) {
    if (isDark(context)) {
      // Very subtle shadow in dark mode
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return [
      BoxShadow(
        color: charcoal.withValues(alpha: 0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// Get subtle elevation shadow (almost invisible in dark mode)
  static List<BoxShadow> getSubtleShadow(BuildContext context) {
    if (isDark(context)) {
      return []; // No shadow in dark mode, use color layering
    }
    return [
      BoxShadow(
        color: charcoal.withValues(alpha: 0.06),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Build a gradient divider (subtle fade in/out)
  static Widget buildGradientDivider(BuildContext context) {
    final dividerColor = getBorder(context);
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            dividerColor.withValues(alpha: isDark(context) ? 0.5 : 0.7),
            dividerColor.withValues(alpha: isDark(context) ? 0.5 : 0.7),
            Colors.transparent,
          ],
          stops: const [0.0, 0.15, 0.85, 1.0],
        ),
      ),
    );
  }
}
