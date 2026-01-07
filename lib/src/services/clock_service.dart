import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:virtual_clock/src/enums/clock_state.dart';
import 'package:virtual_clock/src/enums/http_action.dart';
import 'package:virtual_clock/src/enums/log_level.dart';
import 'package:virtual_clock/src/events/events.dart';
import 'package:virtual_clock/src/models/clock_config.dart';
import 'package:virtual_clock/src/models/http_guard_result.dart';

// Re-export for convenience
export 'package:virtual_clock/src/models/clock_config.dart';

/// Service that provides virtual time acceleration for testing time-based features.
///
/// Allows specifying a clock rate multiplier that accelerates time:
/// - clockRate=1 (default): Normal time
/// - clockRate=100: 1 real minute = 100 virtual minutes (1.67 hours)
/// - clockRate=1000: 1 real minute = 1000 virtual minutes (16.67 hours)
///
/// Features:
/// - Virtual time persistence across app restarts
/// - Auto-reset on version changes
/// - Production safety (forced to 1 in release builds)
/// - Testing utilities: pause(), resume(), timeTravelTo(), fastForward()
///
/// ## Basic Usage
///
/// ```dart
/// // Initialize (typically in app startup)
/// final clockService = ClockService();
/// await clockService.initialize(ClockConfig(clockRate: 100));
///
/// // Get current virtual time
/// final now = clockService.now;
///
/// // Time travel for testing
/// clockService.timeTravelTo(DateTime(2026, 1, 1));
///
/// // Fast forward 7 days
/// clockService.fastForward(Duration(days: 7));
///
/// // Pause time for deterministic tests
/// clockService.pause();
/// ```
///
/// ## With Global Accessor
///
/// ```dart
/// // Set up global accessor (once during app init)
/// VirtualClock.initialize(clockService);
///
/// // Use anywhere via global accessor
/// final now = clock.now;
/// clock.fastForward(Duration(days: 1));
/// ```
class ClockService extends ChangeNotifier {
  // Configuration
  int _clockRate = 1;
  late DateTime? _baseRealTime;
  DateTime? _baseVirtualTime;
  ClockState _state = ClockState.running;
  DateTime? _pausedAt;
  Duration _pausedOffset = Duration.zero;
  String? _appVersion;
  LogCallback? _logCallback;
  bool _isInitialized = false;

  // Event system
  Timer? _eventTimer;
  DateTime? _lastEventCheckTime;

  // HTTP control (queue for O(1) cleanup)
  final Queue<DateTime> _httpRequestTimestamps = Queue<DateTime>();
  HttpAction _httpPolicy = HttpAction.block;
  List<String> _httpAllowedPatterns = const [];
  List<String> _httpBlockedPatterns = const [];
  int _httpThrottleLimit = 10;
  HttpRequestDeniedCallback? _onHttpRequestDenied;

  // Cached regex patterns ((pattern -> compiled regex) to avoid recompilation
  final Map<String, RegExp> _compiledPatterns = {};

  // Clock events - exposed for subscription
  final NewHourEvent _onNewHour = NewHourEvent();
  final AtNoonEvent _atNoon = AtNoonEvent();
  final NewDayEvent _onNewDay = NewDayEvent();
  final WeekStartEvent _onWeekStart = WeekStartEvent();
  final WeekEndEvent _onWeekEnd = WeekEndEvent();

  /// Event fired at the start of each new hour.
  ///
  /// Example:
  /// ```dart
  /// clock.onNewHour.subscribe((time) {
  ///   print('New hour: ${time.hour}:00');
  /// });
  /// ```
  NewHourEvent get onNewHour => _onNewHour;

  /// Event fired at noon (12:00 PM) each day.
  ///
  /// Example:
  /// ```dart
  /// clock.atNoon.subscribe((time) {
  ///   print('It is noon!');
  /// });
  /// ```
  AtNoonEvent get atNoon => _atNoon;

  /// Event fired at the start of each new day (midnight).
  ///
  /// Example:
  /// ```dart
  /// clock.onNewDay.subscribe((time) {
  ///   print('New day: ${time.day}/${time.month}');
  ///   resetDailyBonuses();
  /// });
  /// ```
  NewDayEvent get onNewDay => _onNewDay;

