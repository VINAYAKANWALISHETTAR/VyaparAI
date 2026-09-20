import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/features/auth/presentation/providers/auth_provider.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final auth = ref.watch(authProvider);
    final userName = auth.user?.name ?? '';
    final userEmail = auth.user?.email ?? '';

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
            // ── App Branding + User Info ────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
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
                    children: [
                      const Text(
                        'VyaparAI',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
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

            // ── User profile card ───────────────────────────────────────────
            if (userName.isNotEmpty || userEmail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (userName.isNotEmpty)
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (userEmail.isNotEmpty)
                              Text(
                                userEmail,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),
            const Divider(color: Color(0xFFF1F5F9), thickness: 1),
            const SizedBox(height: 4),

            // ── Navigation items ───────────────────────────────────────────
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

            // ── Logout ─────────────────────────────────────────────────────
            const Divider(color: Color(0xFFF1F5F9), thickness: 1, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: const Icon(
                  Icons.logout_rounded,
                  size: 22,
                  color: AppColors.error,
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context); // close drawer first
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
            ),
            const SizedBox(height: 8),
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
        tileColor: isActive
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.transparent,
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
