import 'package:virtual_clock/src/enums/http_action.dart';

/// Result of an HTTP request guard evaluation.
class HttpGuardResult {
  const HttpGuardResult._({
    required this.action,
    this.reason,
  });

  /// Creates an allowed result.
  factory HttpGuardResult.allow() =>
      const HttpGuardResult._(action: HttpAction.allow);

  /// Creates a blocked result with the given reason.
  factory HttpGuardResult.block(String reason) => HttpGuardResult._(
        action: HttpAction.block,
        reason: reason,
      );

  /// Creates a throttled result with the given reason.
  factory HttpGuardResult.throttle(String reason) => HttpGuardResult._(
        action: HttpAction.throttle,
        reason: reason,
      );

  /// The action taken by the guard.
  final HttpAction action;

  /// Reason for blocking (null if allowed).
  final String? reason;

  /// Whether the request is allowed to proceed.
  bool get allowed => action == HttpAction.allow;

  /// Whether the request was denied (blocked or throttled).
  bool get denied => !allowed;

  @override
  String toString() {
    if (allowed) {
      return 'HttpGuardResult(allowed)';
    }
    return 'HttpGuardResult($action, reason: $reason)';
  }
}
