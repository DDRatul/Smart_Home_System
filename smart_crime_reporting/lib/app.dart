import 'package:flutter/material.dart';
import 'auth_gate.dart';
import 'screens/start_screen.dart'; // ✅ add this (path may differ)

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Crime Reporting',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
      ),
      home: const StartScreen(),
    );
  }
}
