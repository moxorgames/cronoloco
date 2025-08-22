import 'package:flutter/material.dart';
import 'screens/activity_list_screen.dart';

void main() {
  runApp(const CronolocoApp());
}

class CronolocoApp extends StatelessWidget {
  const CronolocoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cronoloco',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ActivityListScreen(),
    );
  }
}