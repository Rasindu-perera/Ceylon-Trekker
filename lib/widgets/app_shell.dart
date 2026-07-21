import 'package:flutter/material.dart';

import '../app/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.screens});

  final List<Widget> screens;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int currentIndex = 0;

  void onTabSelected(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: currentIndex,
        children: widget.screens,
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white10),
            boxShadow: const [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              height: 76,
              selectedIndex: currentIndex,
              onDestinationSelected: onTabSelected,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              indicatorColor: AppTheme.emerald.withValues(alpha: 0.2),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined, color: Colors.white70),
                  selectedIcon: Icon(Icons.home_rounded, color: AppTheme.emerald),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.event_note_outlined, color: Colors.white70),
                  selectedIcon: Icon(Icons.event_note_rounded, color: AppTheme.emerald),
                  label: 'Plan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined, color: Colors.white70),
                  selectedIcon: Icon(Icons.explore_rounded, color: AppTheme.emerald),
                  label: 'Around',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined, color: Colors.white70),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: AppTheme.emerald),
                  label: 'Budget',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}