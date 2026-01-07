import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:virtual_clock/virtual_clock.dart';

class HttpGuardView extends StatefulWidget {
  const HttpGuardView({super.key});

  @override
  State<HttpGuardView> createState() => _HttpGuardViewState();
}

class _HttpGuardViewState extends State<HttpGuardView> {
  String _status = 'Ready';
  Color _statusColor = Colors.grey;

  void _simulateRequest(String path) {
    final clock = context.read<ClockService>();
    final result = clock.guardHttpRequest(path);

    setState(() {
      if (result.allowed) {
        _status = 'Request to $path ALLOWED';
        _statusColor = Colors.green;
      } else {
        _status = 'Request to $path DENIED\n${result.reason}';
        _statusColor = Colors.red;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP Guard'),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Try making requests while accelerated.',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _statusColor),
                    ),
                    child: Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildRequestButton('/api/users', Icons.person),
                  const SizedBox(height: 16),
                  _buildRequestButton('/api/public/news', Icons.public),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestButton(String path, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () => _simulateRequest(path),
      icon: Icon(icon),
      label: Text('GET $path'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
    );
  }
}
