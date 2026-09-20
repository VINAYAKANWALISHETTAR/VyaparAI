import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/core/widgets/language_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/features/auth/presentation/providers/auth_provider.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.title,
    this.subtitle,
    this.showActions = true,
  });

  final String? title;
  final String? subtitle;
  final bool showActions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isHome = location == '/app/home' || location == '/';
    final auth = ref.watch(authProvider);
    final displayName = (auth.user?.name.isNotEmpty == true)
        ? auth.user!.name.split(' ').first
        : 'User';

    Widget titleWidget;
    if (isHome) {
      titleWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _getGreeting(),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$displayName \u{1F44B}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    } else {
      String displayTitle = title ?? 'VyparaAI';
      if (title == null) {
        if (location.startsWith('/app/reports')) {
          displayTitle = 'Reports';
        } else if (location.startsWith('/app/ai')) {
          displayTitle = 'AI Copilot';
        } else if (location.startsWith('/app/records') ||
            location.startsWith('/app/transactions')) {
          displayTitle = 'Transactions';
        } else if (location.startsWith('/app/settings')) {
          displayTitle = 'Settings';
        } else if (location.startsWith('/app/cash-flow')) {
          displayTitle = 'Cash Flow';
        } else if (location.startsWith('/app/reminders')) {
          displayTitle = 'Reminders';
        } else if (location.startsWith('/app/customers')) {
          displayTitle = 'Customers';
        } else if (location.startsWith('/app/suppliers')) {
          displayTitle = 'Suppliers';
        } else if (location.startsWith('/app/upload')) {
          displayTitle = 'Upload';
        }
      }

      titleWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            displayTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
        ],
      );
    }

    final canPop = Navigator.canPop(context);

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      leading: canPop
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: AppColors.textPrimary,
              ),
              onPressed: () => context.pop(),
            )
          : Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(
                  Icons.menu_rounded,
                  size: 24,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
      // Wrap title in an Expanded-friendly widget to prevent overflow
      title: titleWidget,
      titleSpacing: 0,
      actions: showActions
          ? [
              const LanguageSelector(),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => context.push('/app/settings'),
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF4FF),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD0E0FF),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ]
          : null,
    );
  }
}
