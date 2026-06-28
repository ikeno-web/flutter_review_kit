import 'package:flutter/material.dart';
import 'package:flutter_review_kit/flutter_review_kit.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flutter_review_kit Example',
      home: const ReviewDemoPage(),
    );
  }
}

class ReviewDemoPage extends StatefulWidget {
  const ReviewDemoPage({super.key});

  @override
  State<ReviewDemoPage> createState() => _ReviewDemoPageState();
}

class _ReviewDemoPageState extends State<ReviewDemoPage> {
  late final ReviewManager _manager;
  String _status = 'Not initialized';

  @override
  void initState() {
    super.initState();
    _manager = ReviewManager(
      config: const ReviewConfig(
        minLaunches: 3,
        minDaysInstalled: 1,
        minEvents: 2,
        cooldownDays: 30,
        happyMoments: ['purchase_complete', 'level_complete'],
        debug: true,
      ),
      appVersion: '1.0.0',
      // In production, use:
      // reviewRequester: () async {
      //   final inAppReview = InAppReview.instance;
      //   if (await inAppReview.isAvailable()) {
      //     await inAppReview.requestReview();
      //     return true;
      //   }
      //   return false;
      // },
    );
    _init();
  }

  Future<void> _init() async {
    await _manager.initialize();
    await _manager.trackLaunch();
    _updateStatus();
  }

  void _updateStatus() {
    setState(() {
      final s = _manager.state;
      _status = 'Launches: ${s.launchCount}\n'
          'Events: ${s.eventCount}\n'
          'Days installed: ${s.firstLaunchDate != null ? DateTime.now().difference(s.firstLaunchDate!).inDays : 0}\n'
          'Prompts: ${s.promptCount}\n'
          'Ready: ${_manager.isReady}';
    });
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review Kit Demo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_status),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _manager.trackEvent('button_press');
                _updateStatus();
              },
              child: const Text('Track Event'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                final result = await _manager.requestReviewIfReady();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Result: $result')),
                );
                _updateStatus();
              },
              child: const Text('Request Review If Ready'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () async {
                await _manager.reset();
                _updateStatus();
              },
              child: const Text('Reset State'),
            ),
          ],
        ),
      ),
    );
  }
}
