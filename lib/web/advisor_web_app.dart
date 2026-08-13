import 'package:flutter/material.dart';
import 'web_theme.dart';
import 'screens/web_shell.dart';

class AdvisorWebApp extends StatelessWidget {
  const AdvisorWebApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriAdvisor — Advisor Dashboard',
      debugShowCheckedModeBanner: false,
      theme: WebTheme.theme,
      home: const WebShell(),
    );
  }
}
