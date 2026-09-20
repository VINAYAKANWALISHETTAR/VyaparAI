import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
import 'package:vypara_ai/core/widgets/language_selector.dart';
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

  String _getGreeting(String Function(String) tr) {
    final hour = DateTime.now().hour;
    if (hour < 12) return tr('good_morning');
    if (hour < 17) return tr('good_afternoon');
    return tr('good_evening');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(appTranslationsProvider);
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
            _getGreeting(tr),
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
      String displayTitle = title ?? 'VyaparAI';
      if (title == null) {
        if (location.startsWith('/app/reports')) {
          displayTitle = tr('reports');
        } else if (location.startsWith('/app/ai')) {
          displayTitle = tr('ai_copilot');
        } else if (location.startsWith('/app/records') ||
            location.startsWith('/app/transactions')) {
          displayTitle = tr('records');
        } else if (location.startsWith('/app/settings')) {
          displayTitle = tr('settings');
        } else if (location.startsWith('/app/cash-flow')) {
          displayTitle = tr('cash_flow');
        } else if (location.startsWith('/app/reminders')) {
          displayTitle = tr('reminders');
        } else if (location.startsWith('/app/customers')) {
          displayTitle = tr('customers');
        } else if (location.startsWith('/app/suppliers')) {
          displayTitle = tr('suppliers');
        } else if (location.startsWith('/app/upload')) {
          displayTitle = tr('upload');
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
