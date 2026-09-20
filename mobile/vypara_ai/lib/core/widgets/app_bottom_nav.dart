import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.location});

  final String location;

  static const _destinations = <({String path, IconData icon, IconData activeIcon, String label})>[
    (path: '/app/home', icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home'),
    (path: '/app/reports', icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart_rounded, label: 'Reports'),
    (path: '/app/ai', icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, label: 'AI'),
    (path: '/app/records', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long, label: 'Records'),
    (path: '/app/settings', icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    int activeIndex = _destinations.indexWhere((item) => location.startsWith(item.path));
    if (activeIndex < 0) activeIndex = 0;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Color(0xFFF2F4F7), width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_destinations.length, (index) {
              final item = _destinations[index];
              final isSelected = activeIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => context.go(item.path),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: isSelected ? AppColors.primary : AppColors.textTertiary,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
