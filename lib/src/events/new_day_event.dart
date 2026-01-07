import 'package:virtual_clock/src/events/clock_event.dart';

/// Event that fires at the start of each new day (midnight).
///
/// Triggers when the date component of the virtual time changes.
///
/// Example:
/// ```dart
/// clock.onNewDay.subscribe((time) {
///   print('New day: ${time.day}/${time.month}/${time.year}');
///   resetDailyBonuses();
/// });
/// ```
class NewDayEvent extends ClockEvent {
  NewDayEvent() : super(name: 'onNewDay');

  @override
  bool shouldTrigger(DateTime previousTime, DateTime currentTime) {
    // Trigger when the day, month, or year changes
    return previousTime.day != currentTime.day ||
        previousTime.month != currentTime.month ||
        previousTime.year != currentTime.year;
  }
}
