import 'package:virtual_clock/src/events/clock_event.dart';

/// Event that fires at noon (12:00 PM) each day.
///
/// Triggers when the virtual time crosses 12:00 PM.
///
/// Example:
/// ```dart
/// clock.atNoon.subscribe((time) {
///   print('It is noon on ${time.day}/${time.month}');
/// });
/// ```
class AtNoonEvent extends ClockEvent {
  AtNoonEvent() : super(name: 'atNoon');

  @override
  bool shouldTrigger(DateTime previousTime, DateTime currentTime) {
    // Trigger when we cross noon (previous was before noon, current is noon or after)
    // Also handle day changes where we might have skipped past noon
    final prevIsBeforeNoon = previousTime.hour < 12;
    final currIsNoonOrAfter = currentTime.hour >= 12;

    // Same day: crossed noon
    if (_isSameDay(previousTime, currentTime)) {
      return prevIsBeforeNoon && currIsNoonOrAfter;
    }

    // Different day: trigger if current time is noon or after
    // (we jumped forward and should have hit noon)
    return currIsNoonOrAfter;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
