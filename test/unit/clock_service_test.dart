import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_clock/virtual_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    VirtualClock.reset();
  });

  group('ClockService Initialization', () {
    test('initializes with default clock rate of 1', () async {
      // Arrange
      final clockService = ClockService();

      // Act
      await clockService.initialize(const ClockConfig());

      // Assert
      expect(clockService.clockRate, 1);
      expect(clockService.isProduction, true);
      expect(clockService.isInitialized, true);
    });

    test('initializes with custom clock rate', () async {
      // Arrange
      final clockService = ClockService();

      // Act
      await clockService.initialize(const ClockConfig(clockRate: 100));

      // Assert
      expect(clockService.clockRate, 100);
      expect(clockService.isProduction, false);
    });

    test('throws when clock rate > 1 in production mode', () async {
      // Arrange
      final clockService = ClockService();

      // Act & Assert
      expect(
        () => clockService.initialize(
          const ClockConfig(
            clockRate: 100,
            isProduction: true,
          ),
        ),
        throwsException,
      );
    });
  });

  group('ClockService Time Calculation', () {
    test('returns current time when clock rate is 1', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig());

      // Act
      final before = DateTime.now();
      final virtualTime = clockService.now;
      final after = DateTime.now();

      // Assert
      expect(
        virtualTime.isAfter(before) || virtualTime.isAtSameMomentAs(before),
        true,
      );
      expect(
        virtualTime.isBefore(after) || virtualTime.isAtSameMomentAs(after),
        true,
      );
    });
  });

  group('ClockService Time Travel', () {
    test('timeTravelTo jumps to specific date', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));
      final targetDate = DateTime(2026, 12, 25, 10, 30);

      // Act
      clockService.timeTravelTo(targetDate);

      // Assert
      expect(clockService.now.year, 2026);
      expect(clockService.now.month, 12);
      expect(clockService.now.day, 25);
      expect(clockService.now.hour, 10);
      expect(clockService.now.minute, 30);
    });

    test('fastForward advances time by duration', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));
      final before = clockService.now;

      // Act
      clockService.fastForward(const Duration(days: 7));

      // Assert
      final after = clockService.now;
      final difference = after.difference(before);
      expect(difference.inDays, 7);
    });

    test('fastForward can advance by hours', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));
      final before = clockService.now;

      // Act
      clockService.fastForward(const Duration(hours: 3));

      // Assert
      final after = clockService.now;
      final difference = after.difference(before);
      expect(difference.inHours, 3);
    });
  });

  group('ClockService Pause and Resume', () {
    test('pause freezes time', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      // Act
      clockService.pause();
      final pausedTime = clockService.now;
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(clockService.now, pausedTime);
      expect(clockService.isPaused, true);
    });

    test('resume unfreezes time', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      // Act
      clockService.pause();
      expect(clockService.isPaused, true);
      clockService.resume();

      // Assert
      expect(clockService.isPaused, false);
    });

    test('multiple pause calls do not stack', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      // Act
      clockService.pause();
      final pausedTime1 = clockService.now;
      await Future.delayed(const Duration(milliseconds: 10));
      clockService.pause();
      final pausedTime2 = clockService.now;

      // Assert
      expect(pausedTime1, pausedTime2);
    });
  });

  group('ClockService Reset', () {
    test('reset returns to real time', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));
      clockService.timeTravelTo(DateTime(2030));

      // Act
      await clockService.reset();

      // Assert
      final now = DateTime.now();
      final diff = clockService.now.difference(now).abs();
      expect(diff.inSeconds < 2, true);
    });

    test('reset clears pause state', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));
      clockService.pause();
      expect(clockService.isPaused, true);

      // Act
      await clockService.reset();

      // Assert
      expect(clockService.isPaused, false);
    });
  });

  group('ClockService Rate Control', () {
    test('setClockRate updates rate and maintains time continuity', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));
      final beforeChange = clockService.now;

      // Act
      clockService.setClockRate(200);
      final afterChange = clockService.now;

      // Assert
      expect(clockService.clockRate, 200);
      final diff = afterChange.difference(beforeChange).abs();
      expect(diff.inMilliseconds < 1000, true);
    });

    test('setClockRate clamps negative values to 0', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      // Act
      clockService.setClockRate(-50);

      // Assert
      expect(clockService.clockRate, 0);
    });

    test('setClockRate clamps high values to 100000', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      // Act
      clockService.setClockRate(200000);

      // Assert
      expect(clockService.clockRate, 100000);
    });

    test('increaseClockRate doubles rate by default', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      // Act
      clockService.increaseClockRate();

      // Assert
      expect(clockService.clockRate, 200);
    });

    test('decreaseClockRate halves rate by default', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      // Act
      clockService.decreaseClockRate();

      // Assert
      expect(clockService.clockRate, 50);
    });

    test('changing rate while paused does not jump time', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));
      clockService.pause();
      final pausedTime = clockService.now;

      // Act
      clockService.setClockRate(500);

      // Assert
      expect(clockService.now, pausedTime);
      expect(clockService.clockRate, 500);
    });

    test('cannot change rate in production mode', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(
        const ClockConfig(
          isProduction: true,
        ),
      );

      // Act
      clockService.setClockRate(500);

      // Assert
      expect(clockService.clockRate, 1);
    });
  });
}
