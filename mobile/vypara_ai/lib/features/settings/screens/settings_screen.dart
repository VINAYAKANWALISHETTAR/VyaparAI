import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
import 'package:vypara_ai/core/providers/language_provider.dart';
import 'package:vypara_ai/core/widgets/app_card.dart';
import 'package:vypara_ai/features/auth/presentation/providers/auth_provider.dart';

class SettingsScreenPlaceholder extends ConsumerStatefulWidget {
  const SettingsScreenPlaceholder({super.key});

  @override
  ConsumerState<SettingsScreenPlaceholder> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreenPlaceholder> {
  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(appTranslationsProvider);
    final auth = ref.watch(authProvider);
    final currentLang = ref.watch(languageProvider);

    final userEmail = auth.user?.email ?? '';
    final userName = (auth.user?.name.isNotEmpty == true && auth.user!.name != userEmail)
        ? auth.user!.name
        : (userEmail.isNotEmpty ? userEmail.split('@').first : 'User');
    final bizName = tr('business_account');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 110),
      child: Column(
          children: [
            // User Profile Card matching Screen 14
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'M',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bizName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                    onPressed: () => context.push('/app/profile'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Settings Options List matching Screen 14
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildSettingItem(
                    icon: Icons.storefront_outlined,
                    title: tr('business_profile'),
                    onTap: () => context.push('/app/profile'),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.language_outlined,
                    title: tr('language'),
                    trailingText: '${currentLang.name} (${currentLang.nativeName})',
                    onTap: () => _showLanguageModal(context, currentLang),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.mic_none_rounded,
                    title: tr('voice_assistant'),
                    trailingBadge: tr('active'),
                    onTap: () => context.push('/app/voice'),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.auto_awesome,
                    title: tr('ai_assistant'),
                    trailingBadge: tr('new_badge'),
                    onTap: () => context.push('/app/insights'),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: tr('auto_fetch_messages'),
                    trailingBadge: tr('connected'),
                    onTap: () => context.push('/app/messages'),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.notifications_none_outlined,
                    title: tr('notifications_alerts'),
                    onTap: () => context.push('/app/notifications'),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.shield_outlined,
                    title: tr('data_privacy'),
                    onTap: () => _showPrivacyDialog(context),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.card_membership_outlined,
                    title: tr('subscription'),
                    trailingBadge: tr('pro_plan'),
                    onTap: () => _showSubscriptionModal(context),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.help_outline,
                    title: tr('help_support'),
                    onTap: () => _showHelpSupportModal(context),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.logout,
                    title: tr('logout'),
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    showChevron: false,
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App version footer
            Center(
              child: Text(
                tr('app_version_info'),
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    String? trailingText,
    String? trailingBadge,
    Color? iconColor,
    Color? textColor,
    bool showChevron = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor ?? const Color(0xFF64748B)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? const Color(0xFF1E293B),
                ),
              ),
            ),
            if (trailingText != null)
              Text(
                trailingText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            if (trailingBadge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  trailingBadge,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            if (showChevron) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, size: 18, color: Color(0xFF94A3B8)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 0.5, color: Color(0xFFF1F5F9), indent: 52);
  }

  // Screen 14: Language Selection Modal
  void _showLanguageModal(BuildContext context, LanguageModel currentLang) {
    final tr = ref.read(appTranslationsProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('select_language'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 8),
                ...supportedLanguages.map((lang) {
                  final isSelected = lang.code == currentLang.code;
                  return InkWell(
                    onTap: () {
                      ref.read(languageProvider.notifier).setLanguage(lang);
                      Navigator.pop(ctx);
                      final updatedTr = ref.read(appTranslationsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(updatedTr('language_switched', {
                            'name': lang.name,
                            'nativeName': lang.nativeName,
                          })),
                          backgroundColor: AppColors.primary,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          Text(
                            lang.nativeName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.primary : const Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            lang.name,
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                            ),
                          ),
                          const Spacer(),
                          if (isSelected)
                            const Icon(Icons.check, color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }


  void _showSubscriptionModal(BuildContext context) {
    final tr = ref.read(appTranslationsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        title: Row(
          children: [
            const Icon(Icons.card_membership, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tr('subscription'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tr('subscription_active'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Text(tr('feature_ai_copilot')),
              const SizedBox(height: 4),
              Text(tr('feature_smart_reminders')),
              const SizedBox(height: 4),
              Text(tr('feature_ocr_scanning')),
              const SizedBox(height: 4),
              Text(tr('feature_cashflow_projections')),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('awesome')),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    final tr = ref.read(appTranslationsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('data_privacy')),
        content: Text(
          tr('security_compliance_desc'),
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('ok'))),
        ],
      ),
    );
  }

  void _showHelpSupportModal(BuildContext context) {
    final tr = ref.read(appTranslationsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(tr('help_support')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr('need_help_title')),
            const SizedBox(height: 10),
            const Text('📧 support@vyapar.ai', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text('📞 +91 8000-VYAPAR (${tr('toll_free')})', style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('close'))),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final tr = ref.read(appTranslationsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(tr('logout')),
        content: Text(tr('confirm_logout')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: Text(tr('logout')),
          ),
        ],
      ),
    );
  }
}
