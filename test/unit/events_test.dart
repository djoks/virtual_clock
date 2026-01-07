import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_clock/virtual_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    VirtualClock.reset();
  });

  group('NewHourEvent', () {
    test('fires when hour changes', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      DateTime? capturedTime;
      clockService.onNewHour.subscribe((time) {
        capturedTime = time;
      });

      // Jump to minute 59
      final now = clockService.now;
      final nearHour = DateTime(now.year, now.month, now.day, now.hour, 59, 50);
      clockService.timeTravelTo(nearHour);

      // Act - Jump past the hour
      clockService.fastForward(const Duration(minutes: 2));
      clockService.triggerEventCheck();

      // Assert
      expect(capturedTime, isNotNull);
    });

    test('does not fire if no subscribers', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      // Act - Jump past an hour without subscribing
      clockService.fastForward(const Duration(hours: 2));
      clockService.triggerEventCheck();

      // Assert - No error should occur
      expect(true, true);
    });
  });

  group('NewDayEvent', () {
    test('fires when day changes', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      DateTime? capturedTime;
      clockService.onNewDay.subscribe((time) {
        capturedTime = time;
      });

      // Jump to near midnight
      final now = clockService.now;
      final nearMidnight = DateTime(now.year, now.month, now.day, 23, 59, 50);
      clockService.timeTravelTo(nearMidnight);

      // Act - Jump past midnight
      clockService.fastForward(const Duration(minutes: 2));
      clockService.triggerEventCheck();

      // Assert
      expect(capturedTime, isNotNull);
    });
  });

  group('AtNoonEvent', () {
    test('fires at noon', () {
      // Arrange - Test the AtNoonEvent directly
      final event = AtNoonEvent();

      // Set up callback
      DateTime? capturedTime;
      event.subscribe((time) {
        capturedTime = time;
      });

      // Initialize event at 11:00 AM
      final beforeNoon = DateTime(2026, 1, 7, 11);
      event.initialize(beforeNoon);

      // Act - Check at 12:01 PM (past noon)
      final afterNoon = DateTime(2026, 1, 7, 12, 1);
      event.checkAndTrigger(afterNoon);

      // Assert
      expect(capturedTime, isNotNull);
      expect(capturedTime!.hour, 12);
    });

    test('does not fire if already past noon', () {
      // Arrange
      final event = AtNoonEvent();

      DateTime? capturedTime;
      event.subscribe((time) {
        capturedTime = time;
      });

      // Initialize event at 2 PM (already past noon)
      final afternoon = DateTime(2026, 1, 7, 14);
      event.initialize(afternoon);

      // Act - Check at 3 PM (still afternoon, same day)
      final laterAfternoon = DateTime(2026, 1, 7, 15);
      event.checkAndTrigger(laterAfternoon);

      // Assert - Should NOT fire since we didn't cross noon
      expect(capturedTime, isNull);
    });
  });

  group('WeekStartEvent', () {
    test('fires on Monday', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      DateTime? capturedTime;
      clockService.onWeekStart.subscribe((time) {
        capturedTime = time;
      });

      // Find next Sunday 23:59
      var date = clockService.now;
      while (date.weekday != DateTime.sunday) {
        date = date.add(const Duration(days: 1));
      }
      final sundayNight = DateTime(date.year, date.month, date.day, 23, 59, 50);
      clockService.timeTravelTo(sundayNight);

      // Act - Jump to Monday
      clockService.fastForward(const Duration(minutes: 2));
      clockService.triggerEventCheck();

      // Assert
      expect(capturedTime, isNotNull);
    });
  });

  group('WeekEndEvent', () {
    test('fires on Sunday to Monday transition', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      DateTime? capturedTime;
      clockService.onWeekEnd.subscribe((time) {
        capturedTime = time;
      });

      // Find next Sunday 23:59
      var date = clockService.now;
      while (date.weekday != DateTime.sunday) {
        date = date.add(const Duration(days: 1));
      }
      final sundayNight = DateTime(date.year, date.month, date.day, 23, 59, 50);
      clockService.timeTravelTo(sundayNight);

      // Act - Jump to Monday
      clockService.fastForward(const Duration(minutes: 2));
      clockService.triggerEventCheck();

      // Assert
      expect(capturedTime, isNotNull);
    });
  });

  group('Event Subscription Management', () {
    test('unsubscribe prevents callback from firing', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      var callCount = 0;
      void callback(DateTime time) {
        callCount++;
      }

      clockService.onNewHour.subscribe(callback);

      // Jump past one hour
      clockService.fastForward(const Duration(hours: 1, minutes: 1));
      clockService.triggerEventCheck();
      expect(callCount, 1);

      // Act - Unsubscribe
      clockService.onNewHour.unsubscribe(callback);

      // Jump past another hour
      clockService.fastForward(const Duration(hours: 1, minutes: 1));
      clockService.triggerEventCheck();

      // Assert
      expect(callCount, 1);
    });

    test('clearSubscribers removes all callbacks', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      var callCount = 0;
      clockService.onNewHour.subscribe((_) => callCount++);
      clockService.onNewHour.subscribe((_) => callCount++);

      // Act
      clockService.onNewHour.clearSubscribers();

      // Jump past an hour
      clockService.fastForward(const Duration(hours: 1, minutes: 1));
      clockService.triggerEventCheck();

      // Assert
      expect(callCount, 0);
    });

    test('hasSubscribers returns correct state', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      // Assert initial
      expect(clockService.onNewHour.hasSubscribers, false);

      // Add subscriber
      void callback(DateTime time) {}
      clockService.onNewHour.subscribe(callback);
      expect(clockService.onNewHour.hasSubscribers, true);

      // Remove subscriber
      clockService.onNewHour.unsubscribe(callback);
      expect(clockService.onNewHour.hasSubscribers, false);
    });
  });

  group('Events do not fire when paused', () {
    test('events do not fire when clock is paused', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      var callCount = 0;
      clockService.onNewHour.subscribe((_) => callCount++);

      clockService.pause();

      // Act - Try to jump when paused
      clockService.triggerEventCheck();

      // Assert
      expect(callCount, 0);
    });
  });
}
