# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-06

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
