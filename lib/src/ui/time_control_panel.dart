import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:virtual_clock/virtual_clock.dart';

/// Debug panel for controlling virtual time during development and testing.
///
/// Provides controls for:
/// - Time display with current virtual time
/// - Fast forward buttons (+1h, +3h, +6h, +1d, +3d, +1w)
/// - Jump to tomorrow
/// - Pick custom date/time
/// - Pause/Resume time
/// - Reset to real time
///
/// Uses the global [clock] accessor by default, so no configuration needed:
/// ```dart
/// // Simple usage - uses global clock automatically
/// TimeControlPanel()
///
/// // With theme customization
/// TimeControlPanel(
///   themeMode: TimeControlThemeMode.dark,
///   theme: TimeControlTheme(accentColor: Colors.blue),
/// )
/// ```
class TimeControlPanel extends StatefulWidget {
  const TimeControlPanel({
    super.key,
    this.theme = const TimeControlTheme(),
    this.themeMode = TimeControlThemeMode.system,
    this.clockIcon,
    this.embedded = false,
    this.isOpen = true,
    this.onClose,
    this.showBorder = true,
  });

  /// Theme configuration for colors and styling.
  /// Use with [themeMode] for automatic light/dark support.
  final TimeControlTheme theme;

  /// Theme mode: system (default), light, or dark.
  final TimeControlThemeMode themeMode;

  /// Custom clock icon widget. If null, uses a default clock icon.
  final Widget? clockIcon;

  /// Whether the panel is embedded in another widget.
  final bool embedded;

  /// Controls whether the border is shown (only visible when panel is open).
  final bool isOpen;

  /// Callback when close is requested.
  final VoidCallback? onClose;

  /// Whether to show the left border.
  final bool showBorder;

  @override
  State<TimeControlPanel> createState() => _TimeControlPanelState();
}

