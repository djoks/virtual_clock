import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtual_clock/virtual_clock.dart';
import 'package:virtual_clock_example/ui/widgets/feature_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildHeader(context),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FEATURES',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    FeatureCard(
                      title: 'Event Subscription',
                      description:
                          'Listen to NewHour, NewDay, and custom events',
                      icon: Icons.notifications_active,
                      route: '/events',
                    ),
                    SizedBox(height: 12),
                    FeatureCard(
                      title: 'HTTP Guard',
                      description:
                          'Protect network calls during time acceleration',
                      icon: Icons.security,
                      route: '/http',
                    ),
                    SizedBox(height: 12),
                    FeatureCard(
                      title: 'Virtual Timer',
                      description: 'Timers that respect clock acceleration',
                      icon: Icons.timer,
                      route: '/timer',
                    ),
                    SizedBox(height: 12),
                    FeatureCard(
                      title: 'DateTime Extensions',
                      description: 'Virtual-time aware date comparisons',
                      icon: Icons.calendar_today,
                      route: '/datetime',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final now = context.watch<ClockService>().now;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const Text(
            'VIRTUAL CLOCK',
            style: TextStyle(
              fontSize: 14,
              letterSpacing: 3,
              color: Colors.blueAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              fontFamily: 'Space Mono',
            ),
          ),
          Text(
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
            style: TextStyle(fontSize: 16, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
