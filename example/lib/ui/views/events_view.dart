import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtual_clock/virtual_clock.dart';

class EventsView extends StatefulWidget {
  const EventsView({super.key});

  @override
  State<EventsView> createState() => _EventsViewState();
}

class _EventsViewState extends State<EventsView> {
  final List<String> _logs = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    final clock = context.read<ClockService>();

    clock.onNewHour.subscribe((time) {
      _log('New Hour: ${time.hour}:00');
    });

    clock.onNewDay.subscribe((time) {
      _log('New Day: ${time.year}-${time.month}-${time.day}');
    });

    clock.onWeekStart.subscribe((time) {
      _log('Week Start: Monday!');
    });
  }

  void _log(String message) {
    if (!mounted) return;
    setState(() {
      _logs.insert(
        0,
        '[${DateTime.now().toString().split(' ')[1].substring(0, 8)}] $message',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Subscriptions'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Accelerate the clock to see events fire.',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Text(
                    _logs[index],
                    style: const TextStyle(
                      fontFamily: 'Space Mono',
                      fontSize: 13,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