class _TimeControlPanelState extends State<TimeControlPanel>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _updateTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Hover states for interactive elements
  bool _resetHovered = false;
  bool _pauseHovered = false;
  final Map<String, bool> _jumpButtonHovered = {};
  final Map<String, bool> _dateButtonHovered = {};

  ClockService get _clock => clock;

  /// Resolve theme based on theme mode and system brightness.
  TimeControlTheme _resolveTheme(BuildContext context) {
    final brightness = switch (widget.themeMode) {
      TimeControlThemeMode.system => MediaQuery.platformBrightnessOf(context),
      TimeControlThemeMode.light => Brightness.light,
      TimeControlThemeMode.dark => Brightness.dark,
    };
    return widget.theme.resolve(brightness);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startUpdateTimer();

    // Pulse animation for clock icon
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: kAnimationDurationPulse),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause timer when app is backgrounded to save CPU/battery
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _updateTimer?.cancel();
      _updateTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      _startUpdateTimer();
    }
  }

  /// Start the periodic UI update timer.
  void _startUpdateTimer() {
    _updateTimer?.cancel();
    _updateTimer = Timer.periodic(
      const Duration(seconds: kUpdateTimerIntervalSeconds),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final virtualTime = _clock.now;
    final isPaused = _clock.isPaused;
    final theme = _resolveTheme(context);

    return Material(
      color: theme.backgroundColor,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: widget.showBorder && widget.isOpen
              ? Border(left: BorderSide(color: theme.borderColor!))
              : null,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(theme, virtualTime, isPaused),
                const SizedBox(height: 24),
                _buildSectionHeader(theme, kLabelJump),
                const SizedBox(height: 12),
                _buildJumpGrid(theme),
                const SizedBox(height: 24),
                _buildSectionHeader(theme, kLabelDate),
                const SizedBox(height: 12),
                _buildDateOption(
                  theme: theme,
                  icon: Icons.wb_sunny_outlined,
                  label: kLabelTomorrow,
                  id: 'tomorrow',
                  onTap: () {
                    final tomorrow = _clock.now.add(const Duration(days: 1));
                    _clock.timeTravelTo(
                      DateTime(tomorrow.year, tomorrow.month, tomorrow.day),
                    );
                    setState(() {});
                  },
                ),
                const SizedBox(height: 8),
                _buildDateOption(
                  theme: theme,
                  icon: Icons.calendar_today_outlined,
                  label: kLabelPickDate,
                  id: 'pickDate',
                  onTap: _showCustomDatePicker,
                ),
                const SizedBox(height: 12),
                Container(height: 1, color: theme.borderColor),
                const Spacer(),
                _buildPauseButton(theme, isPaused),
                const SizedBox(height: 12),
                _buildResetButton(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    TimeControlTheme theme,
    DateTime virtualTime,
    bool isPaused,
  ) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.borderColor!)),
      ),
      child: Column(
        children: [
          // Clock icon with pulse
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.accentDimColor,
              ),
              child: widget.clockIcon ??
                  Icon(
                    Icons.access_time,
                    size: 32,
                    color: theme.accentColor,
                  ),
            ),
          ),
          const SizedBox(height: 12),

          // Time display
          Text(
            DateFormat('HH:mm:ss').format(virtualTime),
            style: TextStyle(
              fontFamily: theme.timeFontFamily,
              fontWeight: FontWeight.w700,
              fontSize: 28,
              color: theme.textPrimary,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),

          // Date display
          Text(
            DateFormat('EEE, MMM d').format(virtualTime),
            style: TextStyle(
              fontFamily: theme.labelFontFamily,
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: theme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          // Speed badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: theme.accentDimColor,
              borderRadius: BorderRadius.circular(theme.badgeRadius),
            ),
            child: Text(
              '${_clock.clockRate}x',
              style: TextStyle(
                fontFamily: theme.timeFontFamily,
                fontWeight: FontWeight.w400,
                fontSize: 10,
                color: theme.accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(TimeControlTheme theme, String title) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: theme.labelFontFamily,
        fontWeight: FontWeight.w500,
        fontSize: 9,
        color: theme.textTertiary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildJumpGrid(TimeControlTheme theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildJumpButton(theme, '+1h', const Duration(hours: 1)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildJumpButton(theme, '+3h', const Duration(hours: 3)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildJumpButton(theme, '+6h', const Duration(hours: 6)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildJumpButton(theme, '+1d', const Duration(days: 1)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildJumpButton(theme, '+3d', const Duration(days: 3)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildJumpButton(theme, '+1w', const Duration(days: 7)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildJumpButton(
    TimeControlTheme theme,
    String label,
    Duration duration,
  ) {
    final isHovered = _jumpButtonHovered[label] ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _jumpButtonHovered[label] = true),
      onExit: (_) => setState(() => _jumpButtonHovered[label] = false),
      child: GestureDetector(
        onTap: () {
          _clock.fastForward(duration);
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: kAnimationDurationHover),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color:
                isHovered ? theme.backgroundHover : theme.backgroundSecondary,
            borderRadius: BorderRadius.circular(theme.buttonRadius),
            border: Border.all(color: theme.borderColor!),
          ),
          child: Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '+',
                    style: TextStyle(
                      fontFamily: theme.timeFontFamily,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: theme.accentColor,
                    ),
                  ),
                  TextSpan(
                    text: label.substring(1),
                    style: TextStyle(
                      fontFamily: theme.timeFontFamily,
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: theme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateOption({
    required TimeControlTheme theme,
    required IconData icon,
    required String label,
    required String id,
    required VoidCallback onTap,
  }) {
    final isHovered = _dateButtonHovered[id] ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _dateButtonHovered[id] = true),
      onExit: (_) => setState(() => _dateButtonHovered[id] = false),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: kAnimationDurationHover),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isHovered ? theme.backgroundHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: kAnimationDurationHover),
                opacity: isHovered ? 1.0 : 0.5,
                child: Icon(
                  icon,
                  color: isHovered ? theme.textPrimary : theme.textSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontFamily: theme.labelFontFamily,
                  fontWeight: FontWeight.w400,
                  fontSize: 13,
                  color: isHovered ? theme.textPrimary : theme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPauseButton(TimeControlTheme theme, bool isPaused) {
    return MouseRegion(
      onEnter: (_) => setState(() => _pauseHovered = true),
      onExit: (_) => setState(() => _pauseHovered = false),
      child: GestureDetector(
        onTap: () {
          if (isPaused) {
            _clock.resume();
          } else {
            _clock.pause();
          }
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: kAnimationDurationHover),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          decoration: BoxDecoration(
            color: _pauseHovered
                ? theme.backgroundHover
                : theme.backgroundSecondary,
            borderRadius: BorderRadius.circular(theme.buttonRadius),
            border: Border.all(color: theme.borderColor!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPaused ? Icons.play_arrow : Icons.pause,
                color: theme.textPrimary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                isPaused ? kLabelResume : kLabelPause,
                style: TextStyle(
                  fontFamily: theme.labelFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: theme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResetButton(TimeControlTheme theme) {
    return MouseRegion(
      onEnter: (_) => setState(() => _resetHovered = true),
      onExit: (_) => setState(() => _resetHovered = false),
      child: GestureDetector(
        onTap: () async {
          await _clock.reset();
          if (mounted) setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: kAnimationDurationHover),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          decoration: BoxDecoration(
            color: _resetHovered ? theme.resetHoverBgColor : Colors.transparent,
            borderRadius: BorderRadius.circular(theme.buttonRadius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.refresh,
                color:
                    _resetHovered ? theme.resetHoverColor : theme.textTertiary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                kLabelReset,
                style: TextStyle(
                  fontFamily: theme.labelFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: _resetHovered
                      ? theme.resetHoverColor
                      : theme.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _clock.now,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null && mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_clock.now),
      );

      if (pickedTime != null && mounted) {
        final customDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _clock.timeTravelTo(customDateTime);
        });
      }
    }
  }
}
