import 'package:flutter/material.dart';
import 'package:virtual_clock/src/ui/time_control_overlay.dart';
import 'package:virtual_clock/src/ui/time_control_theme.dart';
import 'package:virtual_clock/virtual_clock.dart';

/// A wrapper widget that encapsulates the [TimeControlPanelOverlay].
///
/// Use this widget to provide the sliding time control panel to your application.
///
/// Example:
/// ```dart
/// TimeMachine(
///   child: MaterialApp(
///     home: MyHomeScreen(),
///   ),
/// )
/// ```
class TimeMachine extends StatelessWidget {
  const TimeMachine({
    required this.child,
    super.key,
    this.panelWidth = 200,
    this.theme = const TimeControlTheme(),
    this.themeMode = TimeControlThemeMode.system,
    this.buttonBuilder,
    this.forceShow = false,
    this.overlayColor,
  });

  /// The main app content to display behind the panel.
  final Widget child;

  /// Width of the slide-out panel.
  final double panelWidth;

  /// Theme configuration for the panel.
  final TimeControlTheme theme;

  /// Theme mode: system (default), light, or dark.
  final TimeControlThemeMode themeMode;

  /// Custom builder for the toggle button.
  final Widget Function(BuildContext context, {required bool isOpen})?
      buttonBuilder;

  /// Force show the panel even in production mode.
  final bool forceShow;

  /// Color for the dark overlay behind the panel.
  final Color? overlayColor;

  @override
  Widget build(BuildContext context) {
    return TimeControlPanelOverlay(
      panelWidth: panelWidth,
      theme: theme,
      themeMode: themeMode,
      buttonBuilder: buttonBuilder,
      forceShow: forceShow,
      overlayColor: overlayColor,
      child: child,
    );
  }
}
