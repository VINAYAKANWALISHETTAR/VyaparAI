import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Header matching Screen 15
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'V',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'VyaparAI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Your Business Partner',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFFF1F5F9), thickness: 1),
            const SizedBox(height: 4),

            // Drawer Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildMenuItem(
                    context: context,
                    icon: Icons.home_outlined,
                    label: 'Home',
                    route: '/app/home',
                    isActive: location == '/app/home',
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    label: 'Transactions',
                    route: '/app/transactions',
                    isActive: location.startsWith('/app/transactions'),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.bar_chart_outlined,
                    label: 'Reports',
                    route: '/app/reports',
                    isActive: location.startsWith('/app/reports'),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.people_outline,
                    label: 'Customers',
                    route: '/app/customers',
                    isActive: location.startsWith('/app/customers'),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.storefront_outlined,
                    label: 'Suppliers',
                    route: '/app/suppliers',
                    isActive: location.startsWith('/app/suppliers'),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Reminders',
                    route: '/app/reminders',
                    isActive: location.startsWith('/app/reminders'),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.file_upload_outlined,
                    label: 'Upload',
                    route: '/app/upload',
                    isActive: location.startsWith('/app/upload'),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.trending_up,
                    label: 'Cash Flow',
                    route: '/app/cash-flow',
                    isActive: location.startsWith('/app/cash-flow'),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.psychology_outlined,
                    label: 'AI Assistant',
                    route: '/app/ai',
                    isActive: location.startsWith('/app/ai'),
                  ),
                  _buildMenuItem(
                    context: context,
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    route: '/app/settings',
                    isActive: location.startsWith('/app/settings'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isActive ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
        leading: Icon(
          icon,
          size: 22,
          color: isActive ? AppColors.primary : const Color(0xFF64748B),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.primary : const Color(0xFF1E293B),
          ),
        ),
        onTap: () {
          Navigator.pop(context); // close drawer
          context.go(route);
        },
      ),
    );
  }
}
