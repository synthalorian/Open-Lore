import 'package:flutter/material.dart';
import 'theme/lore_theme.dart';
import 'screens/project_library_screen.dart';

void main() {
  runApp(const LorekeeperApp());
}

class LorekeeperApp extends StatelessWidget {
  const LorekeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Lore',
      debugShowCheckedModeBanner: false,
      theme: LoreTheme.darkTheme,
      home: const ProjectLibraryScreen(),
    );
  }
}
