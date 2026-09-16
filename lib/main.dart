import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main app/auth.dart'; // Import your new Authorization view

void main() async {
  // Required to ensure plugin services are initialized before runApp
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  // If 'isFirstTime' doesn't exist, it defaults to true
  final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

  runApp(MyApp(isFirstTime: isFirstTime));
}

class MyApp extends StatelessWidget {
  final bool isFirstTime;

  const MyApp({super.key, required this.isFirstTime});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickGoals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Colors.white),
      // Directs everyone through the secure authorization gate screen first
      home: AuthScreen(),
    );
  }
}
