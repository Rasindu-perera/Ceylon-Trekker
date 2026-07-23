import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/around_screen.dart';
import '../screens/budget_screen.dart';
import '../screens/home_screen.dart';
import '../screens/plan_screen.dart';
import '../screens/login_screen.dart';
import '../widgets/app_shell.dart';
import 'app_theme.dart';

class CeylonTrekkerApp extends StatelessWidget {
  const CeylonTrekkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ceylon Trekker',
      theme: AppTheme.darkTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppTheme.background,
              body: Center(
                child: CircularProgressIndicator(color: AppTheme.emerald),
              ),
            );
          }
          
          if (snapshot.hasData) {
            return const AppShell(
              screens: [
                HomeScreen(),
                PlanScreen(),
                AroundScreen(),
                BudgetScreen(),
              ],
            );
          }
          
          return const LoginScreen();
        },
      ),
    );
  }
}