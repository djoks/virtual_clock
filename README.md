# Virtual Clock

A Flutter package for virtual time manipulation and acceleration. Perfect for testing time-based features like streaks, daily bonuses, and scheduled events without waiting in real-time.

[![pub package](https://img.shields.io/pub/v/virtual_clock.svg)](https://pub.dev/packages/virtual_clock)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- **Time Acceleration** - Speed up time by any multiplier (100x, 1000x, etc.)
- **Time Travel** - Jump to any date/time instantly
- **Fast Forward** - Skip ahead by any duration
- **Pause/Resume** - Freeze time for deterministic testing
- **Clock Events** - Subscribe to onNewHour, atNoon, onNewDay, onWeekStart, onWeekEnd
- **HTTP Guard** - Control HTTP requests during accelerated time
- **Persistence** - Virtual time survives app restarts
- **Auto-Reset** - Automatically resets on app version changes
- **Production Safe** - Debug-mode only by default, forced to 1x in release builds
- **Virtual Timers** - Timer wrappers that respect accelerated time
- **DateTime Extensions** - Convenient extensions for virtual time comparisons
- **Debug UI** - Built-in TimeMachine widget for visual time control

## Use Cases

- **Testing Streaks** - Test 7-day streak logic in seconds instead of waiting a week
- **Daily Bonuses** - Verify daily bonus awards without waiting 24 hours
- **Subscription Expiry** - Test subscription renewal flows instantly
- **Scheduled Events** - Validate event triggers at specific dates/times
- **Time-Sensitive UI** - Test countdown timers and time-based UI changes

## Installation

Add `virtual_clock` to your `pubspec.yaml`:

```yaml
dependencies:
  virtual_clock: ^1.0.0-dev.1
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Setup

```dart
import 'package:virtual_clock/virtual_clock.dart';

void main() async {
  // 1. Initialize the global clock
  await VirtualClock.setup(
    const ClockConfig(
      clockRate: 100,  // 100x speed: 1 real minute = 100 virtual minutes
      appVersion: '1.0.0+1',  // For auto-reset on version changes
    ),
  );

  // 3. Use virtual time anywhere
  final now = clock.now;
  print('Virtual time: $now');

  runApp(MyApp());
}
```

### With GetIt (Service Locator Pattern)

```dart
import 'package:get_it/get_it.dart';
import 'package:virtual_clock/virtual_clock.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  // Initialize
  await VirtualClock.setup(ClockConfig(
    clockRate: int.parse(dotenv.env['CLOCK_RATE'] ?? '1'),
    appVersion: packageInfo.version,
    isProduction: dotenv.env['APP_ENV'] == 'production',
  ));

  // Register ClockService (optional, if you want dependency injection)
  getIt.registerSingleton<ClockService>(VirtualClock.service);
}
```

### With Provider

```dart
import 'package:provider/provider.dart';
import 'package:virtual_clock/virtual_clock.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ClockService>.value(
      value: VirtualClock.service,
      child: MaterialApp(
        home: HomePage(),
      ),
    );
  }
}

// In your widgets
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final clock = context.watch<ClockService>();

    return Text('Current time: ${clock.now}');
  }
}
```

## Usage

### Getting Virtual Time

Replace `DateTime.now()` with `clock.now`:

```dart
// Before (real time)
final now = DateTime.now();

// After (virtual time)
final now = clock.now;
```

### Time Travel

Jump to any specific date/time:

```dart
// Jump to Christmas 2026
clock.timeTravelTo(DateTime(2026, 12, 25));

// Jump to a specific moment
clock.timeTravelTo(DateTime(2026, 1, 15, 14, 30, 0));  // Jan 15, 2026 2:30 PM
```

### Fast Forward

Skip ahead by a duration:

```dart
// Skip ahead one week
clock.fastForward(Duration(days: 7));

// Skip ahead 3 hours
clock.fastForward(Duration(hours: 3));

// Skip to tomorrow (midnight)
final tomorrow = clock.now.add(Duration(days: 1));
clock.timeTravelTo(DateTime(tomorrow.year, tomorrow.month, tomorrow.day));
```

### Pause and Resume

Freeze time for deterministic testing:

```dart
clock.pause();

