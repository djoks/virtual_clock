/// Action for HTTP request handling in accelerated time mode.
///
/// Used both for configuring HTTP policy in [ClockConfig] and as the
/// result action in [HttpGuardResult].
///
/// These actions only apply when [ClockService.clockRate] > 1 (accelerated mode).
/// In real-time mode (clockRate == 1), all HTTP requests are always allowed.
enum HttpAction {
  /// Allow requests to proceed.
  ///
  /// When used as policy: allows all requests regardless of clock rate.
  /// When used as result: request was allowed.
  allow,

  /// Block requests.
  ///
  /// When used as policy: blocks all requests in accelerated mode (safest).
  /// When used as result: request was blocked due to policy.
  block,

  /// Throttle requests.
  ///
  /// When used as policy: limits requests to [ClockConfig.httpThrottleLimit]
  /// per real minute; excess requests are blocked.
  /// When used as result: request was blocked due to throttle limit exceeded.
  throttle,
}
