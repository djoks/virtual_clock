import 'package:virtual_clock/src/events/clock_event.dart';

/// Event that fires at the end of each week (Sunday 23:59:59 or Monday 00:00).
///
/// Triggers when the virtual time leaves Sunday and enters Monday.
///
/// Example:
/// ```dart
/// clock.onWeekEnd.subscribe((time) {
///   print('Week ended');
///   calculateWeeklyStats();
/// });
/// ```
class WeekEndEvent extends ClockEvent {
  WeekEndEvent() : super(name: 'onWeekEnd');

  @override
  bool shouldTrigger(DateTime previousTime, DateTime currentTime) {
    // Week ends when we move from Sunday to Monday
    // DateTime.weekday: Monday = 1, Sunday = 7
    final prevWasSunday = previousTime.weekday == DateTime.sunday;
    final currIsMonday = currentTime.weekday == DateTime.monday;

    // If previous was Sunday and current is Monday (or later in a new week)
    if (prevWasSunday &&
        currIsMonday &&
        !_isSameDay(previousTime, currentTime)) {
      return true;
    }

    // Handle fast-forward across multiple days
    // Check if we jumped over a Sunday-Monday boundary
    if (!_isSameDay(previousTime, currentTime)) {
      final daysDiff = currentTime.difference(previousTime).inDays;
      if (daysDiff >= 7) {
        // We jumped at least a full week, definitely crossed a week boundary
        return true;
      }

      // Check if we crossed from one week to another
      return _crossedWeekBoundary(previousTime, currentTime);
    }

    return false;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _crossedWeekBoundary(DateTime from, DateTime to) {
    // Get the Monday of each week
    final fromMonday = from.subtract(Duration(days: from.weekday - 1));
    final toMonday = to.subtract(Duration(days: to.weekday - 1));

    // Different weeks if Mondays are different
    return !_isSameDay(fromMonday, toMonday);
  }
}
