import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppBottomNav extends ConsumerWidget {
  const AppBottomNav({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHome = location == '/app/home' || location == '/';
    final isTransactions = location.startsWith('/app/transactions') || location.startsWith('/app/records');
    final isReports = location.startsWith('/app/reports');
    final isSettings = location.startsWith('/app/settings');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1.2),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Navigation Items Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Home
                    _buildNavItem(
                      icon: isHome ? Icons.home_rounded : Icons.home_outlined,
                      label: 'Home',
                      isSelected: isHome,
                      showIndicatorDot: isHome,
                      onTap: () => context.go('/app/home'),
                    ),
                    // Transactions
                    _buildNavItem(
                      icon: Icons.receipt_long_rounded,
                      label: 'Transactions',
                      isSelected: isTransactions,
                      showIndicatorDot: isTransactions,
                      onTap: () => context.go('/app/transactions'),
                    ),
                    // Gap for Center Elevated AI Mic Button
                    const SizedBox(width: 64),
                    // Reports
                    _buildNavItem(
                      icon: Icons.bar_chart_rounded,
                      label: 'Reports',
                      isSelected: isReports,
                      showIndicatorDot: isReports,
                      onTap: () => context.go('/app/reports'),
                    ),
                    // Settings
                    _buildNavItem(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      isSelected: isSettings,
                      showIndicatorDot: isSettings,
                      onTap: () => context.go('/app/settings'),
                    ),
                  ],
                ),
              ),

              // Prominent Elevated Center AI Microphone Button
              Positioned(
                top: -22,
                child: GestureDetector(
                  onTap: () => context.push('/app/voice'),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF6366F1), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.40),
                          blurRadius: 18,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white,
                        width: 3.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.mic_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool showIndicatorDot,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 2),
            // Blue indicator dot for active item
            if (isSelected && showIndicatorDot)
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
