import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_clock/virtual_clock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('TimeControlTheme', () {
    test('dark preset uses correct colors', () {
      // Assert
      expect(TimeControlTheme.dark.backgroundColor, kDarkBackground);
      expect(TimeControlTheme.dark.accentColor, kDarkAccent);
      expect(TimeControlTheme.dark.textPrimary, kDarkTextPrimary);
      expect(TimeControlTheme.dark.textSecondary, kDarkTextSecondary);
      expect(TimeControlTheme.dark.borderColor, kDarkBorder);
    });

    test('light preset uses correct colors', () {
      // Assert
      expect(TimeControlTheme.light.backgroundColor, kLightBackground);
      expect(TimeControlTheme.light.accentColor, kLightAccent);
      expect(TimeControlTheme.light.textPrimary, kLightTextPrimary);
      expect(TimeControlTheme.light.textSecondary, kLightTextSecondary);
      expect(TimeControlTheme.light.borderColor, kLightBorder);
    });

    test('resolve with dark brightness returns dark colors', () {
      // Arrange
      const userTheme = TimeControlTheme();

      // Act
      final resolved = userTheme.resolve(Brightness.dark);

      // Assert
      expect(resolved.backgroundColor, kDarkBackground);
      expect(resolved.accentColor, kDarkAccent);
    });

    test('resolve with light brightness returns light colors', () {
      // Arrange
      const userTheme = TimeControlTheme();

      // Act
      final resolved = userTheme.resolve(Brightness.light);

      // Assert
      expect(resolved.backgroundColor, kLightBackground);
      expect(resolved.accentColor, kLightAccent);
    });

    test('resolve merges user overrides with base theme', () {
      // Arrange
      const customAccent = Colors.purple;
      const userTheme = TimeControlTheme(accentColor: customAccent);

      // Act
      final resolved = userTheme.resolve(Brightness.dark);

      // Assert - User override used
      expect(resolved.accentColor, customAccent);
      // Base theme fills in rest
      expect(resolved.backgroundColor, kDarkBackground);
    });

    test('copyWith creates new theme with updated values', () {
      // Arrange
      const original = TimeControlTheme(
        backgroundColor: Colors.red,
        accentColor: Colors.blue,
      );

      // Act
      final copy = original.copyWith(accentColor: Colors.green);

      // Assert
      expect(copy.backgroundColor, Colors.red);
      expect(copy.accentColor, Colors.green);
    });

    test('has correct default font family', () {
      // Assert
      expect(TimeControlTheme.dark.timeFontFamily, kDefaultTimeFontFamily);
      expect(TimeControlTheme.light.timeFontFamily, kDefaultTimeFontFamily);
    });

    test('has correct default radius', () {
      // Assert
      expect(TimeControlTheme.dark.buttonRadius, kDefaultButtonRadius);
      expect(TimeControlTheme.dark.badgeRadius, kDefaultBadgeRadius);
    });
  });

  group('TimeControlThemeMode', () {
    test('has correct values', () {
      // Assert
      expect(TimeControlThemeMode.values.length, 3);
      expect(TimeControlThemeMode.system, isNotNull);
      expect(TimeControlThemeMode.light, isNotNull);
      expect(TimeControlThemeMode.dark, isNotNull);
    });

    test('index values are correct', () {
      // Assert
      expect(TimeControlThemeMode.system.index, 0);
      expect(TimeControlThemeMode.light.index, 1);
      expect(TimeControlThemeMode.dark.index, 2);
    });
  });

  group('Color Constants', () {
    test('dark colors are defined', () {
      // Assert
      expect(kDarkBackground, const Color(0xFF1A1A2E));
      expect(kDarkBackgroundSecondary, const Color(0xFF252540));
      expect(kDarkBackgroundHover, const Color(0xFF2D2D4A));
      expect(kDarkBorder, const Color(0xFF3D3D5C));
      expect(kDarkAccent, const Color(0xFF4ADE80));
      expect(kDarkTextPrimary, const Color(0xFFFFFFFF));
    });

    test('light colors are defined', () {
      // Assert
      expect(kLightBackground, const Color(0xFFF8F9FA));
      expect(kLightBackgroundSecondary, const Color(0xFFFFFFFF));
      expect(kLightBackgroundHover, const Color(0xFFE9ECEF));
      expect(kLightBorder, const Color(0xFFDEE2E6));
      expect(kLightAccent, const Color(0xFF22C55E));
      expect(kLightTextPrimary, const Color(0xFF212529));
    });

    test('shared constants are correct', () {
      // Assert
      expect(kDefaultTimeFontFamily, 'monospace');
      expect(kDefaultButtonRadius, 10.0);
      expect(kDefaultBadgeRadius, 10.0);
    });
  });
}
