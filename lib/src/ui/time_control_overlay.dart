import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:virtual_clock/virtual_clock.dart';

/// A wrapper widget that provides a sliding time control panel overlay.
///
/// Wrap your app or screen with this widget to get a slide-out panel
/// for controlling virtual time during development and testing.
///
/// Features:
/// - Slide-out panel from right edge with smooth animation
/// - Dark overlay when open (tap to dismiss)
/// - Drag gestures to open/close with velocity detection
/// - Persistent toggle button attached to panel edge
/// - Production safety: only visible when clockRate ≠ 1 (unless [forceShow] is true)
///
/// Example:
/// ```dart
/// // Wrap at root level for global access
/// TimeControlPanelOverlay(
///   child: MaterialApp(
///     home: MyHomeScreen(),
///   ),
/// )
/// ```
class TimeControlPanelOverlay extends StatefulWidget {
  const TimeControlPanelOverlay({
    required this.child,
    super.key,
    this.clockService,
    this.panelWidth = 200,
    this.theme = const TimeControlTheme(),
    this.themeMode = TimeControlThemeMode.system,
    this.buttonBuilder,
    this.forceShow = false,
    this.overlayColor,
  });

  /// The main app content to display behind the panel.
  final Widget child;

  /// The ClockService to control. If null, uses global [clock].
  final ClockService? clockService;

  /// Width of the slide-out panel.
  final double panelWidth;

  /// Theme configuration for the panel.
  final TimeControlTheme theme;

  /// Theme mode: system (default), light, or dark.
  final TimeControlThemeMode themeMode;

  /// Custom builder for the toggle button.
  /// If null, uses a default button with three dots icon.
  final Widget Function(BuildContext context, {required bool isOpen})?
      buttonBuilder;

  /// Force show the panel even in production mode.
  /// By default, the panel is hidden when clockRate == 1.
  final bool forceShow;

  /// Color for the dark overlay behind the panel.
  /// Defaults to black with 30% opacity.
  final Color? overlayColor;

  @override
  State<TimeControlPanelOverlay> createState() =>
      _TimeControlPanelOverlayState();
}

class _TimeControlPanelOverlayState extends State<TimeControlPanelOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _panelController;
  bool _isPanelOpen = false;

  ClockService get _clock => widget.clockService ?? clock;

  /// Whether to show the panel based on production mode and clock rate.
  bool get _shouldShow {
    if (widget.forceShow) return true;
    if (kReleaseMode) return false;
    return _clock.clockRate != 1;
  }

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  void _togglePanel() {
    setState(() {
      _isPanelOpen = !_isPanelOpen;
      if (_isPanelOpen) {
        _panelController.forward();
      } else {
        _panelController.reverse();
      }
    });
  }

  void _closePanel() {
    if (_isPanelOpen) {
      setState(() {
        _isPanelOpen = false;
        _panelController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to clock changes to show/hide panel
    return ListenableBuilder(
      listenable: _clock,
      builder: (context, _) {
        return Directionality(
          // Provide directionality for panel widgets when overlay is outside MaterialApp
          textDirection: TextDirection.ltr,
          child: Stack(
            alignment: Alignment.topLeft,
            children: [
              // Main content
              widget.child,

              // Only show panel controls if conditions are met
              if (_shouldShow) ...[
                // Dark overlay when panel is open
                if (_isPanelOpen)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _closePanel,
                      child: Container(
                        color: widget.overlayColor ??
                            Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  ),

                // Sliding panel with attached toggle button
                Positioned(
                  top: 0,
                  bottom: 0,
                  right: 0,
                  child: _buildSlidingPanel(context),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSlidingPanel(BuildContext context) {
    final panelWidth = min(
      widget.panelWidth,
      MediaQuery.of(context).size.width * 0.5,
    );

    return AnimatedBuilder(
      animation: _panelController,
      builder: (context, child) {
        // Slide only the panel width, keeping button visible
        final offset = (1 - _panelController.value) * panelWidth;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: GestureDetector(
        onHorizontalDragUpdate: (details) {
          // Smoothly drag the panel
          final delta = -details.primaryDelta! / panelWidth;
          _panelController.value =
              (_panelController.value + delta).clamp(0.0, 1.0);
        },
        onHorizontalDragEnd: (details) {
          // Snap to open or closed based on velocity and position
          final velocity = details.primaryVelocity ?? 0;
          if (velocity > 300) {
            // Fast swipe right - close
            _panelController.reverse();
            _isPanelOpen = false;
          } else if (velocity < -300) {
            // Fast swipe left - open
            _panelController.forward();
            _isPanelOpen = true;
          } else {
            // Snap based on position
            if (_panelController.value > 0.5) {
              _panelController.forward();
              _isPanelOpen = true;
            } else {
              _panelController.reverse();
              _isPanelOpen = false;
            }
          }
          setState(() {});
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Toggle button (centered vertically)
            Center(
              child: _buildToggleButton(context),
            ),
            // Panel content
            SizedBox(
              width: panelWidth,
              child: TimeControlPanel(
                clockService: widget.clockService,
                theme: widget.theme,
                themeMode: widget.themeMode,
                embedded: true,
                isOpen: _isPanelOpen,
                showBorder: false,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton(BuildContext context) {
    if (widget.buttonBuilder != null) {
      return GestureDetector(
        onTap: _togglePanel,
        child: widget.buttonBuilder!(context, isOpen: _isPanelOpen),
      );
    }

    // Default toggle button
    final theme = widget.theme.resolve(
      widget.themeMode == TimeControlThemeMode.system
          ? MediaQuery.platformBrightnessOf(context)
          : widget.themeMode == TimeControlThemeMode.dark
              ? Brightness.dark
              : Brightness.light,
    );

    return GestureDetector(
      onTap: _togglePanel,
      child: Container(
        width: 28,
        height: 80,
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(14),
            bottomLeft: Radius.circular(14),
          ),
          border: Border(
            top: BorderSide(color: theme.borderColor!),
            left: BorderSide(color: theme.borderColor!),
            bottom: BorderSide(color: theme.borderColor!),
          ),
        ),
        child: Icon(
          Icons.more_vert,
          color: theme.textTertiary,
          size: 20,
        ),
      ),
    );
  }
}
