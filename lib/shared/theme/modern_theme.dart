import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern UI theme with glassmorphism, shadows, and smooth animations
class ModernTheme {
  // Enhanced shadows for cards
  static List<BoxShadow> get cardShadowLight => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.02),
      blurRadius: 40,
      offset: const Offset(0, 8),
      spreadRadius: -5,
    ),
  ];

  static List<BoxShadow> get cardShadowDark => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.2),
      blurRadius: 40,
      offset: const Offset(0, 8),
      spreadRadius: -5,
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: const Color(0xFF00A86B).withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -5,
    ),
  ];

  // Glassmorphism decoration
  static BoxDecoration glassmorphism({
    required bool isDark,
    double borderRadius = 24,
  }) {
    return BoxDecoration(
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.white.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.6),
        width: 1,
      ),
      boxShadow: isDark ? cardShadowDark : cardShadowLight,
    );
  }

  // Gradient backgrounds
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00A86B),
      Color(0xFF00D68A),
    ],
  );

  static LinearGradient get accentGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF97316),
      Color(0xFFFB923C),
    ],
  );

  static LinearGradient get darkSurfaceGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      const Color(0xFF1A1A1A),
      const Color(0xFF0D0D0D),
    ],
  );

  // Modern button style
  static ButtonStyle get elevatedButtonStyle => ElevatedButton.styleFrom(
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    backgroundColor: const Color(0xFF00A86B),
    foregroundColor: Colors.white,
  );

  // Floating action button decoration
  static BoxDecoration get fabDecoration => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(20),
    boxShadow: floatingShadow,
  );

  // Smooth scroll physics
  static const ScrollPhysics smoothScroll = BouncingScrollPhysics(
    decelerationRate: ScrollDecelerationRate.fast,
  );

  // Page transition duration
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Curve pageTransitionCurve = Curves.easeOutCubic;

  // Micro-animation durations
  static const Duration microAnimationFast = Duration(milliseconds: 150);
  static const Duration microAnimationNormal = Duration(milliseconds: 250);
  static const Duration microAnimationSlow = Duration(milliseconds: 400);

  // Status bar style for light theme
  static SystemUiOverlayStyle get lightStatusBar => const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  // Status bar style for dark theme
  static SystemUiOverlayStyle get darkStatusBar => const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  );

  // Text styles with better hierarchy
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
    fontSize: 36,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.4,
  );

  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  static TextStyle get labelLarge => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.4,
  );

  // Ripple colors
  static Color get lightRipple => Colors.black.withValues(alpha: 0.05);
  static Color get darkRipple => Colors.white.withValues(alpha: 0.1);

  // Border radius constants
  static const double radiusSmall = 12;
  static const double radiusMedium = 16;
  static const double radiusLarge = 24;
  static const double radiusXLarge = 32;
}

/// Extension for easy theme access
extension ModernThemeExtension on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get surfaceColor => Theme.of(this).colorScheme.surface;
  Color get onSurfaceColor => Theme.of(this).colorScheme.onSurface;
  Color get primaryColor => Theme.of(this).colorScheme.primary;
  Color get secondaryColor => Theme.of(this).colorScheme.secondary;
  List<BoxShadow> get cardShadow => isDark ? ModernTheme.cardShadowDark : ModernTheme.cardShadowLight;
}