final frozenTime = clock.now;
await Future.delayed(Duration(seconds: 5));
assert(clock.now == frozenTime);  // Time hasn't moved!

clock.resume();  // Time continues from where it paused
```

### Reset to Real Time

Sync back to real time while keeping the clock rate:

```dart
await clock.reset();  // Back to real time, rate preserved
```

### Dynamic Clock Rate

Adjust the speed of time flow on the fly:

```dart
// Set specific rate
clock.setClockRate(500); // 500x speed

// Increase rate (defaults to 2x current)
clock.increaseClockRate();       // 500 -> 1000
clock.increaseClockRate(multiplier: 1.5); // 1000 -> 1500

// Decrease rate (defaults to 0.5x current)
clock.decreaseClockRate();       // 1500 -> 750
```

**Note:** Clock rate must be non-negative. Negative rates are automatically clamped to 0. Rates above 100,000 are clamped to 100,000.

## Clock Events

Subscribe to time-based events for automatic callbacks when time boundaries are crossed:

### Available Events

| Event | Triggers When |
|-------|---------------|
| `onNewHour` | Hour changes (or day/month/year changes) |
| `atNoon` | Virtual time crosses 12:00 PM |
| `onNewDay` | Day changes (midnight) |
| `onWeekStart` | New week begins (Monday) |
| `onWeekEnd` | Week ends (Sunday → Monday transition) |

### Usage

```dart
// Get notified when a new day starts
final unsubscribe = clock.onNewDay.subscribe((time) {
  print('New day: ${time.day}/${time.month}/${time.year}');
  resetDailyBonuses();
});

// Get notified at noon
clock.atNoon.subscribe((time) => showLunchReminder());

// Get notified on new hour
clock.onNewHour.subscribe((time) {
  print('New hour: ${time.hour}:00');
  updateHourlyStats();
});

// Get notified when week starts (Monday)
clock.onWeekStart.subscribe((time) => resetWeeklyChallenge());

// Get notified when week ends (Sunday to Monday)
clock.onWeekEnd.subscribe((time) => calculateWeeklyStats());

// Unsubscribe when done
unsubscribe();
```

### Event Properties

```dart
// Check if event has subscribers
if (clock.onNewDay.hasSubscribers) {
  print('Someone is listening for new days');
}

// Get subscriber count
print('${clock.onNewDay.subscriberCount} listeners');

// Clear all subscribers
clock.onNewDay.clearSubscribers();
```

## HTTP Guard

Control HTTP requests during accelerated time to prevent accidental API calls:

### Policies

| Policy | Behavior |
|--------|----------|
| `HttpPolicy.block` | Block all requests in accelerated mode (default, safest) |
| `HttpPolicy.allow` | Allow all requests regardless of clock rate |
| `HttpPolicy.throttle` | Limit requests per real minute |

### Configuration

```dart
await VirtualClock.setup(ClockConfig(
  clockRate: 100,
  httpPolicy: HttpAction.throttle,
  httpThrottleLimit: 10,  // Max 10 requests per real minute
  httpAllowedPatterns: ['/auth/*', '/health'],  // Always allowed
  httpBlockedPatterns: ['/payments/*'],  // Always blocked
  onHttpRequestDenied: (path, reason) {
    print('Request to $path blocked: $reason');
  },
));
```

### Usage in HTTP Client

```dart
// Before making a request, check with the guard
final result = clock.guardHttpRequest('/api/users');

if (result.denied) {
  print('Request blocked: ${result.reason}');
  return;  // Don't make the request
}

// Safe to proceed
final response = await http.get('/api/users');
```

### Pattern Matching

Patterns support glob syntax:
- `*` matches any characters
- `?` matches single character
- Exact paths like `/auth/login`

**Precedence:** blockedPatterns > allowedPatterns > httpPolicy

## Virtual Timers

Use `VirtualTimer` for timers that respect accelerated time:

### Periodic Timer

```dart
// Check for new day every virtual minute
// At 100x speed, this fires every 0.6 real seconds
final timer = VirtualTimer.periodicWithClock(
  Duration(minutes: 1),
  (timer) {
    if (isNewDay()) {
      handleNewDay();
    }
  },
);

