import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
import 'package:vypara_ai/core/widgets/language_selector.dart';
import 'package:vypara_ai/core/widgets/notification_button.dart';
import 'package:vypara_ai/core/widgets/vyapar_ai_ribbon_logo.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(appTranslationsProvider);
    final location = GoRouterState.of(context).uri.path;
    final isHome = location == '/app/home' || location == '/';
    final isTransactions = location == '/app/transactions' || location == '/app/records';
    final showBrandedHeader = isHome || isTransactions;
    final auth = ref.watch(authProvider);
    final displayName = (auth.user?.name.isNotEmpty == true)
        ? auth.user!.name.split(' ').first
        : 'User';

    final canPop = Navigator.canPop(context);

    if (showBrandedHeader) {
      return AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 64,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Row(
          children: [
            // Hamburger squircle button
            Builder(
              builder: (ctx) => InkWell(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.menu_rounded,
                      color: Color(0xFF1E293B),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // VyaparAI Logo (Wordmark removed per user request, only logo retained)
            const VyaparAiRibbonLogo(
              size: 34,
              showWordmark: false,
            ),
          ],
        ),
        actions: showActions
            ? [
                const NotificationButton(),
                const SizedBox(width: 4),
                const LanguageSelector(),
                const SizedBox(width: 8),
                // Circular User Avatar with Online Dot
                GestureDetector(
                  onTap: () => context.push('/app/settings'),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'V',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -1,
                          bottom: -1,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ]
            : null,
      );
    }

    // Secondary Screen Header
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
      } else if (location.startsWith('/app/voice')) {
        displayTitle = tr('voice_assistant');
      }
    }

    final titleWidget = Column(
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

    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 64,
      leading: canPop
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
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
      title: titleWidget,
      titleSpacing: 0,
      actions: showActions
          ? [
              const NotificationButton(),
              const SizedBox(width: 4),
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
