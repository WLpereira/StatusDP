import 'package:flutter/material.dart';
import 'package:status_dp_app/screens/status_dp_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Status DP App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const StatusDPScreen(),
    );
  }
}