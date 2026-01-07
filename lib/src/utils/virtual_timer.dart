import 'dart:async';

import 'package:virtual_clock/virtual_clock.dart';

/// Wrapper for Timer that respects virtual time acceleration.
///
/// When clock acceleration is active (clockRate > 1), this wrapper
/// automatically adjusts timer durations to match virtual time progression.
///
/// ## Usage
///
/// ```dart
/// // With clockRate=100
/// VirtualTimer.periodic(
///   clockService,
///   Duration(minutes: 1),
///   (timer) {
///     print('One virtual minute has passed!');
///   },
/// );
/// // This will fire every 0.6 real seconds (60 seconds / 100)
/// ```
///
/// In production mode (clockRate=1), this behaves exactly like Timer.periodic
/// with zero overhead.
///
/// ## With Global Clock
///
/// If you've set up the global clock accessor, you can use:
/// ```dart
/// VirtualTimer.periodicWithClock(Duration(minutes: 1), (timer) {
///   print('One virtual minute!');
/// });
/// ```
class VirtualTimer {
  VirtualTimer._();

  /// Create a periodic timer that respects virtual time acceleration.
  ///
  /// When clock acceleration is active, the duration is divided by the clock rate
  /// so the timer fires at the correct virtual intervals.
  ///
  /// Parameters:
  /// - [clockService]: The ClockService instance to use for time calculation
  /// - [duration]: The virtual duration between timer ticks
  /// - [callback]: Function called on each timer tick
  ///
  /// Returns a standard [Timer] that can be cancelled normally.
  ///
  /// Example:
  /// ```dart
  /// final timer = VirtualTimer.periodic(
  ///   clockService,
  ///   Duration(minutes: 1),
  ///   (timer) {
  ///     if (checkNewDay()) {
  ///       // New day detected in virtual time
  ///     }
  ///   },
  /// );
  ///
  /// // Later, cancel the timer
  /// timer.cancel();
  /// ```
  static Timer periodic(
    ClockService clockService,
    Duration duration,
    void Function(Timer) callback,
  ) {
    // In production mode, use regular timer (no overhead)
    if (clockService.isProduction) {
      return Timer.periodic(duration, callback);
    }

    // Calculate accelerated duration
    final acceleratedDuration = Duration(
      microseconds: (duration.inMicroseconds / clockService.clockRate).round(),
    );

    return Timer.periodic(acceleratedDuration, callback);
  }

  /// Create a periodic timer using the global clock accessor.
  ///
  /// This is a convenience method that uses [VirtualClock.service].
  /// Requires [VirtualClock.initialize] to have been called first.
  ///
  /// Example:
  /// ```dart
  /// final timer = VirtualTimer.periodicWithClock(
  ///   Duration(hours: 1),
  ///   (timer) => checkHourlyTasks(),
  /// );
  /// ```
  static Timer periodicWithClock(
    Duration duration,
    void Function(Timer) callback,
  ) {
    return periodic(VirtualClock.service, duration, callback);
  }

  /// Create a one-time timer that respects virtual time acceleration.
  ///
  /// Parameters:
  /// - [clockService]: The ClockService instance to use for time calculation
  /// - [duration]: The virtual duration before timer fires
  /// - [callback]: Function called when timer fires
  ///
  /// Returns a standard [Timer] that can be cancelled normally.
  ///
  /// Example:
  /// ```dart
  /// // Wait 1 virtual day
  /// VirtualTimer.delayed(
  ///   clockService,
  ///   Duration(days: 1),
  ///   () {
  ///     print('One virtual day has passed!');
  ///   },
  /// );
  /// // With clockRate=100, this fires after ~14.4 real minutes
  /// ```
  static Timer delayed(
    ClockService clockService,
    Duration duration,
    void Function() callback,
  ) {
    // In production mode, use regular timer
    if (clockService.isProduction) {
      return Timer(duration, callback);
    }

    // Calculate accelerated duration
    final acceleratedDuration = Duration(
      microseconds: (duration.inMicroseconds / clockService.clockRate).round(),
    );

    return Timer(acceleratedDuration, callback);
  }

  /// Create a one-time timer using the global clock accessor.
  ///
  /// This is a convenience method that uses [VirtualClock.service].
  /// Requires [VirtualClock.initialize] to have been called first.
  static Timer delayedWithClock(Duration duration, void Function() callback) {
    return delayed(VirtualClock.service, duration, callback);
  }

  /// Wait for a virtual duration to pass.
  ///
  /// This is the virtual time equivalent of `await Future.delayed()`.
  ///
  /// Parameters:
  /// - [clockService]: The ClockService instance to use
  /// - [duration]: The virtual duration to wait
  ///
  /// Returns a Future that completes after the virtual duration has elapsed.
  ///
  /// Example:
  /// ```dart
  /// // Wait 1 virtual hour
  /// await VirtualTimer.wait(clockService, Duration(hours: 1));
  /// // With clockRate=100, this waits 36 real seconds
  /// ```
  static Future<void> wait(ClockService clockService, Duration duration) {
    final completer = Completer<void>();
    delayed(clockService, duration, completer.complete);
    return completer.future;
  }

  /// Wait for a virtual duration using the global clock accessor.
  ///
  /// This is a convenience method that uses [VirtualClock.service].
  /// Requires [VirtualClock.initialize] to have been called first.
  static Future<void> waitWithClock(Duration duration) {
    return wait(VirtualClock.service, duration);
  }
}
