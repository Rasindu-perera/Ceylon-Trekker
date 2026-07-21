import 'package:flutter/material.dart';

import '../screens/around_screen.dart';
import '../screens/budget_screen.dart';
import '../screens/home_screen.dart';
import '../screens/plan_screen.dart';
import '../widgets/app_shell.dart';
import '../screens/splash_screen.dart';
import 'app_theme.dart';

class CeylonTrekkerApp extends StatelessWidget {
  const CeylonTrekkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ceylon Trekker',
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}