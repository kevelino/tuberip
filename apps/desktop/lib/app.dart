import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'ui/screens/main_screen.dart';

class TubeRipApp extends StatelessWidget {
  const TubeRipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TubeRip',
      theme: AppTheme.dark,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
