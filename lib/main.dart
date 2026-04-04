import 'package:flutter/material.dart';
import 'features/stage_selector/stage_selector_page.dart';

void main() {
  runApp(const LaunchPadDemoApp());
}

class LaunchPadDemoApp extends StatelessWidget {
  const LaunchPadDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaunchPad — Voice Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A56DB),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const StageSelectorPage(),
    );
  }
}
