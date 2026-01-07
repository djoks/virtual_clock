import 'package:virtual_clock/src/services/clock_service.dart';

/// Global accessor for the ClockService instance.
///
/// Provides a convenient way to access virtual time from anywhere in your app.
///
/// ## Setup
///
/// Initialize once during app startup:
/// ```dart
/// final clockService = ClockService();
/// await clockService.initialize(ClockConfig(clockRate: 100));
/// VirtualClock.initialize(clockService);
/// ```
///
/// ## Usage
///
/// After initialization, use the global `clock` getter:
/// ```dart
/// // Get current virtual time
/// final now = clock.now;
///
/// // Time travel
/// clock.timeTravelTo(DateTime(2026, 1, 1));
///
/// // Fast forward
/// clock.fastForward(Duration(days: 7));
///
/// // Pause for deterministic tests
/// clock.pause();
/// final frozenTime = clock.now;
/// await Future.delayed(Duration(seconds: 5));
/// assert(clock.now == frozenTime); // Time hasn't moved
/// clock.resume();
/// ```
class VirtualClock {
  VirtualClock._();

  static ClockService? _service;

  /// Initialize the global clock accessor with a ClockService instance.
  ///
  /// This should be called once during app startup after the ClockService
  /// has been initialized.
  ///
  /// Example:
  /// ```dart
  /// final clockService = ClockService();
  /// await clockService.initialize(ClockConfig(clockRate: 100));
  /// VirtualClock.initialize(clockService);
  /// ```
  static void initialize(ClockService clockService) {
    _service = clockService;
  }

  /// Get the global ClockService instance.
  ///
  /// Throws [StateError] if [initialize] hasn't been called.
  static ClockService get service {
    if (_service == null) {
      throw StateError(
        'VirtualClock not initialized. Call VirtualClock.initialize() first.',
      );
    }
    return _service!;
  }

  /// Check if the global clock has been initialized.
  static bool get isInitialized => _service != null;

  /// Reset the global clock instance.
  ///
  /// Useful for testing to reset state between tests.
  static void reset() {
    _service = null;
  }
}

/// Global clock property accessible anywhere in the application.
///
/// Provides convenient access to the ClockService for virtual time operations.
///
/// ## Setup Required
///
/// Before using, you must initialize the global clock:
/// ```dart
/// final clockService = ClockService();
/// await clockService.initialize(ClockConfig(clockRate: 100));
/// VirtualClock.initialize(clockService);
/// ```
///
/// ## Usage
///
/// ```dart
/// // Before (using real time)
/// final now = DateTime.now();
///
/// // After (using virtual time)
/// final now = clock.now;
/// ```
///
/// ## Testing Scenarios
///
/// ```dart
/// // Time travel
/// clock.timeTravelTo(DateTime(2026, 1, 1));
///
/// // Fast forward
/// clock.fastForward(Duration(days: 7));
///
/// // Pause for deterministic tests
/// clock.pause();
/// final frozenTime = clock.now;
/// await Future.delayed(Duration(seconds: 5));
/// assert(clock.now == frozenTime); // Time hasn't moved
/// clock.resume();
/// ```
ClockService get clock => VirtualClock.service;

/// Extension on DateTime for virtual clock utilities.
extension VirtualClockX on DateTime {
  /// Check if this DateTime is different from current virtual time.
  ///
  /// Returns true if this DateTime is not the current moment in virtual time.
  /// Allows 1 second tolerance for timing differences.
  ///
  /// Requires the global clock to be initialized.
  bool isDifferentFromVirtualNow([ClockService? clockService]) {
    final service = clockService ?? VirtualClock.service;
    final currentTime = service.now;
    return difference(currentTime).abs() > const Duration(seconds: 1);
  }

  /// Check if this DateTime is in the virtual past.
  ///
  /// Returns true if this DateTime is before the current virtual time.
  ///
  /// Requires the global clock to be initialized.
  bool isInVirtualPast([ClockService? clockService]) {
    final service = clockService ?? VirtualClock.service;
    return isBefore(service.now);
  }

  /// Check if this DateTime is in the virtual future.
  ///
  /// Returns true if this DateTime is after the current virtual time.
  ///
  /// Requires the global clock to be initialized.
  bool isInVirtualFuture([ClockService? clockService]) {
    final service = clockService ?? VirtualClock.service;
    return isAfter(service.now);
  }

  /// Check if this DateTime is today in virtual time.
  ///
  /// Returns true if this DateTime has the same year, month, and day as
  /// the current virtual time.
  ///
  /// Requires the global clock to be initialized.
  bool isVirtualToday([ClockService? clockService]) {
    final service = clockService ?? VirtualClock.service;
    final now = service.now;
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if this DateTime is yesterday in virtual time.
  ///
  /// Returns true if this DateTime has the same date as yesterday
  /// in virtual time.
  ///
  /// Requires the global clock to be initialized.
  bool isVirtualYesterday([ClockService? clockService]) {
    final service = clockService ?? VirtualClock.service;
    final yesterday = service.now.subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Get the difference between this DateTime and virtual now.
  ///
  /// Positive duration means this DateTime is in the virtual future.
  /// Negative duration means this DateTime is in the virtual past.
  ///
  /// Requires the global clock to be initialized.
  Duration differenceFromVirtualNow([ClockService? clockService]) {
    final service = clockService ?? VirtualClock.service;
    return difference(service.now);
  }
}