// Don't forget to cancel when done
timer.cancel();
```

### One-Time Timer

```dart
// Trigger after 1 virtual hour
// At 100x speed, this fires after 36 real seconds
VirtualTimer.delayedWithClock(
  Duration(hours: 1),
  () => showReminder(),
);
```

### Async Wait

```dart
// Wait for 1 virtual day
// At 100x speed, this completes after ~14.4 real minutes
await VirtualTimer.waitWithClock(Duration(days: 1));
```

## DateTime Extensions

Convenient extensions for working with virtual time:

```dart
final someDate = DateTime(2026, 1, 15);

// Check if date is today in virtual time
if (someDate.isVirtualToday()) {
  print('This is virtually today!');
}

// Check if date is yesterday in virtual time
if (someDate.isVirtualYesterday()) {
  print('This was virtually yesterday!');
}

// Check if date is in the virtual past
if (someDate.isInVirtualPast()) {
  print('This is in the virtual past');
}

// Check if date is in the virtual future
if (someDate.isInVirtualFuture()) {
  print('This is in the virtual future');
}

// Get difference from virtual now
final diff = someDate.differenceFromVirtualNow();
print('${diff.inDays} virtual days from now');

// Check if different from virtual now (with 1 second tolerance)
if (someDate.isDifferentFromVirtualNow()) {
  print('Not the current moment');
}
```

## Debug UI

### TimeMachine Widget

A slide-out panel wrapper that provides global time control anywhere in your app. This is the recommended way to add the debug interface.

#### Basic Usage

Wrap your entire app with the overlay for global access:

```dart
TimeMachine(
  child: MaterialApp(
    home: MyHomeScreen(),
  ),
)
```

#### Features

- **Slide-out Panel**: Animated slide-in/out from right edge
- **Dark Overlay**: Semi-transparent background when open (tap to dismiss)
- **Drag Gestures**: Swipe left/right with velocity-based snapping
- **Toggle Button**: Persistent button attached to panel edge
- **Production Safety**: Hidden in release mode unless `forceShow: true`

#### Customization

```dart
TimeMachine(
  child: MyApp(),
  panelWidth: 200,  // Width of the slide-out panel
  theme: TimeControlTheme(...),  // Panel theming
  themeMode: TimeControlThemeMode.dark,
  forceShow: true,  // Show even when clockRate == 1
  overlayColor: Colors.black54,  // Dark overlay color
  buttonBuilder: (context, {required isOpen}) {
    // Custom toggle button
    return Icon(isOpen ? Icons.close : Icons.menu);
  },
)
```

### TimeControlPanel (Embedded)

For more complex layouts where you want to embed the controls directly into your own UI (not as an overlay), use `TimeControlPanel`.

#### Usage

```dart
// Add to your debug settings screen or custom drawer
TimeControlPanel()
```

#### Customization

```dart
TimeControlPanel(
  themeMode: TimeControlThemeMode.dark,
  theme: TimeControlTheme(
    accentColor: Colors.blue,
  ),
  embedded: true,
  showBorder: true,
  isOpen: true,
  onClose: () => Navigator.pop(context),
)
```

## Clock Configuration

### Configuration Options

```dart
ClockConfig(
  clockRate: 100,           // Time multiplier (default: 1, must be >= 0)
  isProduction: false,      // Force production mode (default: false)
  forceEnable: false,       // Enable in release/profile mode (default: false)
  appVersion: '1.0.0+1',    // For auto-reset on version changes
  logCallback: (msg, {level = LogLevel.info}) {
    // Custom logging
    print('[Clock] $msg');
  },
  // HTTP Guard options
  httpPolicy: HttpAction.block,
  httpAllowedPatterns: ['/auth/*'],
  httpBlockedPatterns: ['/payments/*'],
  httpThrottleLimit: 10,
  onHttpRequestDenied: (path, reason) => print('Blocked: $path'),
)
```

### Clock Rate Limits

- **Minimum:** 0 (pauses virtual time progression)
- **Maximum:** 100,000 (values above are clamped)
- **Negative values:** Not supported, clamped to 0 with warning

### Clock Rate Examples

| Clock Rate | Virtual Speed | 1 Real Minute = | 1 Virtual Day = |
|------------|---------------|-----------------|-----------------|
| 1 | Normal | 1 minute | 24 hours |
| 10 | 10x faster | 10 minutes | 2.4 hours |
| 100 | 100x faster | 1.67 hours | 14.4 minutes |
| 1000 | 1000x faster | 16.67 hours | 86.4 seconds |
| 10000 | 10000x faster | ~1 week | 8.64 seconds |

### Environment-Based Configuration

```dart
// .env file
CLOCK_RATE=100
APP_ENV=develop

