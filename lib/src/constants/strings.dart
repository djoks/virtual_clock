/// String constants for log messages, errors, and labels.
///
/// Organized by category: logging, errors, UI labels.
library;

// =============================================================================
// Log Tags and Prefixes
// =============================================================================

/// Prefix for all virtual clock log messages.
const kLogPrefix = '[VirtualClock]';

// =============================================================================
// Log Messages
// =============================================================================

/// Message when resetting virtual time due to version change or first run.
const kLogResettingVirtualTime =
    'Resetting virtual time (version change or first run)';

/// Message when clock rate changes.
const kLogClockRateChanged = 'Clock rate changed to';

/// Message when acceleration banner is shown.
const kLogClockAccelerationActive = 'CLOCK ACCELERATION ACTIVE:';

/// Message for virtual time acceleration warning.
const kLogVirtualTimeAccelerated = 'Virtual time is accelerated!';

/// Message for not for production use warning.
const kLogNotForProduction = 'NOT FOR PRODUCTION USE';

// =============================================================================
// Warning Messages
// =============================================================================

/// Warning when negative clock rate is provided.
const kWarnNegativeClockRate = 'Negative clock rate';

/// Warning suffix for negative clock rate.
const kWarnNegativeClockRateSuffix = 'not supported. Resetting to 1.';

/// Warning when clamping negative rate.
const kWarnClampingNegative = 'not supported. Clamping to 0.';

/// Warning when clamping high rate.
const kWarnClampingHigh = 'too high. Clamping to 100,000.';

/// Warning when clock rate ignored in release mode.
const kWarnReleaseMode = 'CLOCK_RATE ignored in release mode (forced to 1)';

/// Warning when virtual clock only runs in debug mode.
const kWarnDebugModeOnly =
    'Virtual clock only runs in debug mode. Set forceEnable=true to override.';

/// Warning when cannot change clock rate in production.
const kWarnProductionMode = 'Cannot change clock rate in production mode';

// =============================================================================
// Error Messages
// =============================================================================

/// Error when clock rate must be 1 in production.
const kErrProductionClockRate =
    'CLOCK_RATE must be 1 in production environment';

/// Error when clock acceleration not allowed in production.
const kErrAccelerationNotAllowed =
    'Clock acceleration not allowed in production';

/// Error when clock rate assertion fails.
const kErrClockRateAssertion = 'Clock rate must be non-negative';

// =============================================================================
// HTTP Guard Messages
// =============================================================================

/// Reason for blocking in accelerated mode.
const kHttpReasonAcceleratedMode = 'Accelerated mode active (rate=';

/// Reason for throttle limit exceeded.
const kHttpReasonThrottleExceeded = 'Throttle limit';

/// Suffix for throttle exceeded message.
const kHttpReasonThrottleSuffix = '/min) exceeded';

// =============================================================================
// UI Labels
// =============================================================================

/// Label for jump section header.
const kLabelJump = 'JUMP';

/// Label for date section header.
const kLabelDate = 'DATE';

/// Label for tomorrow button.
const kLabelTomorrow = 'Tomorrow';

/// Label for pick date button.
const kLabelPickDate = 'Pick Date';

/// Label for pause button.
const kLabelPause = 'Pause';

/// Label for resume button.
const kLabelResume = 'Resume';

/// Label for reset button.
const kLabelReset = 'Reset';

/// Snackbar message after time reset.
const kSnackbarTimeReset = 'Time reset';
