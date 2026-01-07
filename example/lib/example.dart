// ignore_for_file: avoid_print
/// Example demonstrating core virtual_clock features.
///
/// This file provides a simple, copy-pastable example for pub.dev.
/// For a full interactive demo, run the Flutter app in this directory.
library;

import 'package:virtual_clock/virtual_clock.dart';

Future<void> main() async {
  // 1. Initialization
  final clockService = ClockService();
  await clockService.initialize(
    const ClockConfig(
      clockRate: 100, // 100x acceleration for testing
      httpPolicy: HttpAction.block, // Block HTTP when accelerated
      httpAllowedPatterns: ['/api/public/*'], // Always allow these
    ),
  );

  // Set up global accessor (optional but recommended)
  VirtualClock.initialize(clockService);

  // 2. Event subscriptions
  clockService.onNewHour.subscribe((time) {
    print('New hour: ${time.hour}:00');
  });

  clockService.onNewDay.subscribe((time) {
    print('New day: ${time.year}-${time.month}-${time.day}');
  });

  clockService.onWeekStart.subscribe((time) {
    print('Week started!');
  });

  // 3. Time manipulation
  print('Initial virtual time: ${clockService.now}');

  // Time travel to a specific date
  clockService.timeTravelTo(DateTime(2030, 6, 15, 12, 0));
  print('After time travel: ${clockService.now}');

  // Fast forward by a duration
  clockService.fastForward(const Duration(days: 7));
  print('After +7 days: ${clockService.now}');

  // 4. HTTP guard
  print('Clock rate: ${clockService.clockRate}x');

  final protectedResult = clockService.guardHttpRequest('/api/users');
  print('/api/users: ${protectedResult.allowed ? "ALLOWED" : "BLOCKED"}');

  final publicResult = clockService.guardHttpRequest('/api/public/news');
  print('/api/public/news: ${publicResult.allowed ? "ALLOWED" : "BLOCKED"}');

  // 5. DateTime extensions
  final now = clockService.now;
  final tomorrow = now.add(const Duration(days: 1));
  final yesterday = now.subtract(const Duration(days: 1));

  print('now.isVirtualToday(): ${now.isVirtualToday()}');
  print('tomorrow.isInVirtualFuture(): ${tomorrow.isInVirtualFuture()}');
  print('yesterday.isVirtualYesterday(): ${yesterday.isVirtualYesterday()}');

  // 6. Pause and resume
  clockService.pause();
  print('Paused: ${clockService.isPaused}');
  clockService.resume();
  print('Resumed: ${clockService.isPaused}');

  // 7. Reset to real time
  await clockService.reset();
  print('After reset: ${clockService.now}');
}
