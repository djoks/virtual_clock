import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtual_clock/virtual_clock.dart';
import 'package:virtual_clock_example/ui/views/datetime_view.dart';
import 'package:virtual_clock_example/ui/views/events_view.dart';
import 'package:virtual_clock_example/ui/views/home_view.dart';
import 'package:virtual_clock_example/ui/views/http_guard_view.dart';
import 'package:virtual_clock_example/ui/views/timer_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ClockService
  final clockService = ClockService();
  await clockService.initialize(
    const ClockConfig(
      clockRate: 100, // Start with accelerated time for demo
      httpPolicy: HttpAction.block,
      httpAllowedPatterns: ['/api/public/*'],
    ),
  );

  // Initialize global accessor
  VirtualClock.initialize(clockService);

  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider.value(value: clockService)],
      child: const VirtualClockExampleApp(),
    ),
  );
}

class VirtualClockExampleApp extends StatelessWidget {
  const VirtualClockExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return TimeControlPanelOverlay(
      forceShow: true, // Always show in example app
      child: MaterialApp(
        title: 'Virtual Clock Example',
        theme: ThemeData(
          brightness: Brightness.dark,
          primarySwatch: Colors.blue,
          fontFamily: 'Space Mono',
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          useMaterial3: true,
        ),
        routes: {
          '/': (context) => const HomeView(),
          '/events': (context) => const EventsView(),
          '/http': (context) => const HttpGuardView(),
          '/timer': (context) => const TimerView(),
          '/datetime': (context) => const DateTimeView(),
        },
        initialRoute: '/',
      ),
    );
  }
}
