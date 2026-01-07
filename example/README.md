# Virtual Clock Example

A Flutter application demonstrating all features of the `virtual_clock` package.

## Features Demonstrated

| Feature | Description |
|---------|-------------|
| **Event Subscriptions** | Listen to `onNewHour`, `onNewDay`, `onWeekStart` events |
| **HTTP Guard** | Protect network calls during time acceleration |
| **Virtual Timer** | Timers that respect clock acceleration |
| **DateTime Extensions** | Virtual-time aware date comparisons |
| **TimeMachine** | Slide-out panel for global time control |

## Running the Example

```bash
cd example
flutter run
```

## App Structure

```
lib/
├── main.dart              # App entry point with overlay setup
├── example.dart           # Standalone code sample for pub.dev
└── ui/
    ├── views/
    │   ├── home_view.dart      # Main dashboard
    │   ├── events_view.dart    # Event subscription demo
    │   ├── http_guard_view.dart # HTTP guard demo
    │   ├── timer_view.dart     # Virtual timer demo
    │   └── datetime_view.dart  # DateTime extensions demo
    └── widgets/
        └── feature_card.dart   # Reusable navigation card
```

## Key Integration Points

### 1. Initialization & Overlay

Initialize the global clock in `main()` and wrap your app:

```dart
void main() async {
  // 1. Initialize global clock
  await VirtualClock.setup(
    const ClockConfig(
      clockRate: 100,
      appVersion: '1.0.0+1',
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        // 2. Provide the service
        ChangeNotifierProvider.value(value: VirtualClock.service)
      ],
      child: const VirtualClockExampleApp(),
    ),
  );
}

// 3. Wrap MaterialApp
class VirtualClockExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TimeMachine(
      forceShow: true,
      child: MaterialApp(...),
    );
  }
}
```

### 2. Event Subscriptions

```dart
clock.onNewHour.subscribe((time) {
  log('New hour: ${time.hour}:00');
});

clock.onNewDay.subscribe((time) {
  log('New day: ${time.day}/${time.month}/${time.year}');
});
```

### 3. HTTP Guard

```dart
final result = clock.guardHttpRequest('/api/users');
if (result.denied) {
  print('Blocked: ${result.reason}');
}
```

### 4. Virtual Timer

```dart
VirtualTimer.periodic(clock, Duration(seconds: 1), (timer) {
  // Fires faster when clock is accelerated
});
```

## Screenshots

The app includes a slide-out panel on the right edge for controlling:
- Time jumps (+1h, +3h, +6h, +1d, +3d, +1w)
- Time travel to specific dates
- Pause/Resume
- Reset to real time