  /// Event fired at the start of each new week (Monday).
  ///
  /// Example:
  /// ```dart
  /// clock.onWeekStart.subscribe((time) {
  ///   resetWeeklyChallenge();
  /// });
  /// ```
  WeekStartEvent get onWeekStart => _onWeekStart;

  /// Event fired at the end of each week (Sunday to Monday transition).
  ///
  /// Example:
  /// ```dart
  /// clock.onWeekEnd.subscribe((time) {
  ///   calculateWeeklyStats();
  /// });
  /// ```
  WeekEndEvent get onWeekEnd => _onWeekEnd;

  // SharedPreferences keys
  static const String _keyVirtualTimeBase = 'virtual_clock_base_timestamp';
  static const String _keyAppVersion = 'virtual_clock_app_version';

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Whether the clock is running in production mode (no acceleration).
  bool get isProduction => _clockRate == 1 && _baseVirtualTime == null;

  /// Current clock rate multiplier.
  int get clockRate => _clockRate;

  /// Current state of the clock.
  ClockState get state => _state;

  /// Whether time is currently paused.
  bool get isPaused => _state == ClockState.paused;

  /// Last time events were checked for triggers.
  ///
  /// Useful for debugging the event system.
  DateTime? get lastEventCheckTime => _lastEventCheckTime;

  /// Get current virtual time.
  ///
  /// In production mode, returns real time.
  /// In development mode with acceleration, returns accelerated virtual time.
  DateTime get now {
    if (_state == ClockState.paused && _pausedAt != null) {
      return _calculateVirtualTime(_pausedAt!);
    }
    return _calculateVirtualTime(DateTime.now());
  }

  /// Calculate virtual time based on real time and clock rate.
  DateTime _calculateVirtualTime(DateTime realNow) {
    if (isProduction) return realNow;

    final realElapsed = realNow.difference(_baseRealTime!);
    final effectiveElapsed = realElapsed - _pausedOffset;
    final virtualElapsed = Duration(
      microseconds: (effectiveElapsed.inMicroseconds * _clockRate).round(),
    );

    return _baseVirtualTime!.add(virtualElapsed);
  }

  void _log(String message, {LogLevel level = LogLevel.info}) {
    if (_logCallback != null) {
      _logCallback!(message, level: level);
    } else if (kDebugMode) {
      debugPrint('[VirtualClock] $message');
    }
  }

  /// Initialize ClockService with configuration.
  ///
  /// This method should be called once during app startup.
  ///
  /// The [config] parameter controls the clock behavior:
  /// - [ClockConfig.clockRate]: Time multiplier (default: 1)
  /// - [ClockConfig.isProduction]: Force production mode (default: false)
  /// - [ClockConfig.appVersion]: App version for auto-reset detection
  /// - [ClockConfig.logCallback]: Custom logging callback
  ///
  /// Example:
  /// ```dart
  /// await clockService.initialize(ClockConfig(
  ///   clockRate: 100,
  ///   appVersion: '1.0.0+1',
  /// ));
  /// ```
  Future<void> initialize(ClockConfig config) async {
    var clockRate = config.clockRate;
    _logCallback = config.logCallback;
    _appVersion = config.appVersion;

    if (clockRate < 0) {
      _log(
        'Negative clock rate ($clockRate) not supported. Resetting to 1.',
        level: LogLevel.error,
      );
      clockRate = 1;
    }

    // Default: Only run accelerated clock in debug mode unless explicitly forced
    if (!kDebugMode && !config.forceEnable && clockRate != 1) {
      _log(
        'Virtual clock only runs in debug mode. Set forceEnable=true to override.',
        level: LogLevel.warning,
      );
      clockRate = 1;
    }

    // CRITICAL: Force 1 in release builds (unless explicitly forced)
    if (kReleaseMode && !config.forceEnable) {
      if (clockRate != 1) {
        _log(
          'CLOCK_RATE ignored in release mode (forced to 1)',
          level: LogLevel.warning,
        );
      }
      clockRate = 1;
    }

    // CRITICAL: Force 1 if explicitly set as production
    if (config.isProduction) {
      if (clockRate != 1) {
        _log(
          'CLOCK_RATE must be 1 in production environment',
          level: LogLevel.error,
        );
        throw Exception('Clock acceleration not allowed in production');
      }
      clockRate = 1;
    }

    _clockRate = clockRate;

    if (_clockRate != 1) {
      final shouldReset = await _shouldResetVirtualTime();

      if (shouldReset) {
        _log('Resetting virtual time (version change or first run)');
        await _clearPersistedVirtualTime();
        _baseVirtualTime = DateTime.now();
      } else {
        _baseVirtualTime = await _loadPersistedVirtualTime() ?? DateTime.now();
      }

      _baseRealTime = DateTime.now();

      await _persistVirtualTime(_baseVirtualTime!);
      await _persistAppVersion();

      _log(
        '╔════════════════════════════════════════╗',
        level: LogLevel.warning,
      );
      _log(
        '║  CLOCK ACCELERATION ACTIVE: ${_clockRate}x'.padRight(40),
        level: LogLevel.warning,
      );
      _log(
        '║  Virtual time is accelerated!          ║',
        level: LogLevel.warning,
      );
      _log(
        '║  NOT FOR PRODUCTION USE                ║',
        level: LogLevel.warning,
      );
      _log(
        '╚════════════════════════════════════════╝',
        level: LogLevel.warning,
      );
    }

    // Initialize HTTP control settings
    _httpPolicy = config.httpPolicy;
    _httpAllowedPatterns = config.httpAllowedPatterns;
    _httpBlockedPatterns = config.httpBlockedPatterns;
    _httpThrottleLimit = config.httpThrottleLimit;
    _onHttpRequestDenied = config.onHttpRequestDenied;

    // Initialize event system
    _initializeEvents();
    _startEventTimer();

    _isInitialized = true;
    notifyListeners();
  }

