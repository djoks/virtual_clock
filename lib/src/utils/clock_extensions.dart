import 'package:virtual_clock/src/services/clock_service.dart';

/// Global accessor for the ClockService instance.
///
/// Provides a convenient way to access virtual time from anywhere in your app.
///
/// ## Setup
///
/// Initialize once during app startup:
/// ```dart
/// ```dart
/// await VirtualClock.initialize(
///   const ClockConfig(clockRate: 100),
/// );
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

  /// Initialize the global clock with configuration.
  ///
  /// This should be called once during app startup.
  ///
  /// Example:
  /// ```dart
  /// await VirtualClock.setup(
  ///   const ClockConfig(clockRate: 100),
  /// );
  /// ```
  static Future<void> setup(ClockConfig config) async {
    _service ??= ClockService();
    await _service!.initialize(config);
  }

  /// Get the global ClockService instance.
  ///
  /// Returns the singleton instance.
  /// Throws [StateError] if [setup] hasn't been called.
  static ClockService get service {
    if (_service == null) {
      throw StateError(
        'VirtualClock not initialized. Call VirtualClock.setup() first.',
      );
    }
    return _service!;
  }

  /// Check if the global clock has been initialized.
  static bool get isInitialized => _service != null && _service!.isInitialized;

  /// Reset the global clock.
  ///
  /// Disposes the current service and clears the instance.
  /// Useful for testing to ensure a clean state.
  static Future<void> reset() async {
    if (_service != null) {
      _service!.dispose();
      // Also clear persisted state if needed, or rely on ClockService.clearAllState() if we want deep clean?
      // For now, dispose stops timers.
      _service = null;
    }
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
/// await VirtualClock.initialize(
///   const ClockConfig(clockRate: 100),
/// );
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
  bool isDifferentFromVirtualNow() {
    final service = VirtualClock.service;
    final currentTime = service.now;
    return difference(currentTime).abs() > const Duration(seconds: 1);
  }

  /// Check if this DateTime is in the virtual past.
  ///
  /// Returns true if this DateTime is before the current virtual time.
  ///
  /// Requires the global clock to be initialized.
  bool isInVirtualPast() {
    final service = VirtualClock.service;
    return isBefore(service.now);
  }

  /// Check if this DateTime is in the virtual future.
  ///
  /// Returns true if this DateTime is after the current virtual time.
  ///
  /// Requires the global clock to be initialized.
  bool isInVirtualFuture() {
    final service = VirtualClock.service;
    return isAfter(service.now);
  }

  /// Check if this DateTime is today in virtual time.
  ///
  /// Returns true if this DateTime has the same year, month, and day as
  /// the current virtual time.
  ///
  /// Requires the global clock to be initialized.
  bool isVirtualToday() {
    final service = VirtualClock.service;
    final now = service.now;
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if this DateTime is yesterday in virtual time.
  ///
  /// Returns true if this DateTime has the same date as yesterday
  /// in virtual time.
  ///
  /// Requires the global clock to be initialized.
  bool isVirtualYesterday() {
    final service = VirtualClock.service;
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
  Duration differenceFromVirtualNow() {
    final service = VirtualClock.service;
    return difference(service.now);
  }
}
