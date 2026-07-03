import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────────────────
///  GYM TRACKER DESIGN SYSTEM — "Midnight Steel / Volt Azure"
///
///  A single source of truth for color, type, shape and motion.
///  • Display + numerals: Space Grotesk (geometric, athletic)
///  • Body + labels:      Manrope (clean, highly legible)
///  • Dark-first palette tuned for gym lighting; matching light theme.
/// ─────────────────────────────────────────────────────────────────────────

abstract final class AppColors {
  // Core dark surfaces (blue-black "midnight steel")
  static const ink = Color(0xFF0A0E17);
  static const surface1 = Color(0xFF101625);
  static const surface2 = Color(0xFF161E31);
  static const surface3 = Color(0xFF1E2840);
  static const line = Color(0xFF283354);
  static const lineSoft = Color(0xFF1B2338);

  // Accents
  static const volt = Color(0xFF4D8DFF); // primary azure
  static const voltDeep = Color(0xFF2E5BFF);
  static const voltDark = Color(0xFF1737A8);
  static const mint = Color(0xFF34D8A4); // success / completed sets
  static const amber = Color(0xFFFFB454); // warm-ups / streak fire
  static const violet = Color(0xFFA78BFA); // drop sets
  static const rose = Color(0xFFFF5C7A); // errors / destructive

  // Dark text
  static const textHi = Color(0xFFF2F5FB);
  static const textMid = Color(0xFFA6B0C3);
  static const textLow = Color(0xFF6B7690);

  // Light theme counterparts
  static const paper = Color(0xFFF4F6FB);
  static const paperCard = Color(0xFFFFFFFF);
  static const paperLine = Color(0xFFDDE3F0);
  static const inkOnPaper = Color(0xFF10182B);
  static const voltOnPaper = Color(0xFF2563EB);
}

abstract final class AppFonts {
  static const display = 'SpaceGrotesk';
  static const body = 'Manrope';
}

abstract final class AppRadius {
  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 18.0;
  static const xl = 24.0;
  static const sheet = 28.0;
}

abstract final class AppGradients {
  /// Signature "volt" call-to-action gradient.
  static const volt = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.volt, AppColors.voltDeep],
  );

  /// Deep hero backdrop (splash / auth / profile header).
  static const midnight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14224A), Color(0xFF0A0E17)],
  );

  /// Success sweep for streaks / PR celebration accents.
  static const mint = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D8A4), Color(0xFF19A97C)],
  );
}

/// Semantic tokens available via `context.tokens`.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.success,
    required this.onSuccess,
    required this.warning,
    required this.dropset,
    required this.cardBorder,
    required this.cardShadow,
    required this.glass,
  });

  final Color success;
  final Color onSuccess;
  final Color warning;
  final Color dropset;
  final Color cardBorder;
  final Color cardShadow;

  /// Translucent surface used for glassy overlays.
  final Color glass;

  static const dark = AppTokens(
    success: AppColors.mint,
    onSuccess: Color(0xFF04120C),
    warning: AppColors.amber,
    dropset: AppColors.violet,
    cardBorder: Color(0x3D3D4E78),
    cardShadow: Color(0x66000000),
    glass: Color(0xB3101625),
  );

  static const light = AppTokens(
    success: Color(0xFF0E9F6E),
    onSuccess: Colors.white,
    warning: Color(0xFFB45309),
    dropset: Color(0xFF7C3AED),
    cardBorder: Color(0xFFE2E8F5),
    cardShadow: Color(0x14203050),
    glass: Color(0xE6FFFFFF),
  );

  @override
  AppTokens copyWith({
    Color? success,
    Color? onSuccess,
    Color? warning,
    Color? dropset,
    Color? cardBorder,
    Color? cardShadow,
    Color? glass,
  }) {
    return AppTokens(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      warning: warning ?? this.warning,
      dropset: dropset ?? this.dropset,
      cardBorder: cardBorder ?? this.cardBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      glass: glass ?? this.glass,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      dropset: Color.lerp(dropset, other.dropset, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      glass: Color.lerp(glass, other.glass, t)!,
    );
  }
}

extension AppTokensX on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.dark;
}

/// Subtle fade + rise transition used app-wide for pushed routes.
class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.035),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

// ───────────────────────────── TEXT THEME ──────────────────────────────

