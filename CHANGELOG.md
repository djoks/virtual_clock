# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0-dev.3] - 2026-01-07

### Added
- `TimeMachine` widget - A new public wrapper for the debug overlay, replacing direct usage of `TimeControlPanelOverlay`.
- `VirtualClock.setup(ClockConfig)` - Simplified initialization method properly accepting configuration.

### Changed
- **BREAKING**: Renamed `VirtualClock.initialize` to `VirtualClock.setup`.
- **BREAKING**: Removed `clockService` parameter from `TimeMachine`, `TimeControlPanelOverlay`, and `TimeControlPanel`. These widgets now strictly use the internal singleton service accessed via the global `clock` getter.
- **BREAKING**: Made `TimeControlPanelOverlay` internal. Use `TimeMachine` instead.
- Refactored `VirtualClock` to manage its own singleton `ClockService` instance. Manual injection is no longer supported.

## [1.0.0-dev.2] - 2026-01-07

### Added
- `TimeControlPanelOverlay` widget for slide-out panel integration
  - Animated slide-in/out from right edge
  - Dark overlay with tap to dismiss
  - Drag gestures with velocity-based snapping
  - Persistent toggle button
  - Production safety (hidden when clockRate == 1)
- Comprehensive example app demonstrating all package features
- GitHub Actions CI/CD workflows for automated publishing

### Fixed
- Font family path for package resolution in consuming apps
- Removed SnackBar from reset button to avoid ScaffoldMessenger dependency

### Changed
- Updated README with TimeControlPanelOverlay documentation

## [1.0.0-dev.1] - 2026-01-06

### Added
- Initial release of Virtual Clock package
- `ClockService` - Core service for virtual time management
  - Time acceleration with configurable clock rate
  - Time travel to any date/time
  - Fast forward by duration
  - Pause and resume functionality
  - Persistence across app restarts
  - Auto-reset on app version changes
  - Production safety (forced to 1x in release builds)
- `VirtualClock` - Global accessor for convenient clock access
- `VirtualTimer` - Timer wrappers that respect virtual time
  - `periodic()` - Repeating timer
  - `delayed()` - One-time timer
  - `wait()` - Async wait
- `VirtualClockX` - DateTime extensions
  - `isVirtualToday()` - Check if date is today in virtual time
  - `isVirtualYesterday()` - Check if date is yesterday in virtual time
  - `isInVirtualPast()` - Check if date is in virtual past
  - `isInVirtualFuture()` - Check if date is in virtual future
  - `differenceFromVirtualNow()` - Get difference from virtual now
  - `isDifferentFromVirtualNow()` - Check if different from virtual now
- `ClockConfig` - Configuration class for clock initialization
- Comprehensive documentation and examples
