// ignore_for_file: avoid_print
/// Example demonstrating core virtual_clock features.
///
/// This file provides a simple, copy-pastable example for pub.dev.
/// For a full interactive demo, run the Flutter app in this directory.
library;

import 'package:virtual_clock/virtual_clock.dart';

Future<void> main() async {
  // 1. Initialization
  await VirtualClock.setup(
    const ClockConfig(
      clockRate: 100, // 100x acceleration for testing
      httpPolicy: HttpAction.block, // Block HTTP when accelerated
      httpAllowedPatterns: ['/api/public/*'], // Always allow these
    ),
  );

  // 2. Event subscriptions
  clock.onNewHour.subscribe((time) {
    print('New hour: ${time.hour}:00');
  });

  clock.onNewDay.subscribe((time) {
    print('New day: ${time.year}-${time.month}-${time.day}');
  });

  clock.onWeekStart.subscribe((time) {
    print('Week started!');
  });

  // 3. Time manipulation
  print('Initial virtual time: ${clock.now}');

  // Time travel to a specific date
  clock.timeTravelTo(DateTime(2030, 6, 15, 12, 0));
  print('After time travel: ${clock.now}');

  // Fast forward by a duration
  clock.fastForward(const Duration(days: 7));
  print('After +7 days: ${clock.now}');

  // 4. HTTP guard
  print('Clock rate: ${clock.clockRate}x');

  final protectedResult = clock.guardHttpRequest('/api/users');
  print('/api/users: ${protectedResult.allowed ? "ALLOWED" : "BLOCKED"}');

  final publicResult = clock.guardHttpRequest('/api/public/news');
  print('/api/public/news: ${publicResult.allowed ? "ALLOWED" : "BLOCKED"}');

  // 5. DateTime extensions
  final now = clock.now;
  final tomorrow = now.add(const Duration(days: 1));
  final yesterday = now.subtract(const Duration(days: 1));

  print('now.isVirtualToday(): ${now.isVirtualToday()}');
  print('tomorrow.isInVirtualFuture(): ${tomorrow.isInVirtualFuture()}');
  print('yesterday.isVirtualYesterday(): ${yesterday.isVirtualYesterday()}');

  // 6. Pause and resume
  clock.pause();
  print('Paused: ${clock.isPaused}');
  clock.resume();
  print('Resumed: ${clock.isPaused}');

  // 7. Reset to real time
  await clock.reset();
  print('After reset: ${clock.now}');
}
