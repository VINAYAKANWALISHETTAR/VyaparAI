import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
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
    final auth = ref.watch(authProvider);
    final currentLang = ref.watch(languageProvider);

    final userEmail = auth.user?.email ?? '';
    final userName = (auth.user?.name.isNotEmpty == true && auth.user!.name != userEmail)
        ? auth.user!.name
        : (userEmail.isNotEmpty ? userEmail.split('@').first : 'User');
    const bizName = 'Business Owner';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1E293B)),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                        ),
                        const SizedBox(height: 2),
                        Text(
                          bizName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          userEmail,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
                    onPressed: () => _showBusinessProfileModal(context, auth),
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
                    title: 'Business Profile',
                    onTap: () => _showBusinessProfileModal(context, auth),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.language_outlined,
                    title: 'Language',
                    trailingText: '${currentLang.name} (${currentLang.nativeName})',
                    onTap: () => _showLanguageModal(context, currentLang),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.notifications_none_outlined,
                    title: 'Notifications',
                    onTap: () => context.push('/app/notifications'),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.shield_outlined,
                    title: 'Data & Privacy',
                    onTap: () => _showPrivacyDialog(context),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.card_membership_outlined,
                    title: 'Subscription',
                    trailingBadge: 'Pro Plan',
                    onTap: () => _showSubscriptionModal(context),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.help_outline,
                    title: 'Help & Support',
                    onTap: () => _showHelpSupportModal(context),
                  ),
                  _buildDivider(),
                  _buildSettingItem(
                    icon: Icons.logout,
                    title: 'Logout',
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
            const Center(
              child: Text(
                'VyaparAI v1.0.0 • Made with ❤️ for Indian MSMEs',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
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
                    const Text(
                      'Select Language',
                      style: TextStyle(
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Language switched to ${lang.name} (${lang.nativeName})'),
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

  void _showBusinessProfileModal(BuildContext context, AuthState auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.storefront, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Business Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileRow('Business Name', 'My Vyapar Store'),
            _buildProfileRow('Owner', auth.user?.name ?? 'Business Owner'),
            _buildProfileRow('Email', auth.user?.email ?? '—'),
            _buildProfileRow('Currency', 'INR (₹)'),
            _buildProfileRow('Status', 'Verified & Active'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  void _showSubscriptionModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.card_membership, color: AppColors.primary),
            SizedBox(width: 8),
            Text('VyaparAI Pro Plan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Your subscription is active.', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            SizedBox(height: 10),
            Text('✓ Unlimited AI Copilot & Voice queries'),
            SizedBox(height: 4),
            Text('✓ Smart WhatsApp & SMS payment reminders'),
            SizedBox(height: 4),
            Text('✓ Automated OCR bill & receipt scanning'),
            SizedBox(height: 4),
            Text('✓ Predictive 30-day cash flow projections'),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Awesome'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Data & Privacy'),
        content: const Text(
          'Your financial data is encrypted in transit (TLS) and stored securely in MongoDB with JWT role-based access. Your invoices and accounts are strictly private to your registered business.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showHelpSupportModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Need help managing your accounts or invoices?'),
            SizedBox(height: 10),
            Text('📧 support@vyapar.ai', style: TextStyle(fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('📞 +91 8000-VYAPAR (Toll Free)', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
