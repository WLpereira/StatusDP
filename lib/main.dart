import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://zfmyccxgynlmdspzjith.supabase.co', // Substitua pela URL do seu Supabase
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpmbXljY3hneW5sbWRzcHpqaXRoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA4NDMyMjAsImV4cCI6MjA1NjQxOTIyMH0.IzYoSygScIOGtuMV6VvBi1HY5LhRAu5g-lUpzjKpJiM', // Substitua pela chave anônima do seu Supabase
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planner DP',
      theme: ThemeData.dark(),
      home: const LoginScreen(),
    );
  }
}