import 'package:flutter/foundation.dart';

/// Callback type for clock events.
///
/// Parameters:
/// - [eventTime]: The virtual time when the event occurred.
typedef ClockEventCallback = void Function(DateTime eventTime);

/// Base class for all clock events.
///
/// Provides a subscription mechanism for time-based events in the virtual clock.
/// Each event tracks its last trigger time to prevent duplicate firings.
///
/// Example:
/// ```dart
/// final event = ClockEvent(
///   name: 'hourly',
///   shouldTrigger: (prev, curr) => prev.hour != curr.hour,
/// );
///
/// event.subscribe((time) => print('New hour: ${time.hour}'));
/// ```
abstract class ClockEvent {
  ClockEvent({required this.name});

  /// Name of the event for debugging and logging.
  final String name;

  /// Callbacks subscribed to this event.
  final List<ClockEventCallback> _callbacks = [];

  /// Last time this event was triggered (to prevent duplicate firings).
  DateTime? _lastTriggeredAt;

  /// Whether this event has any subscribers.
  bool get hasSubscribers => _callbacks.isNotEmpty;

  /// Number of subscribers.
  int get subscriberCount => _callbacks.length;

  /// Subscribe to this event.
  ///
  /// Returns a function that can be called to unsubscribe.
  ///
  /// Example:
  /// ```dart
  /// final unsubscribe = event.subscribe((time) => print('Event at $time'));
  /// // Later...
  /// unsubscribe(); // Stop receiving events
  /// ```
  void Function() subscribe(ClockEventCallback callback) {
    _callbacks.add(callback);
    return () => _callbacks.remove(callback);
  }

  /// Unsubscribe a specific callback.
  void unsubscribe(ClockEventCallback callback) {
    _callbacks.remove(callback);
  }

  /// Remove all subscribers.
  void clearSubscribers() {
    _callbacks.clear();
  }

  /// Check if this event should trigger based on the previous and current time.
  ///
  /// Subclasses must implement this to define their trigger condition.
  bool shouldTrigger(DateTime previousTime, DateTime currentTime);

  /// Check and potentially trigger the event.
  ///
  /// Called periodically by the ClockService to check if the event should fire.
  /// Returns true if the event was triggered.
  bool checkAndTrigger(DateTime currentTime) {
    if (_callbacks.isEmpty) return false;

    final previousTime = _lastTriggeredAt ?? currentTime;

    if (shouldTrigger(previousTime, currentTime)) {
      _lastTriggeredAt = currentTime;
      _notifySubscribers(currentTime);
      return true;
    }

    return false;
  }

  /// Initialize or reset the last triggered time.
  ///
  /// Should be called when the clock is initialized or reset.
  void initialize(DateTime currentTime) {
    _lastTriggeredAt = currentTime;
  }

  /// Notify all subscribers of the event.
  ///
  /// Errors in individual callbacks are caught and logged to prevent
  /// one failing callback from blocking others.
  void _notifySubscribers(DateTime eventTime) {
    for (final callback in List.of(_callbacks)) {
      try {
        callback(eventTime);
      } catch (e, stackTrace) {
        // Log error but continue notifying other subscribers
        debugPrint('[VirtualClock] Error in $name callback: $e\n$stackTrace');
      }
    }
  }
}