// In your app
await VirtualClock.setup(ClockConfig(
  clockRate: int.parse(dotenv.env['CLOCK_RATE'] ?? '1'),
  isProduction: dotenv.env['APP_ENV'] == 'production',
  appVersion: packageInfo.version,
));
```

## Production Safety

The package includes multiple safety layers:

1. **Debug Mode Only** - Clock rate > 1 only works in debug mode by default
2. **Release Mode Check** - Clock rate is forced to 1 in release builds (`kReleaseMode`)
3. **Production Flag** - Set `isProduction: true` to reject any acceleration
4. **Force Enable** - Set `forceEnable: true` to override debug-mode restriction (use with caution)
5. **Runtime Exception** - Throws if acceleration attempted in production mode
6. **Warning Logs** - Prominent banners when acceleration is active

```dart
// This will work only in debug mode
await VirtualClock.setup(ClockConfig(clockRate: 100));

// This will throw in production
await VirtualClock.setup(ClockConfig(
  clockRate: 100,
  isProduction: true,  // Will throw!
));

// Force enable in release mode (use with extreme caution!)
await VirtualClock.setup(ClockConfig(
  clockRate: 100,
  forceEnable: true,  // Bypasses debug-mode restriction
));
```

## Constants

The package exports useful constants for customization:

```dart
import 'package:virtual_clock/virtual_clock.dart';

// Clock rate limits
kClockRateMin     // 0
kClockRateMax     // 100,000
kClockRateDefault // 1

// Theme colors (dark theme)
kDarkBackground
kDarkAccent
kDarkTextPrimary

// Theme colors (light theme)
kLightBackground
kLightAccent
kLightTextPrimary

// UI values
kDefaultButtonRadius
kDefaultBadgeRadius
kDefaultTimeFontFamily
```

## Testing

### Unit Tests

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_clock/virtual_clock.dart';

void main() {
  late ClockService clockService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await VirtualClock.setup(ClockConfig(clockRate: 100));
    clockService = VirtualClock.service;
  });

  tearDown(() {
    VirtualClock.reset();
  });

  test('time travel works', () {
    final targetDate = DateTime(2026, 12, 25);
    clock.timeTravelTo(targetDate);

    expect(clock.now.year, 2026);
    expect(clock.now.month, 12);
    expect(clock.now.day, 25);
  });

  test('pause freezes time', () async {
    clock.pause();
    final pausedTime = clock.now;

    await Future.delayed(Duration(milliseconds: 100));

    expect(clock.now, pausedTime);
  });

  test('fast forward advances time', () {
    final before = clock.now;
    clock.fastForward(Duration(days: 7));
    final after = clock.now;

    expect(after.difference(before).inDays, 7);
  });

  test('onNewDay event fires on day change', () async {
    DateTime? receivedTime;
    clock.onNewDay.subscribe((time) => receivedTime = time);

    clock.fastForward(Duration(days: 1));
    await Future.delayed(Duration(milliseconds: 200));

    expect(receivedTime, isNotNull);
  });

  test('negative clock rate is rejected', () async {
    // Negative rates are clamped to 0
    clockService.setClockRate(-10);
    expect(clockService.clockRate, 0);
  });
});
```

### Integration Testing Scenario

```dart
// Testing a 7-day streak feature
test('streak unlocks after 7 consecutive days', () async {
  // Initialize with 1000x speed (1 virtual day = ~86 seconds)
  await VirtualClock.setup(ClockConfig(clockRate: 1000));

  // Simulate 7 days of activity
  for (int day = 0; day < 7; day++) {
    await streakService.recordActivity();
    clock.fastForward(Duration(days: 1));
  }

  // Verify streak achievement
  final streak = await streakService.getCurrentStreak();
  expect(streak.days, 7);
  expect(streak.isUnlocked, true);
});
```

