import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_clock/virtual_clock.dart';

void main() {
  group('ClockConfig', () {
    test('has correct defaults', () {
      // Arrange & Act
      const config = ClockConfig();

      // Assert
      expect(config.clockRate, 1);
      expect(config.isProduction, false);
      expect(config.forceEnable, false);
      expect(config.appVersion, null);
      expect(config.logCallback, null);
      expect(config.httpPolicy, HttpAction.block);
      expect(config.httpAllowedPatterns, isEmpty);
      expect(config.httpBlockedPatterns, isEmpty);
      expect(config.httpThrottleLimit, 10);
      expect(config.onHttpRequestDenied, null);
    });

    test('accepts custom clock rate', () {
      // Arrange & Act
      const config = ClockConfig(clockRate: 100);

      // Assert
      expect(config.clockRate, 100);
    });

    test('accepts production mode flag', () {
      // Arrange & Act
      const config = ClockConfig(isProduction: true);

      // Assert
      expect(config.isProduction, true);
    });

    test('accepts forceEnable flag', () {
      // Arrange & Act
      const config = ClockConfig(forceEnable: true);

      // Assert
      expect(config.forceEnable, true);
    });

    test('accepts app version', () {
      // Arrange & Act
      const config = ClockConfig(appVersion: '1.0.0');

      // Assert
      expect(config.appVersion, '1.0.0');
    });

    test('accepts log callback', () {
      // Arrange
      void logFn(String msg, {LogLevel level = LogLevel.info}) {}

      // Act
      final config = ClockConfig(logCallback: logFn);

      // Assert
      expect(config.logCallback, logFn);
    });

    test('accepts HTTP policy', () {
      // Arrange & Act
      const config = ClockConfig(httpPolicy: HttpAction.allow);

      // Assert
      expect(config.httpPolicy, HttpAction.allow);
    });

    test('accepts HTTP allowed patterns', () {
      // Arrange & Act
      const config = ClockConfig(httpAllowedPatterns: ['/api/*', '/health']);

      // Assert
      expect(config.httpAllowedPatterns, ['/api/*', '/health']);
    });

    test('accepts HTTP blocked patterns', () {
      // Arrange & Act
      const config = ClockConfig(httpBlockedPatterns: ['/admin/*']);

      // Assert
      expect(config.httpBlockedPatterns, ['/admin/*']);
    });

    test('accepts HTTP throttle limit', () {
      // Arrange & Act
      const config = ClockConfig(httpThrottleLimit: 50);

      // Assert
      expect(config.httpThrottleLimit, 50);
    });
  });

  group('ClockConfig copyWith', () {
    test('preserves all values when no changes', () {
      // Arrange
      const original = ClockConfig(
        clockRate: 100,
        isProduction: true,
        forceEnable: true,
        appVersion: '1.0.0',
        httpPolicy: HttpAction.throttle,
        httpThrottleLimit: 50,
      );

      // Act
      final copy = original.copyWith();

      // Assert
      expect(copy.clockRate, 100);
      expect(copy.isProduction, true);
      expect(copy.forceEnable, true);
      expect(copy.appVersion, '1.0.0');
      expect(copy.httpPolicy, HttpAction.throttle);
      expect(copy.httpThrottleLimit, 50);
    });

    test('updates specified values only', () {
      // Arrange
      const original = ClockConfig(clockRate: 100);

      // Act
      final copy = original.copyWith(clockRate: 200, isProduction: true);

      // Assert
      expect(copy.clockRate, 200);
      expect(copy.isProduction, true);
      expect(copy.forceEnable, false);
    });
  });

  group('ClockConfig assertion', () {
    test('asserts clock rate is non-negative', () {
      // Assert
      expect(
        () => ClockConfig(clockRate: -1),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
