import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.location});

  final String location;

  static const _destinations = <({String path, IconData icon, String label})>[
    (path: '/app/home', icon: Icons.home_outlined, label: 'Home'),
    (path: '/app/reports', icon: Icons.bar_chart_outlined, label: 'Reports'),
    (path: '/app/ai', icon: Icons.auto_awesome_outlined, label: 'AI'),
    (path: '/app/records', icon: Icons.receipt_long_outlined, label: 'Records'),
    (path: '/app/settings', icon: Icons.settings_outlined, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final index = _destinations.indexWhere((item) => location.startsWith(item.path));
    return NavigationBar(
      selectedIndex: index < 0 ? 0 : index,
      onDestinationSelected: (selected) => context.go(_destinations[selected].path),
      destinations: _destinations
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.icon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}
