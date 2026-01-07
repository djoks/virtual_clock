/// Numeric and configuration value constants.
///
/// Includes clock limits, UI dimensions, and default values.
library;

// =============================================================================
// Clock Rate Limits
// =============================================================================

/// Minimum allowed clock rate.
const kClockRateMin = 0;

/// Maximum allowed clock rate.
const kClockRateMax = 100000;

/// Default clock rate (real-time).
const kClockRateDefault = 1;

// =============================================================================
// HTTP Throttle Defaults
// =============================================================================

/// Default HTTP throttle limit per minute.
const kHttpThrottleLimitDefault = 10;

// =============================================================================
// UI Dimensions
// =============================================================================

/// Default button border radius.
const kDefaultButtonRadius = 10.0;

/// Default badge border radius.
const kDefaultBadgeRadius = 10.0;

// =============================================================================
// Typography
// =============================================================================

/// Default font family for time display.
/// Uses package prefix for proper resolution when used from consuming apps.
const kDefaultTimeFontFamily = 'packages/virtual_clock/Space Mono';

/// Default font family for labels.
const kDefaultLabelFontFamily = 'system-ui';

// =============================================================================
// Persistence Keys
// =============================================================================

/// SharedPreferences key for virtual time base timestamp.
const kKeyVirtualTimeBase = 'virtual_clock_base_timestamp';

/// SharedPreferences key for app version.
const kKeyAppVersion = 'virtual_clock_app_version';

// =============================================================================
// Animation Durations (in milliseconds)
// =============================================================================

/// Duration for hover animation.
const kAnimationDurationHover = 150;

/// Duration for pulse animation.
const kAnimationDurationPulse = 1500;

// =============================================================================
// Timer Intervals
// =============================================================================

/// Interval for UI update timer in seconds.
const kUpdateTimerIntervalSeconds = 1;

/// Interval for event check in milliseconds.
const kEventCheckIntervalMs = 100;
