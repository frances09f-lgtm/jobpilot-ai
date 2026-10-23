import 'package:flutter/material.dart';
import '../features/home_screen.dart';

class JobPilotApp extends StatelessWidget {
  const JobPilotApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'JobPilot AI', debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0A0F1F),
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B8CFF), brightness: Brightness.dark,
        primary: const Color(0xFF5B8CFF), secondary: const Color(0xFFA78BFA), surface: const Color(0xFF121A2E), onSurface: const Color(0xFFEEF1F8)),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0A0F1F), centerTitle: false),
      inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: const Color(0xFF070C18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2C3851)))),
    ), home: const HomeScreen(),
  );
}
