import 'package:flutter/material.dart';
import 'screens/patient_detail_screen.dart';

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
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5),
          primary: const Color(0xFF4F46E5),
        ),
        useMaterial3: true,
      ),
      home: const PatientDetailScreen(),
    );
  }
}