TextTheme _textTheme(Color hi, Color mid, Color low) {
  TextStyle d(double size, FontWeight w, {double? ls, Color? c}) => TextStyle(
        fontFamily: AppFonts.display,
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: c ?? hi,
        height: 1.15,
      );
  TextStyle b(double size, FontWeight w, {double? ls, Color? c}) => TextStyle(
        fontFamily: AppFonts.body,
        fontSize: size,
        fontWeight: w,
        letterSpacing: ls,
        color: c ?? hi,
        height: 1.4,
      );

  return TextTheme(
    displayLarge: d(52, FontWeight.w700, ls: -1.0),
    displayMedium: d(42, FontWeight.w700, ls: -0.8),
    displaySmall: d(34, FontWeight.w700, ls: -0.5),
    headlineLarge: d(28, FontWeight.w700, ls: -0.4),
    headlineMedium: d(24, FontWeight.w700, ls: -0.3),
    headlineSmall: d(20, FontWeight.w700, ls: -0.2),
    titleLarge: d(18, FontWeight.w700, ls: -0.1),
    titleMedium: b(16, FontWeight.w700),
    titleSmall: b(14, FontWeight.w700),
    bodyLarge: b(16, FontWeight.w500),
    bodyMedium: b(14, FontWeight.w500, c: mid),
    bodySmall: b(12, FontWeight.w500, c: low),
    labelLarge: b(14, FontWeight.w700, ls: 0.2),
    labelMedium: b(12, FontWeight.w600, ls: 0.3, c: mid),
    labelSmall: b(11, FontWeight.w600, ls: 0.6, c: low),
  );
}

// ───────────────────────────── DARK THEME ──────────────────────────────

ThemeData buildDarkTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.volt,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF1B316B),
    onPrimaryContainer: Color(0xFFBFD6FF),
    secondary: AppColors.mint,
    onSecondary: Color(0xFF04120C),
    secondaryContainer: Color(0xFF0D3D2E),
    onSecondaryContainer: Color(0xFF8CEFCB),
    tertiary: AppColors.amber,
    onTertiary: Color(0xFF241300),
    tertiaryContainer: Color(0xFF4A2E08),
    onTertiaryContainer: Color(0xFFFFD9A3),
    error: AppColors.rose,
    onError: Colors.white,
    errorContainer: Color(0xFF551423),
    onErrorContainer: Color(0xFFFFB3C1),
    surface: AppColors.ink,
    onSurface: AppColors.textHi,
    surfaceContainerLowest: Color(0xFF070B12),
    surfaceContainerLow: AppColors.surface1,
    surfaceContainer: AppColors.surface2,
    surfaceContainerHigh: AppColors.surface3,
    surfaceContainerHighest: AppColors.surface3,
    onSurfaceVariant: AppColors.textMid,
    outline: AppColors.line,
    outlineVariant: AppColors.lineSoft,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: AppColors.textHi,
    onInverseSurface: AppColors.ink,
    inversePrimary: AppColors.voltDark,
    surfaceTint: Colors.transparent,
  );

  final text = _textTheme(AppColors.textHi, AppColors.textMid, AppColors.textLow);

  return ThemeData(
    useMaterial3: true,
    fontFamily: AppFonts.body,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.ink,
    canvasColor: AppColors.ink,
    cardColor: AppColors.surface2,
    textTheme: text,
    extensions: const [AppTokens.dark],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
        TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
      },
    ),
    splashColor: AppColors.volt.withValues(alpha: 0.08),
    highlightColor: AppColors.volt.withValues(alpha: 0.05),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.ink,
      foregroundColor: AppColors.textHi,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: text.titleLarge,
      iconTheme: const IconThemeData(color: AppColors.textHi, size: 22),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface1,
      indicatorColor: AppColors.volt.withValues(alpha: 0.16),
      height: 68,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? AppColors.volt
              : AppColors.textLow,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? AppColors.volt
              : AppColors.textLow,
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface1,
      selectedItemColor: AppColors.volt,
      unselectedItemColor: AppColors.textLow,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface2,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: Color(0x3D3D4E78)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.lineSoft,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface1,
      hintStyle: text.bodyMedium?.copyWith(color: AppColors.textLow),
      labelStyle: text.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.lineSoft),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.lineSoft),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.volt, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.rose),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.rose, width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.volt,
        foregroundColor: Colors.white,
        textStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.volt,
        foregroundColor: Colors.white,
        elevation: 0,
        textStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textHi,
        textStyle: text.labelLarge,
        side: const BorderSide(color: AppColors.line),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.volt,
        textStyle: text.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface3,
      side: const BorderSide(color: AppColors.lineSoft),
      labelStyle: text.labelMedium?.copyWith(color: AppColors.textHi),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface1,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: text.headlineSmall,
      contentTextStyle: text.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface1,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: AppColors.surface1,
      showDragHandle: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surface3,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      textStyle: text.bodyLarge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.lineSoft),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.surface3,
      contentTextStyle: text.bodyLarge,
      actionTextColor: AppColors.volt,
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.lineSoft),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: AppColors.textMid,
      textColor: AppColors.textHi,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: const BorderSide(color: AppColors.line, width: 1.6),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.volt
            : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(Colors.white),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : AppColors.textLow,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.volt
            : AppColors.surface3,
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : AppColors.line,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.volt,
      linearTrackColor: AppColors.surface3,
      circularTrackColor: AppColors.surface3,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.volt,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      iconColor: AppColors.textMid,
      collapsedIconColor: AppColors.textLow,
      shape: Border(),
      collapsedShape: Border(),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.surface3,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.lineSoft),
      ),
      textStyle: text.labelMedium?.copyWith(color: AppColors.textHi),
    ),
  );
}