  /// Check if virtual time should be reset.
  Future<bool> _shouldResetVirtualTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastAppVersion = prefs.getString(_keyAppVersion);
    if (lastAppVersion == null) return true;
    if (_appVersion == null) return false;
    return lastAppVersion != _appVersion;
  }

  /// Load persisted virtual time base.
  Future<DateTime?> _loadPersistedVirtualTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_keyVirtualTimeBase);
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Persist virtual time base.
  Future<void> _persistVirtualTime(DateTime virtualTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyVirtualTimeBase, virtualTime.millisecondsSinceEpoch);
  }

  /// Clear persisted virtual time.
  Future<void> _clearPersistedVirtualTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyVirtualTimeBase);
  }

  /// Persist current app version.
  Future<void> _persistAppVersion() async {
    if (_appVersion == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppVersion, _appVersion!);
  }

  // Testing API

  /// Jump to specific date/time.
  ///
  /// Useful for testing features at specific dates.
  ///
  /// Example:
  /// ```dart
  /// clock.timeTravelTo(DateTime(2026, 12, 25)); // Jump to Christmas 2026
  /// ```
  void timeTravelTo(DateTime targetTime) {
    _baseRealTime = DateTime.now();
    _baseVirtualTime = targetTime;
    _pausedOffset = Duration.zero;
    _persistVirtualTime(targetTime);
    triggerEventCheck(); // Check events immediately after time travel
    notifyListeners();
  }

  /// Fast-forward by duration.
  ///
  /// Advances virtual time by the specified duration.
  ///
  /// Example:
  /// ```dart
  /// clock.fastForward(Duration(days: 7)); // Skip ahead one week
  /// ```
  void fastForward(Duration duration) {
    final current = now;
    final targetTime = current.add(duration);
    _baseRealTime = DateTime.now();
    _baseVirtualTime = targetTime;
    _pausedOffset = Duration.zero;
    _persistVirtualTime(targetTime);
    triggerEventCheck(); // Check events immediately after fast forward
    notifyListeners();
  }

  /// Pause time (for deterministic tests).
  ///
  /// Freezes virtual time at the current moment.
  /// Useful for tests that need predictable timestamps.
  ///
  /// Example:
  /// ```dart
  /// clock.pause();
  /// // Perform tests with frozen time
  /// clock.resume();
  /// ```
  void pause() {
    if (_state != ClockState.paused) {
      _state = ClockState.paused;
      _pausedAt = DateTime.now();
      notifyListeners();
    }
  }

  /// Resume time after pause.
  ///
  /// Unfreezes time and continues virtual time progression.
  void resume() {
    if (_state == ClockState.paused && _pausedAt != null) {
      _pausedOffset += DateTime.now().difference(_pausedAt!);
      _state = ClockState.running;
      _pausedAt = null;
      notifyListeners();
    }
  }

  /// Reset virtual time back to real time while preserving the clock rate.
  ///
  /// Syncs virtual time to the current real time but maintains the configured
  /// clock rate for continued testing with accelerated time.
  ///
  /// Example:
  /// ```dart
  /// clock.reset(); // Back to real time, rate preserved
  /// ```
  Future<void> reset() async {
    _baseRealTime = DateTime.now();
    _baseVirtualTime = DateTime.now();
    _state = ClockState.running;
    _pausedAt = null;
    _pausedOffset = Duration.zero;
    await _persistVirtualTime(_baseVirtualTime!);

    // Reinitialize events to prevent immediate triggers after reset
    _initializeEvents();

    notifyListeners();
  }

  /// Set the clock rate dynamically.
  ///
  /// Changes the speed of time progression.
  /// Seamlessly transitions current virtual time to the new rate.
  ///
  /// [newRate] must be non-negative. Values > 100,000 are clamped.
  void setClockRate(int newRate) {
    if (isProduction) {
      _log(
        'Cannot change clock rate in production mode',
        level: LogLevel.error,
      );
      return;
    }

    // Validation
    var effectiveRate = newRate;
    if (effectiveRate < 0) {
      _log(
        'Negative clock rate ($effectiveRate) not supported. Clamping to 0.',
        level: LogLevel.warning,
      );
      effectiveRate = 0;
    } else if (effectiveRate > 100000) {
      _log(
        'Clock rate ($effectiveRate) too high. Clamping to 100,000.',
        level: LogLevel.warning,
      );
      effectiveRate = 100000;
    }

    if (_clockRate == effectiveRate) return;

    // Capture current state before changing rate
    final currentVirtual = now;
    final nowTime = DateTime.now();

    // Re-anchor time calculation
    _baseRealTime = nowTime;
    _baseVirtualTime = currentVirtual;
    _pausedOffset = Duration.zero;

    // Update pause state if needed
    if (_state == ClockState.paused) {
      _pausedAt = nowTime;
    }

    _clockRate = effectiveRate;
    _log('Clock rate changed to $_clockRate');

    // Update timer
    _startEventTimer();
    notifyListeners();
  }

  /// Increase clock rate by a multiplier.
  ///
  /// [multiplier] defaults to 2.0 (double the speed).
  void increaseClockRate({double multiplier = 2.0}) {
    setClockRate((_clockRate * multiplier).round());
  }

  /// Decrease clock rate by a multiplier.
  ///
  /// [multiplier] defaults to 0.5 (half the speed).
  void decreaseClockRate({double multiplier = 0.5}) {
    setClockRate((_clockRate * multiplier).round());
  }

  /// Clear all persisted state.
  ///
  /// Removes virtual time and version data from storage.
  /// Useful for testing or when completely resetting the clock.
  Future<void> clearAllState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyVirtualTimeBase);
    await prefs.remove(_keyAppVersion);
  }

  // Event System Methods

  /// Get all registered events for iteration.
  List<ClockEvent> get _allEvents => [
        _onNewHour,
        _atNoon,
        _onNewDay,
        _onWeekStart,
        _onWeekEnd,
      ];

  /// Initialize all events with the current virtual time.
  void _initializeEvents() {
    final currentTime = now;
    _lastEventCheckTime = currentTime;
    for (final event in _allEvents) {
      event.initialize(currentTime);
    }
  }

  /// Start the event timer that periodically checks for triggered events.
  void _startEventTimer() {
    _stopEventTimer();

    // Calculate check interval based on clock rate
    // At higher rates, check more frequently since time passes faster
    final checkIntervalMs =
        _clockRate > 1 ? (1000 ~/ _clockRate).clamp(50, 1000) : 1000;

    _eventTimer = Timer.periodic(
      Duration(milliseconds: checkIntervalMs),
      (_) => _checkEvents(),
    );
  }

  /// Stop the event timer.
  void _stopEventTimer() {
    _eventTimer?.cancel();
    _eventTimer = null;
  }

  /// Check all events and trigger those that should fire.
  void _checkEvents() {
    if (_state == ClockState.paused) return;

    final currentTime = now;

    for (final event in _allEvents) {
      if (event.hasSubscribers) {
        event.checkAndTrigger(currentTime);
      }
    }

    _lastEventCheckTime = currentTime;
  }

  /// Manually trigger an event check.
  ///
  /// Useful after time travel or fast forward operations.
  void triggerEventCheck() {
    _checkEvents();
  }

  // HTTP Control Methods

  /// Evaluate if an HTTP request to [path] should be allowed.
  ///
  /// Returns [HttpGuardResult] with action and reason.
  /// Use this before making HTTP requests when clockRate > 1.
  ///
  /// In real-time mode (clockRate == 1), always returns allowed.
  ///
  /// **Precedence**: blockedPatterns > allowedPatterns > httpPolicy
  ///
  /// Example:
  /// ```dart
  /// final result = clock.guardHttpRequest('/api/users');
  /// if (result.denied) {
  ///   log.w('Request denied: ${result.reason}');
  ///   return cachedData;
  /// }
  /// // Proceed with HTTP request...
  /// ```
  HttpGuardResult guardHttpRequest(String path) {
    // Real-time mode (rate=1): always allow
    if (clockRate == 1) {
      return HttpGuardResult.allow();
    }

    // Determine policy for this path
    final policy = _getPolicyForPath(path);

    switch (policy) {
      case HttpAction.allow:
        return HttpGuardResult.allow();

      case HttpAction.block:
        final reason = 'Accelerated mode active (rate=${clockRate}x)';
        _onHttpRequestDenied?.call(path, reason);
        return HttpGuardResult.block(reason);

      case HttpAction.throttle:
        _cleanOldHttpTimestamps();
        if (_httpRequestTimestamps.length < _httpThrottleLimit) {
          _httpRequestTimestamps.add(DateTime.now());
          return HttpGuardResult.allow();
        }
        final reason = 'Throttle limit ($_httpThrottleLimit/min) exceeded';
        _onHttpRequestDenied?.call(path, reason);
        return HttpGuardResult.throttle(reason);
    }
  }

  /// Quick check if request would be allowed (convenience method).
  bool isHttpRequestAllowed(String path) {
    return guardHttpRequest(path).allowed;
  }

  /// Policy precedence: blockedPatterns > allowedPatterns > httpPolicy
  HttpAction _getPolicyForPath(String path) {
    // Blocked patterns take priority (safer default)
    if (_matchesPattern(path, _httpBlockedPatterns)) return HttpAction.block;
    if (_matchesPattern(path, _httpAllowedPatterns)) return HttpAction.allow;
    return _httpPolicy;
  }

  bool _matchesPattern(String path, List<String> patterns) {
    for (final pattern in patterns) {
      if (_globMatch(path, pattern)) return true;
    }
    return false;
  }

  /// Match path against glob pattern using cached compiled regex.
  ///
  /// Caches compiled regex patterns to avoid recompilation overhead on
  /// every HTTP guard check.
  bool _globMatch(String path, String pattern) {
    // Return cached regex if available
    var regex = _compiledPatterns[pattern];
    if (regex == null) {
      // Escape all regex meta characters except * and ?
      final escaped = pattern.replaceAllMapped(
        RegExp(r'[.+^${}()|\[\]\\]'),
        (m) => '\\${m.group(0)}',
      );
      // Convert glob wildcards to regex
      final regexPattern = escaped.replaceAll('*', '.*').replaceAll('?', '.');
      regex = RegExp('^$regexPattern\$');
      _compiledPatterns[pattern] = regex;
    }
    return regex.hasMatch(path);
  }

  /// Remove timestamps older than 1 real minute (uses wall clock).
  void _cleanOldHttpTimestamps() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 1));
    while (_httpRequestTimestamps.isNotEmpty &&
        _httpRequestTimestamps.first.isBefore(cutoff)) {
      _httpRequestTimestamps.removeFirst();
    }
  }

  /// Reset HTTP throttle counter (useful for testing).
  void resetHttpThrottle() => _httpRequestTimestamps.clear();

  /// Dispose of resources.
  ///
  /// Should be called when the ClockService is no longer needed.
  @override
  void dispose() {
    _stopEventTimer();
    for (final event in _allEvents) {
      event.clearSubscribers();
    }
    super.dispose();
  }
}
