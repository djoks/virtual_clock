import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_clock/virtual_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await VirtualClock.reset();
  });

  group('VirtualClock Global Accessor', () {
    test('throws StateError when not initialized', () {
      // Act & Assert
      expect(() => VirtualClock.service, throwsStateError);
    });

    test('isInitialized returns false before initialization', () {
      // Assert
      expect(VirtualClock.isInitialized, false);
    });

    test('returns service after initialization', () async {
      // Act
      await VirtualClock.setup(const ClockConfig(clockRate: 100));

      // Assert
      expect(VirtualClock.service.clockRate, 100);
      expect(VirtualClock.isInitialized, true);
    });

    test('clock getter works after initialization', () async {
      // Arrange
      await VirtualClock.setup(const ClockConfig(clockRate: 100));

      // Act & Assert
      expect(clock.clockRate, 100);
    });

    test('reset clears global service', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig());
      await VirtualClock.setup(const ClockConfig(clockRate: 100));

      // Act
      await VirtualClock.reset();

      // Assert
      expect(VirtualClock.isInitialized, false);
      expect(() => VirtualClock.service, throwsStateError);
    });
  });

  group('VirtualClockX DateTime Extensions', () {
    setUp(() async {
      await VirtualClock.setup(const ClockConfig(clockRate: 100));
    });

    test('isVirtualToday returns true for today', () {
      // Arrange
      final now = clock.now;

      // Act & Assert
      expect(now.isVirtualToday(), true);
    });

    test('isVirtualToday returns false for yesterday', () {
      // Arrange
      final yesterday = clock.now.subtract(const Duration(days: 1));

      // Act & Assert
      expect(yesterday.isVirtualToday(), false);
    });

    test('isVirtualToday returns false for tomorrow', () {
      // Arrange
      final tomorrow = clock.now.add(const Duration(days: 1));

      // Act & Assert
      expect(tomorrow.isVirtualToday(), false);
    });

    test('isVirtualYesterday returns true for yesterday', () {
      // Arrange
      final yesterday = clock.now.subtract(const Duration(days: 1));

      // Act & Assert
      expect(yesterday.isVirtualYesterday(), true);
    });

    test('isVirtualYesterday returns false for today', () {
      // Arrange
      final now = clock.now;

      // Act & Assert
      expect(now.isVirtualYesterday(), false);
    });

    test('isInVirtualPast returns true for past dates', () {
      // Arrange
      final pastDate = clock.now.subtract(const Duration(days: 1));

      // Act & Assert
      expect(pastDate.isInVirtualPast(), true);
    });

    test('isInVirtualPast returns false for future dates', () {
      // Arrange
      final futureDate = clock.now.add(const Duration(days: 1));

      // Act & Assert
      expect(futureDate.isInVirtualPast(), false);
    });

    test('isInVirtualFuture returns true for future dates', () {
      // Arrange
      final futureDate = clock.now.add(const Duration(days: 1));

      // Act & Assert
      expect(futureDate.isInVirtualFuture(), true);
    });

    test('isInVirtualFuture returns false for past dates', () {
      // Arrange
      final pastDate = clock.now.subtract(const Duration(days: 1));

      // Act & Assert
      expect(pastDate.isInVirtualFuture(), false);
    });

    test('differenceFromVirtualNow returns correct difference', () {
      // Arrange
      final futureDate = clock.now.add(const Duration(days: 7));

      // Act
      final diff = futureDate.differenceFromVirtualNow();

      // Assert (allow for slight timing variance)
      expect(diff.inDays, greaterThanOrEqualTo(6));
      expect(diff.inDays, lessThanOrEqualTo(7));
    });
  });
}
