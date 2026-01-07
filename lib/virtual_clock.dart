/// A Flutter package for virtual time manipulation and acceleration.
///
/// Perfect for testing time-based features like streaks, daily bonuses,
/// and scheduled events without waiting in real-time.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:virtual_clock/virtual_clock.dart';
///
/// // 1. Create and initialize the clock service
/// final clockService = ClockService();
/// await clockService.initialize(ClockConfig(
///   clockRate: 100,  // 100x speed: 1 real minute = 100 virtual minutes
///   appVersion: '1.0.0+1',
/// ));
///
/// // 2. Set up global accessor (optional but recommended)
/// VirtualClock.initialize(clockService);
///
/// // 3. Use virtual time anywhere
/// final now = clock.now;
///
/// // 4. Time manipulation for testing
/// clock.timeTravelTo(DateTime(2026, 12, 25));  // Jump to Christmas
/// clock.fastForward(Duration(days: 7));         // Skip a week
/// clock.pause();                                // Freeze time
/// clock.resume();                               // Unfreeze
/// await clock.reset();                          // Back to real time
/// ```
///
/// ## Features
///
/// - **Time Acceleration**: Speed up time by any multiplier (100x, 1000x, etc.)
/// - **Time Travel**: Jump to any date/time instantly
/// - **Fast Forward**: Skip ahead by any duration
/// - **Pause/Resume**: Freeze time for deterministic testing
/// - **Persistence**: Virtual time survives app restarts
/// - **Auto-Reset**: Automatically resets on app version changes
/// - **Production Safe**: Forced to 1x in release builds
/// - **Time Events**: Subscribe to onNewHour, atNoon, onNewDay, onWeekStart, onWeekEnd
///
/// ## Time Events
///
/// Subscribe to time-based events for automatic callbacks:
///
/// ```dart
/// // Get notified when a new day starts
/// clock.onNewDay.subscribe((time) {
///   print('New day: ${time.day}/${time.month}');
///   resetDailyBonuses();
/// });
///
/// // Get notified at noon
/// clock.atNoon.subscribe((time) => showLunchReminder());
///
/// // Get notified on new hour
/// clock.onNewHour.subscribe((time) => updateHourlyStats());
///
/// // Get notified when week starts (Monday)
/// clock.onWeekStart.subscribe((time) => resetWeeklyChallenge());
///
/// // Get notified when week ends (Sunday to Monday)
/// clock.onWeekEnd.subscribe((time) => calculateWeeklyStats());
/// ```
///
/// ## Virtual Timers
///
/// Use [VirtualTimer] for timers that respect accelerated time:
///
/// ```dart
/// // Fire every virtual minute (every 0.6 real seconds at 100x)
/// final timer = VirtualTimer.periodicWithClock(
///   Duration(minutes: 1),
///   (timer) => checkForNewDay(),
/// );
///
/// // Wait for virtual duration
/// await VirtualTimer.waitWithClock(Duration(hours: 1));
/// ```
///
/// ## DateTime Extensions
///
/// Convenient extensions for working with virtual time:
///
/// ```dart
/// final someDate = DateTime(2026, 1, 1);
///
/// if (someDate.isVirtualToday()) {
///   // It's virtually today!
/// }
///
/// if (someDate.isInVirtualPast()) {
///   // This date is in the virtual past
/// }
/// ```
library;

// Enums
export 'src/enums/clock_state.dart';
export 'src/enums/http_action.dart';
export 'src/enums/log_level.dart';

// Constants
export 'src/constants/constants.dart';

// Events
export 'src/events/events.dart';

// Models
export 'src/models/clock_config.dart';
export 'src/models/http_guard_result.dart';

// Services
export 'src/services/clock_service.dart';

// UI
export 'src/ui/time_control_panel.dart';
export 'src/ui/time_control_theme.dart';

// Utils
export 'src/utils/clock_extensions.dart';
export 'src/utils/virtual_timer.dart';
