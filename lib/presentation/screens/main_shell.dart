import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

/// Persistent bottom-navigation shell: Home / Settings.
/// Each tab keeps its own state via [IndexedStack] so switching tabs
/// never loses scroll position.
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  static const _tabs = [
    _TabDef(icon: Icons.home_rounded, outlineIcon: Icons.home_outlined, label: 'Home'),
    _TabDef(icon: Icons.settings_rounded, outlineIcon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: [
          for (final tab in _tabs)
            BottomNavigationBarItem(
              icon: Icon(tab.outlineIcon),
              activeIcon: Icon(tab.icon, color: AppColors.gold),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _TabDef {
  final IconData icon;
  final IconData outlineIcon;
  final String label;

  const _TabDef({required this.icon, required this.outlineIcon, required this.label});
}
