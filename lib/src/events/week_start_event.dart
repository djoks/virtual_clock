import 'package:virtual_clock/src/events/clock_event.dart';

/// Event that fires at the start of each new week (Monday).
///
/// Triggers when the virtual time enters a new week (Monday 00:00).
///
/// Example:
/// ```dart
/// clock.onWeekStart.subscribe((time) {
///   print('New week started on ${time.day}/${time.month}');
///   resetWeeklyChallenge();
/// });
/// ```
class WeekStartEvent extends ClockEvent {
  WeekStartEvent() : super(name: 'onWeekStart');

  @override
  bool shouldTrigger(DateTime previousTime, DateTime currentTime) {
    // Get the ISO week number for both times
    final prevWeek = _getIsoWeekNumber(previousTime);
    final currWeek = _getIsoWeekNumber(currentTime);

    // Trigger if we're in a different week or different year
    return prevWeek != currWeek || previousTime.year != currentTime.year;
  }

  /// Calculate ISO week number (weeks start on Monday).
  int _getIsoWeekNumber(DateTime date) {
    // Find the Thursday of this week (ISO 8601 week definition)
    // ignore: avoid_redundant_argument_values
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    // ignore: avoid_redundant_argument_values
    final firstThursday = DateTime(thursday.year, 1, 1);

    // If Jan 1 is not a Thursday, find the first Thursday
    // ignore: avoid_redundant_argument_values
    final daysToAdd = (DateTime.thursday - firstThursday.weekday + 7) % 7;
    final firstThursdayOfYear = firstThursday.add(Duration(days: daysToAdd));

    // Calculate week number
    return ((thursday.difference(firstThursdayOfYear).inDays) / 7).floor() + 1;
  }
}
