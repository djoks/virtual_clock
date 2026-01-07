import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtual_clock/virtual_clock.dart';

class DateTimeView extends StatefulWidget {
  const DateTimeView({super.key});

  @override
  State<DateTimeView> createState() => _DateTimeViewState();
}

class _DateTimeViewState extends State<DateTimeView> {
  late DateTime _realNow;
  late DateTime _virtualNow;

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    if (!mounted) return;
    setState(() {
      _realNow = DateTime.now();
      _virtualNow = context.read<ClockService>().now;
    });

    // Auto-refresh every second
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  @override
  Widget build(BuildContext context) {
    // We use context.watch to rebuild when clock service notifies changes
    final clock = context.watch<ClockService>();
    final now = clock.now;

    // Create some dates relative to virtual NOW
    final yesterday = now.subtract(const Duration(days: 1));
    final tomorrow = now.add(const Duration(days: 1));
    final nextWeek = now.add(const Duration(days: 7));

    return Scaffold(
      appBar: AppBar(
        title: const Text('DateTime Extensions'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildInfoCard('Context', [
                  'Real Time: ${_formatTime(_realNow)}',
                  'Virtual Time: ${_formatTime(_virtualNow)}',
                ]),
                const SizedBox(height: 16),
                _buildSectionHeader('Extension Checks'),
                const SizedBox(height: 8),
                _buildCheckItem('now.isVirtualToday()', now.isVirtualToday()),
                _buildCheckItem(
                  'yesterday.isVirtualYesterday()',
                  yesterday.isVirtualYesterday(),
                ),
                _buildCheckItem(
                  'tomorrow.isInVirtualFuture()',
                  tomorrow.isInVirtualFuture(),
                ),
                _buildCheckItem(
                  'nextWeek.isInVirtualFuture()',
                  nextWeek.isInVirtualFuture(),
                ),

                const SizedBox(height: 24),
                _buildSectionHeader('Comparisons'),
                const SizedBox(height: 8),
                _buildInfoCard('Virtual Difference', [
                  'Tomorrow vs Now: ${tomorrow.differenceFromVirtualNow().inHours} hours',
                  'Next Week vs Now: ${nextWeek.differenceFromVirtualNow().inDays} days',
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildCheckItem(String expression, bool result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            result ? Icons.check_circle : Icons.cancel,
            color: result ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              expression,
              style: const TextStyle(fontFamily: 'Space Mono', fontSize: 13),
            ),
          ),
          Text(
            result.toString().toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: result ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> lines) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent,
            ),
          ),
          const SizedBox(height: 8),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: const TextStyle(fontFamily: 'Space Mono', fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
