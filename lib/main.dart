import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://zfmyccxgynlmdspzjith.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpmbXljY3hneW5sbWRzcHpqaXRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA4NDMyMjAsImV4cCI6MjA1NjQxOTIyMH0.IzYoSygScIOGtuMV6VvBi1HY5LhRAu5g-lUpzjKpJiM',
  );
  print('Supabase inicializado com sucesso');

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
      home: const LoginScreen(),
    );
  }
}