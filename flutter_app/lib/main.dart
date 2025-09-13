import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'config.dart';
import 'push_notification_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Push Demo',
      theme: ThemeData(colorSchemeSeed: Colors.blue, useMaterial3: true),
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _backendController = TextEditingController(text: defaultBackendBaseUrl);
  String? _token;
  bool _initializing = true;
  String _statusText = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await PushNotificationService.instance.initialize();
      final String? token = PushNotificationService.instance.deviceToken;
      setState(() {
        _token = token;
        _statusText = 'Ready';
        _initializing = false;
      });
    } catch (e) {
      setState(() {
        _statusText = 'Initialization error: $e';
        _initializing = false;
      });
    }
  }

  Future<void> _sendTestPush() async {
    final String baseUrl = _backendController.text.trim();
    if (_token == null || _token!.isEmpty) {
      _showSnack('No FCM token yet');
      return;
    }
    try {
      final http.Response resp = await PushNotificationService.instance.sendPushViaBackend(
        backendBaseUrl: baseUrl,
        token: _token,
        title: 'Hello from Flutter',
        body: 'This is a test push',
      );
      final String pretty = _prettyBody(resp.body);
      _showSnack('Status ${resp.statusCode}: $pretty');
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  String _prettyBody(String body) {
    try {
      final Object? jsonObj = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(jsonObj);
    } catch (_) {
      return body;
    }
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Push Notification Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $_statusText'),
            const SizedBox(height: 12),
            const Text('Device FCM Token:'),
            SelectableText(_token ?? 'Loading...'),
            const SizedBox(height: 16),
            const Text('Backend Base URL'),
            TextField(
              controller: _backendController,
              decoration: const InputDecoration(
                hintText: 'http://10.0.2.2:8080',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _initializing ? null : _sendTestPush,
                  icon: const Icon(Icons.send),
                  label: const Text('Send test push'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _initializing
                      ? null
                      : () async {
                          final String? newToken = await PushNotificationService.instance.refreshAndGetToken();
                          setState(() => _token = newToken);
                        },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh token'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Notes:'),
            const Text('• Use 10.0.2.2 for Android emulator, localhost for iOS simulator.'),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _backendController.dispose();
    super.dispose();
  }
}