// ───────────────────────────── LIGHT THEME ─────────────────────────────

ThemeData buildLightTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.voltOnPaper,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDBE7FF),
    onPrimaryContainer: Color(0xFF11316B),
    secondary: Color(0xFF0E9F6E),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFCDF3E4),
    onSecondaryContainer: Color(0xFF06402C),
    tertiary: Color(0xFFB45309),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFFFE7C2),
    onTertiaryContainer: Color(0xFF4A2E08),
    error: Color(0xFFDC2649),
    onError: Colors.white,
    errorContainer: Color(0xFFFFDBE1),
    onErrorContainer: Color(0xFF551423),
    surface: AppColors.paper,
    onSurface: AppColors.inkOnPaper,
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: Colors.white,
    surfaceContainer: AppColors.paperCard,
    surfaceContainerHigh: Color(0xFFEBEFF8),
    surfaceContainerHighest: Color(0xFFE4E9F5),
    onSurfaceVariant: Color(0xFF57617A),
    outline: Color(0xFFC4CDE0),
    outlineVariant: AppColors.paperLine,
    shadow: Color(0xFF203050),
    scrim: Colors.black,
    inverseSurface: AppColors.inkOnPaper,
    onInverseSurface: Colors.white,
    inversePrimary: AppColors.volt,
    surfaceTint: Colors.transparent,
  );

  final text = _textTheme(
    AppColors.inkOnPaper,
    const Color(0xFF57617A),
    const Color(0xFF8A93A8),
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: AppFonts.body,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.paper,
    canvasColor: AppColors.paper,
    cardColor: AppColors.paperCard,
    textTheme: text,
    extensions: const [AppTokens.light],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
        TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
      },
    ),
    splashColor: AppColors.voltOnPaper.withValues(alpha: 0.08),
    highlightColor: AppColors.voltOnPaper.withValues(alpha: 0.05),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.paper,
      foregroundColor: AppColors.inkOnPaper,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: text.titleLarge,
      iconTheme: const IconThemeData(color: AppColors.inkOnPaper, size: 22),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.voltOnPaper.withValues(alpha: 0.12),
      height: 68,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? AppColors.voltOnPaper
              : const Color(0xFF8A93A8),
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 11,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? AppColors.voltOnPaper
              : const Color(0xFF8A93A8),
        ),
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.voltOnPaper,
      unselectedItemColor: Color(0xFF8A93A8),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: AppColors.paperCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: const BorderSide(color: AppColors.paperLine),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.paperLine,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: text.bodyMedium?.copyWith(color: const Color(0xFF8A93A8)),
      labelStyle: text.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.paperLine),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.paperLine),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.voltOnPaper, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: Color(0xFFDC2649)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: Color(0xFFDC2649), width: 1.6),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.voltOnPaper,
        foregroundColor: Colors.white,
        textStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.voltOnPaper,
        foregroundColor: Colors.white,
        elevation: 0,
        textStyle: text.labelLarge,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.inkOnPaper,
        textStyle: text.labelLarge,
        side: const BorderSide(color: Color(0xFFC4CDE0)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.voltOnPaper,
        textStyle: text.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFEBEFF8),
      side: const BorderSide(color: AppColors.paperLine),
      labelStyle: text.labelMedium?.copyWith(color: AppColors.inkOnPaper),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: text.headlineSmall,
      contentTextStyle: text.bodyMedium,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: Colors.white,
      showDragHandle: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shadowColor: const Color(0x33203050),
      textStyle: text.bodyLarge,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: const BorderSide(color: AppColors.paperLine),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.inkOnPaper,
      contentTextStyle: text.bodyLarge?.copyWith(color: Colors.white),
      actionTextColor: AppColors.volt,
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: const Color(0xFF57617A),
      textColor: AppColors.inkOnPaper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      side: const BorderSide(color: Color(0xFFC4CDE0), width: 1.6),
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.voltOnPaper
            : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(Colors.white),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : const Color(0xFF8A93A8),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.voltOnPaper
            : const Color(0xFFE4E9F5),
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.transparent
            : const Color(0xFFC4CDE0),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.voltOnPaper,
      linearTrackColor: Color(0xFFE4E9F5),
      circularTrackColor: Color(0xFFE4E9F5),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: AppColors.voltOnPaper,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    expansionTileTheme: const ExpansionTileThemeData(
      iconColor: Color(0xFF57617A),
      collapsedIconColor: Color(0xFF8A93A8),
      shape: Border(),
      collapsedShape: Border(),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.inkOnPaper,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      textStyle: text.labelMedium?.copyWith(color: Colors.white),
    ),
  );
}
