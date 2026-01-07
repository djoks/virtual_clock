import 'package:virtual_clock/src/events/clock_event.dart';

/// Event that fires at the start of each new hour.
///
/// Triggers when the hour component of the virtual time changes.
///
/// Example:
/// ```dart
/// clock.onNewHour.subscribe((time) {
///   print('New hour started: ${time.hour}:00');
/// });
/// ```
class NewHourEvent extends ClockEvent {
  NewHourEvent() : super(name: 'onNewHour');

  @override
  bool shouldTrigger(DateTime previousTime, DateTime currentTime) {
    // Only trigger when the hour component actually changes.
    // Use truncated timestamps to avoid sub-hour comparisons.
    final prevHourStart = DateTime(
      previousTime.year,
      previousTime.month,
      previousTime.day,
      previousTime.hour,
    );
    final currHourStart = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      currentTime.hour,
    );
    return currHourStart.isAfter(prevHourStart);
  }
}
