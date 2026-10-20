import 'package:flutter/material.dart';

/// Final Lab2 tokens, not the historical DESIGN.md at repository root.
abstract final class AppColors {
  static const primary = Color(0xFF006C49);
  static const accent = Color(0xFF10B981);
  static const background = Color(0xFFFAF8FF);
  static const surface = Color(0xFFFFFFFF);
  static const text = Color(0xFF131B2E);
  static const muted = Color(0xFF52625C);
  static const border = Color(0xFF73867A);
  static const soft = Color(0xFFE8F7EF);
  static const danger = Color(0xFFBA1A1A);
  static const error = Color(0xFFFFDAD6);
  static const amber = Color(0xFF895900);
  static const disabled = Color(0xFFD3E3DC);
  // Documented dashboard extensions: quiet structural dividers and frame.
  static const line = Color(0xFFE8ECE9);
  static const frame = Color(0xFFF3F6F4);
  static const neutral = Color(0xFFF4F5F6);
  static const chartSecondary = Color(0xFF52625C);
  static const chartTertiary = Color(0xFF9BAD9F);
}

abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const cardRadius = 20.0;
  static const controlRadius = 12.0;
  static const touch = 48.0;
  static const button = 52.0;
  static const sidebar = 236.0;
  static const wide = 1000.0;
}

abstract final class AppMotion {
  static const short = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const chart = Duration(milliseconds: 650);
  static const curve = Curves.easeOutCubic;
  static Duration duration(BuildContext context, Duration value) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : value;
}

class MotionAwareTransitions extends PageTransitionsBuilder {
  const MotionAwareTransitions({
    this.delegate = const FadeForwardsPageTransitionsBuilder(),
  });
  final PageTransitionsBuilder delegate;
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => MediaQuery.disableAnimationsOf(context)
      ? child
      : delegate.buildTransitions(
          route,
          context,
          animation,
          secondaryAnimation,
          child,
        );
}

ThemeData buildAppTheme() {
  const base = TextStyle(
    fontFamily: 'Inter',
    color: AppColors.text,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
    primary: AppColors.primary,
    secondary: AppColors.primary,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.danger,
    outline: AppColors.border,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.background,
    textTheme: TextTheme(
      displaySmall: base.copyWith(
        fontSize: 28,
        height: 36 / 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -.7,
      ),
      headlineSmall: base.copyWith(
        fontSize: 24,
        height: 32 / 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -.5,
      ),
      titleLarge: base.copyWith(
        fontSize: 18,
        height: 26 / 18,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: base.copyWith(
        fontSize: 16,
        height: 1.5,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: base.copyWith(fontSize: 14, height: 20 / 14),
      bodySmall: base.copyWith(
        fontSize: 14,
        height: 20 / 14,
        color: AppColors.muted,
      ),
      labelLarge: base.copyWith(
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.copyWith(fontSize: 14, height: 20 / 14),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, AppSpace.button),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: base.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpace.controlRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, AppSpace.touch),
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpace.controlRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(AppSpace.touch, AppSpace.touch),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(AppSpace.touch, AppSpace.touch),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        minimumSize: const Size(AppSpace.touch, AppSpace.touch),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      helperMaxLines: 12,
      errorMaxLines: 12,
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpace.controlRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpace.controlRadius),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpace.controlRadius),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.soft,
      height: 80,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => base.copyWith(
          fontSize: 14,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w600
              : FontWeight.w400,
        ),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpace.cardRadius),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: MotionAwareTransitions(),
        TargetPlatform.iOS: MotionAwareTransitions(
          delegate: ZoomPageTransitionsBuilder(),
        ),
        TargetPlatform.macOS: MotionAwareTransitions(
          delegate: ZoomPageTransitionsBuilder(),
        ),
        TargetPlatform.windows: MotionAwareTransitions(),
        TargetPlatform.linux: MotionAwareTransitions(),
      },
    ),
  );
}
