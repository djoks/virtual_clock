import 'package:virtual_clock/src/enums/http_action.dart';
import 'package:virtual_clock/src/enums/log_level.dart';

/// Callback type for when an HTTP request is denied.
///
/// Parameters:
/// - [path]: The request path that was denied
/// - [reason]: The reason for denial
typedef HttpRequestDeniedCallback = void Function(String path, String reason);

/// Callback type for logging messages.
///
/// Parameters:
/// - [message]: The log message
/// - [level]: The severity level of the message
typedef LogCallback = void Function(String message, {LogLevel level});

/// Configuration for the ClockService.
///
/// Example:
/// ```dart
/// ClockConfig(
///   clockRate: 100,
///   isProduction: false,
///   appVersion: '1.0.0+1',
///   logCallback: (message, {level = LogLevel.info}) {
///     switch (level) {
///       case LogLevel.error:
///         log.e(message);
///       case LogLevel.warning:
///         log.w(message);
///       case LogLevel.info:
///         log.i(message);
///     }
///   },
/// )
/// ```
class ClockConfig {
  /// Creates a clock configuration.
  const ClockConfig({
    this.clockRate = 1,
    this.isProduction = false,
    this.forceEnable = false,
    this.appVersion,
    this.logCallback,
    this.httpPolicy = HttpAction.block,
    this.httpAllowedPatterns = const [],
    this.httpBlockedPatterns = const [],
    this.httpThrottleLimit = 10,
    this.onHttpRequestDenied,
  }) : assert(clockRate >= 0, 'Clock rate must be non-negative');

  /// Time multiplier (1 = normal, 100 = 100x faster).
  final int clockRate;

  /// Whether the app is running in production mode.
  final bool isProduction;

  /// Whether to force-enable the clock even in release/profile mode.
  ///
  /// By default, clockRate > 1 only works in debug mode.
  /// Set to true to explicitly enable in other modes (use with caution).
  final bool forceEnable;

  /// Current app version for auto-reset detection.
  final String? appVersion;

  /// Optional callback for logging messages.
  final LogCallback? logCallback;

  // HTTP Control Fields

  /// Default HTTP policy when clockRate > 1 (accelerated mode).
  /// In real-time mode (clockRate == 1), all requests are allowed.
  /// Defaults to [HttpAction.block] for safety.
  final HttpAction httpPolicy;

  /// Path patterns always allowed in accelerated mode.
  /// Supports glob patterns: '/status', '/auth/*', '*/health'
  ///
  /// **Precedence**: blockedPatterns > allowedPatterns > httpPolicy
  /// (blocked patterns take priority for safety)
  final List<String> httpAllowedPatterns;

  /// Path patterns always blocked in accelerated mode.
  /// Supports glob patterns. Takes precedence over [httpAllowedPatterns].
  final List<String> httpBlockedPatterns;

  /// Max requests per real minute when using [HttpAction.throttle].
  /// Uses real wall-clock time, not virtual time.
  final int httpThrottleLimit;

  /// Callback when HTTP request is denied (blocked or throttled).
  final HttpRequestDeniedCallback? onHttpRequestDenied;

  /// Creates a copy with the given fields replaced.
  ClockConfig copyWith({
    int? clockRate,
    bool? isProduction,
    bool? forceEnable,
    String? appVersion,
    LogCallback? logCallback,
    HttpAction? httpPolicy,
    List<String>? httpAllowedPatterns,
    List<String>? httpBlockedPatterns,
    int? httpThrottleLimit,
    HttpRequestDeniedCallback? onHttpRequestDenied,
  }) {
    return ClockConfig(
      clockRate: clockRate ?? this.clockRate,
      isProduction: isProduction ?? this.isProduction,
      forceEnable: forceEnable ?? this.forceEnable,
      appVersion: appVersion ?? this.appVersion,
      logCallback: logCallback ?? this.logCallback,
      httpPolicy: httpPolicy ?? this.httpPolicy,
      httpAllowedPatterns: httpAllowedPatterns ?? this.httpAllowedPatterns,
      httpBlockedPatterns: httpBlockedPatterns ?? this.httpBlockedPatterns,
      httpThrottleLimit: httpThrottleLimit ?? this.httpThrottleLimit,
      onHttpRequestDenied: onHttpRequestDenied ?? this.onHttpRequestDenied,
    );
  }
}
