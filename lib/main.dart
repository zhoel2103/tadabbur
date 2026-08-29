import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const QuranChatApp());
}

class QuranChatApp extends StatelessWidget {
  const QuranChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Tadabbur Qur'an",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
