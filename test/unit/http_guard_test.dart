import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_clock/virtual_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    VirtualClock.reset();
  });

  group('HTTP Guard - Basic Behavior', () {
    test('allows all requests when clock rate is 1', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig());

      // Act
      final result = clockService.guardHttpRequest('/api/users');

      // Assert
      expect(result.allowed, true);
      expect(result.action, HttpAction.allow);
    });

    test('blocks requests by default when accelerated', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(const ClockConfig(clockRate: 100));

      // Act
      final result = clockService.guardHttpRequest('/api/users');

      // Assert
      expect(result.denied, true);
      expect(result.action, HttpAction.block);
      expect(result.reason, contains('Accelerated mode active'));
    });
  });

  group('HTTP Guard - Policy Allow', () {
    test('allows all requests when policy is allow', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(
        const ClockConfig(
          clockRate: 100,
          httpPolicy: HttpAction.allow,
        ),
      );

      // Act
      final result = clockService.guardHttpRequest('/api/users');

      // Assert
      expect(result.allowed, true);
    });
  });

  group('HTTP Guard - Throttle Policy', () {
    test('allows requests within throttle limit', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(
        const ClockConfig(
          clockRate: 100,
          httpPolicy: HttpAction.throttle,
          httpThrottleLimit: 5,
        ),
      );

      // Act & Assert
      for (var i = 0; i < 5; i++) {
        final result = clockService.guardHttpRequest('/api/test');
        expect(result.allowed, true);
      }
    });

    test('blocks requests after throttle limit exceeded', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(
        const ClockConfig(
          clockRate: 100,
          httpPolicy: HttpAction.throttle,
          httpThrottleLimit: 3,
        ),
      );

      // Use up the limit
      for (var i = 0; i < 3; i++) {
        clockService.guardHttpRequest('/api/test');
      }

      // Act
      final result = clockService.guardHttpRequest('/api/test');

      // Assert
      expect(result.denied, true);
      expect(result.action, HttpAction.throttle);
      expect(result.reason, contains('Throttle limit'));
    });

    test('resetHttpThrottle clears throttle counter', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(
        const ClockConfig(
          clockRate: 100,
          httpPolicy: HttpAction.throttle,
          httpThrottleLimit: 2,
        ),
      );

      // Use up the limit
      clockService.guardHttpRequest('/api/test');
      clockService.guardHttpRequest('/api/test');
      expect(clockService.guardHttpRequest('/api/test').denied, true);

      // Act
      clockService.resetHttpThrottle();

      // Assert
      expect(clockService.guardHttpRequest('/api/test').allowed, true);
    });
  });

  group('HTTP Guard - Pattern Matching', () {
    test('allowedPatterns override default block policy', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(
        const ClockConfig(
          clockRate: 100,
          httpAllowedPatterns: ['/health', '/status'],
        ),
      );

      // Act & Assert
      expect(clockService.guardHttpRequest('/health').allowed, true);
      expect(clockService.guardHttpRequest('/status').allowed, true);
      expect(clockService.guardHttpRequest('/api/users').denied, true);
    });

    test('blockedPatterns override allowedPatterns', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(
        const ClockConfig(
          clockRate: 100,
          httpPolicy: HttpAction.allow,
          httpAllowedPatterns: ['/api/*'],
          httpBlockedPatterns: ['/api/admin*'],
        ),
      );

      // Act & Assert
      expect(clockService.guardHttpRequest('/api/users').allowed, true);
      expect(clockService.guardHttpRequest('/api/admin').denied, true);
      expect(clockService.guardHttpRequest('/api/admin/delete').denied, true);
    });

    test('glob patterns with * work correctly', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(
        const ClockConfig(
          clockRate: 100,
          httpAllowedPatterns: ['/api/*'],
        ),
      );

      // Act & Assert
      expect(clockService.guardHttpRequest('/api/users').allowed, true);
      expect(clockService.guardHttpRequest('/api/posts/123').allowed, true);
      expect(clockService.guardHttpRequest('/other/path').denied, true);
    });

    test('handles special regex characters in patterns', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(
        const ClockConfig(
          clockRate: 100,
          httpAllowedPatterns: ['/api/v1.2/test'],
        ),
      );

      // Act & Assert
      expect(clockService.guardHttpRequest('/api/v1.2/test').allowed, true);
      expect(clockService.guardHttpRequest('/api/v1X2/test').denied, true);
    });
  });

  group('HTTP Guard - Callbacks', () {
    test('onHttpRequestDenied callback fires on block', () async {
      // Arrange
      String? capturedPath;
      String? capturedReason;

      final clockService = ClockService();
      await clockService.initialize(
        ClockConfig(
          clockRate: 100,
          onHttpRequestDenied: (path, reason) {
            capturedPath = path;
            capturedReason = reason;
          },
        ),
      );

      // Act
      clockService.guardHttpRequest('/api/users');

      // Assert
      expect(capturedPath, '/api/users');
      expect(capturedReason, contains('Accelerated mode active'));
    });

    test('onHttpRequestDenied callback fires on throttle', () async {
      // Arrange
      String? capturedReason;

      final clockService = ClockService();
      await clockService.initialize(
        ClockConfig(
          clockRate: 100,
          httpPolicy: HttpAction.throttle,
          httpThrottleLimit: 1,
          onHttpRequestDenied: (path, reason) {
            capturedReason = reason;
          },
        ),
      );

      // Use up the limit
      clockService.guardHttpRequest('/api/test');

      // Act
      clockService.guardHttpRequest('/api/test');

      // Assert
      expect(capturedReason, contains('Throttle limit'));
    });
  });

  group('HTTP Guard - Convenience Method', () {
    test('isHttpRequestAllowed returns correct boolean', () async {
      // Arrange
      final clockService = ClockService();
      await clockService.initialize(
        const ClockConfig(
          clockRate: 100,
          httpAllowedPatterns: ['/health'],
        ),
      );

      // Act & Assert
      expect(clockService.isHttpRequestAllowed('/health'), true);
      expect(clockService.isHttpRequestAllowed('/api/users'), false);
    });
  });
}
