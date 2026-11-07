import 'package:flutter/material.dart';

import 'features/indicators/indicator_screens.dart';

void main() {
  runApp(const RedVitalysApp());
}

class RedVitalysApp extends StatelessWidget {
  const RedVitalysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Red Vitalys',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFAFAFE),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5045EF),
          surface: const Color(0xFFFAFAFE),
        ),
        fontFamily: 'Roboto',
      ),
      home: const IndicatorsDashboardScreen(),
    );
  }
}