## API Reference

### ClockService

| Property | Type | Description |
|----------|------|-------------|
| `now` | `DateTime` | Current virtual time |
| `clockRate` | `int` | Current time multiplier |
| `isPaused` | `bool` | Whether time is paused |
| `isProduction` | `bool` | Whether running in production mode |
| `isInitialized` | `bool` | Whether service has been initialized |
| `state` | `ClockState` | Current state (running/paused) |
| `lastEventCheckTime` | `DateTime?` | Last time events were checked |

| Method | Description |
|--------|-------------|
| `setup(ClockConfig)` | Initialize the clock service |
| `timeTravelTo(DateTime)` | Jump to specific date/time |
| `fastForward(Duration)` | Skip ahead by duration |
| `pause()` | Freeze time |
| `resume()` | Unfreeze time |
| `reset()` | Reset to real time (preserves rate) |
| `setClockRate(int)` | Change clock rate dynamically |
| `increaseClockRate({double})` | Increase rate (defaults to 2x) |
| `decreaseClockRate({double})` | Decrease rate (defaults to 0.5x) |
| `clearAllState()` | Clear all persisted state |
| `guardHttpRequest(String)` | Check if HTTP request is allowed |
| `triggerEventCheck()` | Manually trigger event check |

| Event | Description |
|-------|-------------|
| `onNewHour` | Fires when hour changes |
| `atNoon` | Fires at 12:00 PM |
| `onNewDay` | Fires at midnight |
| `onWeekStart` | Fires when week starts (Monday) |
| `onWeekEnd` | Fires when week ends (Sunday → Monday) |

### VirtualClock (Global Accessor)

| Method | Description |
|--------|-------------|
| `setup(ClockConfig)` | Initialize both clock service and accessor |
| `service` | Get the global ClockService |
| `isInitialized` | Check if initialized |
| `reset()` | Clear global instance |

### VirtualTimer

| Method | Description |
|--------|-------------|
| `periodic(ClockService, Duration, callback)` | Create periodic timer |
| `periodicWithClock(Duration, callback)` | Periodic timer using global clock |
| `delayed(ClockService, Duration, callback)` | Create one-time timer |
| `delayedWithClock(Duration, callback)` | One-time timer using global clock |
| `wait(ClockService, Duration)` | Async wait for virtual duration |
| `waitWithClock(Duration)` | Async wait using global clock |

### ClockEvent

| Property/Method | Description |
|-----------------|-------------|
| `name` | Event name for debugging |
| `hasSubscribers` | Whether event has any subscribers |
| `subscriberCount` | Number of subscribers |
| `subscribe(callback)` | Subscribe to event, returns unsubscribe function |
| `unsubscribe(callback)` | Unsubscribe specific callback |
| `clearSubscribers()` | Remove all subscribers |

### HttpGuardResult

| Property | Description |
|----------|-------------|
| `action` | HttpGuardAction (allow/block/throttle) |
| `reason` | Reason for blocking (null if allowed) |
| `allowed` | Whether request is allowed |
| `denied` | Whether request was denied |

## Troubleshooting

### Clock not accelerating?

1. Check if you're in release mode (`kReleaseMode` forces rate to 1)
2. Verify `isProduction` is not set to `true`
3. Ensure `setup()` was called before using the clock
4. In release/profile mode, set `forceEnable: true` if you really need acceleration

### Virtual time reset unexpectedly?

The clock auto-resets when the app version changes. This is intentional to prevent stale virtual time from previous development sessions.

### Getting `StateError: VirtualClock not initialized`?

Make sure to call `VirtualClock.setup(clockConfig)`.

### Events not firing?

1. Ensure you've subscribed before the time change
2. Check that time actually crossed the boundary (e.g., for onNewDay, time must cross midnight)
3. Wait briefly after fast forward for event timer to trigger

### HTTP requests being blocked?

1. Check your `httpPolicy` setting
2. Review `httpAllowedPatterns` and `httpBlockedPatterns`
3. Use `guardHttpRequest()` to check before making requests

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Inspired by the need to test time-based features in Flutter apps without the tedious wait times. Built with love for developers who value their time (pun intended).
