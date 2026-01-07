import 'package:flutter/material.dart';

import 'package:virtual_clock/src/constants/colors.dart';
import 'package:virtual_clock/src/constants/values.dart';

// Re-export color constants for backwards compatibility
export 'package:virtual_clock/src/constants/colors.dart';
export 'package:virtual_clock/src/constants/values.dart'
    show kDefaultTimeFontFamily, kDefaultButtonRadius, kDefaultBadgeRadius;

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                         Theme Mode Enum                                  ║
// ╚══════════════════════════════════════════════════════════════════════════╝

/// Theme mode for TimeControlPanel.
enum TimeControlThemeMode {
  /// Follow system brightness (default).
  system,

  /// Always use light theme.
  light,

  /// Always use dark theme.
  dark,
}

// ╔══════════════════════════════════════════════════════════════════════════╗
// ║                       TimeControlTheme Class                             ║
// ╚══════════════════════════════════════════════════════════════════════════╝

/// Theme configuration for the TimeControlPanel widget.
///
/// All color fields are nullable and resolved at runtime based on brightness.
/// Use [resolve] to get a fully populated theme for a given brightness.
///
/// Example:
/// ```dart
/// TimeControlPanel(
///   themeMode: TimeControlThemeMode.system,
///   theme: TimeControlTheme(
///     accentColor: Colors.blue, // Override just accent
///   ),
/// )
/// ```
class TimeControlTheme {
  const TimeControlTheme({
    this.backgroundColor,
    this.backgroundSecondary,
    this.backgroundHover,
    this.borderColor,
    this.accentColor,
    this.accentDimColor,
    this.textPrimary,
    this.textSecondary,
    this.textTertiary,
    this.resetHoverColor,
    this.resetHoverBgColor,
    this.timeFontFamily = kDefaultTimeFontFamily,
    this.labelFontFamily,
    this.buttonRadius = kDefaultButtonRadius,
    this.badgeRadius = kDefaultBadgeRadius,
  });

  /// Primary background color for the panel.
  final Color? backgroundColor;

  /// Secondary background color for buttons.
  final Color? backgroundSecondary;

  /// Background color on hover.
  final Color? backgroundHover;

  /// Border color.
  final Color? borderColor;

  /// Accent color (for highlights like the "+" in time jumps).
  final Color? accentColor;

  /// Dimmed accent color (for backgrounds).
  final Color? accentDimColor;

  /// Primary text color.
  final Color? textPrimary;

  /// Secondary text color.
  final Color? textSecondary;

  /// Tertiary text color (for labels).
  final Color? textTertiary;

  /// Reset button hover color.
  final Color? resetHoverColor;

  /// Reset button hover background color.
  final Color? resetHoverBgColor;

  /// Font family for time display (monospace recommended).
  final String timeFontFamily;

  /// Font family for labels (null uses default).
  final String? labelFontFamily;

  /// Border radius for buttons.
  final double buttonRadius;

  /// Border radius for badges.
  final double badgeRadius;

  /// Dark theme preset using k-constants.
  static const dark = TimeControlTheme(
    backgroundColor: kDarkBackground,
    backgroundSecondary: kDarkBackgroundSecondary,
    backgroundHover: kDarkBackgroundHover,
    borderColor: kDarkBorder,
    accentColor: kDarkAccent,
    accentDimColor: kDarkAccentDim,
    textPrimary: kDarkTextPrimary,
    textSecondary: kDarkTextSecondary,
    textTertiary: kDarkTextTertiary,
    resetHoverColor: kDarkResetHover,
    resetHoverBgColor: kDarkResetHoverBg,
  );

  /// Light theme preset using k-constants.
  static const light = TimeControlTheme(
    backgroundColor: kLightBackground,
    backgroundSecondary: kLightBackgroundSecondary,
    backgroundHover: kLightBackgroundHover,
    borderColor: kLightBorder,
    accentColor: kLightAccent,
    accentDimColor: kLightAccentDim,
    textPrimary: kLightTextPrimary,
    textSecondary: kLightTextSecondary,
    textTertiary: kLightTextTertiary,
    resetHoverColor: kLightResetHover,
    resetHoverBgColor: kLightResetHoverBg,
  );

  /// Resolve theme colors based on brightness.
  ///
  /// Merges user overrides with the appropriate base theme (dark or light).
  TimeControlTheme resolve(Brightness brightness) {
    final base = brightness == Brightness.dark ? dark : light;
    return TimeControlTheme(
      backgroundColor: backgroundColor ?? base.backgroundColor,
      backgroundSecondary: backgroundSecondary ?? base.backgroundSecondary,
      backgroundHover: backgroundHover ?? base.backgroundHover,
      borderColor: borderColor ?? base.borderColor,
      accentColor: accentColor ?? base.accentColor,
      accentDimColor: accentDimColor ?? base.accentDimColor,
      textPrimary: textPrimary ?? base.textPrimary,
      textSecondary: textSecondary ?? base.textSecondary,
      textTertiary: textTertiary ?? base.textTertiary,
      resetHoverColor: resetHoverColor ?? base.resetHoverColor,
      resetHoverBgColor: resetHoverBgColor ?? base.resetHoverBgColor,
      timeFontFamily: timeFontFamily,
      labelFontFamily: labelFontFamily ?? base.labelFontFamily,
      buttonRadius: buttonRadius,
      badgeRadius: badgeRadius,
    );
  }

  /// Creates a copy with the given fields replaced.
  TimeControlTheme copyWith({
    Color? backgroundColor,
    Color? backgroundSecondary,
    Color? backgroundHover,
    Color? borderColor,
    Color? accentColor,
    Color? accentDimColor,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? resetHoverColor,
    Color? resetHoverBgColor,
    String? timeFontFamily,
    String? labelFontFamily,
    double? buttonRadius,
    double? badgeRadius,
  }) {
    return TimeControlTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      backgroundHover: backgroundHover ?? this.backgroundHover,
      borderColor: borderColor ?? this.borderColor,
      accentColor: accentColor ?? this.accentColor,
      accentDimColor: accentDimColor ?? this.accentDimColor,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      resetHoverColor: resetHoverColor ?? this.resetHoverColor,
      resetHoverBgColor: resetHoverBgColor ?? this.resetHoverBgColor,
      timeFontFamily: timeFontFamily ?? this.timeFontFamily,
      labelFontFamily: labelFontFamily ?? this.labelFontFamily,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      badgeRadius: badgeRadius ?? this.badgeRadius,
    );
  }
}
