import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_clock/virtual_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await VirtualClock.reset();
  });

  group('VirtualTimer.periodic', () {
    test('creates a periodic timer with clock service', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      var callCount = 0;

      // Act
      final timer = VirtualTimer.periodic(
        clockService,
        const Duration(milliseconds: 100),
        (_) => callCount++,
      );

      // Wait real time (accelerated)
      await Future.delayed(const Duration(milliseconds: 50));

      // Assert
      expect(callCount, greaterThan(0));

      // Cleanup
      timer.cancel();
    });

    test('timer can be cancelled', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      var callCount = 0;
      final timer = VirtualTimer.periodic(
        clockService,
        const Duration(milliseconds: 50),
        (_) => callCount++,
      );

      // Wait for some calls
      await Future.delayed(const Duration(milliseconds: 30));
      final countAfterWait = callCount;

      // Act - Cancel
      timer.cancel();

      // Wait more
      await Future.delayed(const Duration(milliseconds: 30));

      // Assert - Count should not have increased much
      expect(callCount, lessThanOrEqualTo(countAfterWait + 2));
    });
  });

  group('VirtualTimer.delayed', () {
    test('fires after specified virtual duration', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      var fired = false;

      // Act
      VirtualTimer.delayed(
        clockService,
        const Duration(milliseconds: 100),
        () => fired = true,
      );

      // Wait for real time equivalent
      await Future.delayed(const Duration(milliseconds: 20));

      // Assert
      expect(fired, true);
    });

    test('delayed timer can be cancelled before firing', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 10));

      var fired = false;

      final timer = VirtualTimer.delayed(
        clockService,
        const Duration(milliseconds: 500),
        () => fired = true,
      );

      // Act - Cancel immediately
      timer.cancel();

      // Wait past the delay
      await Future.delayed(const Duration(milliseconds: 100));

      // Assert
      expect(fired, false);
    });
  });

  group('VirtualTimer.wait', () {
    test('completes after virtual duration', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      var completed = false;

      // Act
      unawaited(
        VirtualTimer.wait(
          clockService,
          const Duration(milliseconds: 100),
        ).then((_) => completed = true),
      );

      // Wait for real time equivalent
      await Future.delayed(const Duration(milliseconds: 20));

      // Assert
      expect(completed, true);
    });
  });

  group('VirtualTimer with global clock', () {
    test('periodicWithClock uses global clock', () async {
      // Arrange
      await VirtualClock.setup(const ClockConfig(clockRate: 100));

      var callCount = 0;

      // Act
      final timer = VirtualTimer.periodicWithClock(
        const Duration(milliseconds: 50),
        (_) => callCount++,
      );

      // Wait
      await Future.delayed(const Duration(milliseconds: 20));

      // Assert
      expect(callCount, greaterThan(0));

      // Cleanup
      timer.cancel();
    });

    test('delayedWithClock uses global clock', () async {
      // Arrange
      await VirtualClock.setup(const ClockConfig(clockRate: 100));

      var fired = false;

      // Act
      VirtualTimer.delayedWithClock(
        const Duration(milliseconds: 50),
        () => fired = true,
      );

      // Wait
      await Future.delayed(const Duration(milliseconds: 20));

      // Assert
      expect(fired, true);
    });

    test('waitWithClock uses global clock', () async {
      // Arrange
      await VirtualClock.setup(const ClockConfig(clockRate: 100));

      var completed = false;

      // Act
      unawaited(
        VirtualTimer.waitWithClock(
          const Duration(milliseconds: 50),
        ).then((_) => completed = true),
      );

      // Wait
      await Future.delayed(const Duration(milliseconds: 20));

      // Assert
      expect(completed, true);
    });
  });
}
