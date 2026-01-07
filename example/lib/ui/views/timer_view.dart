import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtual_clock/virtual_clock.dart';

class TimerView extends StatefulWidget {
  const TimerView({super.key});

  @override
  State<TimerView> createState() => _TimerViewState();
}

class _TimerViewState extends State<TimerView> {
  Timer? _timer;
  int _remainingSeconds = 60;
  bool _isRunning = false;

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 60;
      _isRunning = true;
    });

    final clock = context.read<ClockService>();
    _timer = VirtualTimer.periodic(clock, const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _isRunning = false;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Timer'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Accelerate clock to speed up the timer.',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$_remainingSeconds',
                    style: const TextStyle(
                      fontSize: 120,
                      fontFamily: 'Space Mono',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('VIRTUAL SECONDS REMAINING'),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: _isRunning ? null : _startTimer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 24,
                      ),
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      _isRunning ? 'RUNNING...' : 'START 1 MIN TIMER',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
