import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
import 'package:vypara_ai/core/widgets/app_card.dart';
import 'package:vypara_ai/features/auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(appTranslationsProvider);
    final auth = ref.watch(authProvider);
    final userEmail = auth.user?.email ?? '';
    final userName = (auth.user?.name.isNotEmpty == true && auth.user!.name != userEmail)
        ? auth.user!.name
        : (userEmail.isNotEmpty ? userEmail.split('@').first : tr('business_account'));
    final bizName = auth.user?.name.isNotEmpty == true
        ? '${auth.user!.name}\'s Business'
        : tr('kirana_store');

    final initials = userName.isNotEmpty
        ? userName.substring(0, 1).toUpperCase()
        : 'V';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          tr('business_profile'),
          style: const TextStyle(
            fontSize: 20,
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
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card with Avatar & Primary Info
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified,
                                color: AppColors.primary,
                                size: 18,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bizName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            userEmail.isNotEmpty ? userEmail : '—',
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
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Business Information Section
              _buildSectionTitle(tr('business_profile')),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildInfoRow(tr('business_name'), bizName),
                    const Divider(height: 16, thickness: 0.5, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(tr('category'), 'Retail & General Trade'),
                    const Divider(height: 16, thickness: 0.5, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(tr('currency'), 'INR (₹)'),
                    const Divider(height: 16, thickness: 0.5, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(tr('status'), tr('active'), isBadge: true),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Owner Details Section
              _buildSectionTitle('Owner Details'),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildInfoRow(tr('full_name'), userName),
                    const Divider(height: 16, thickness: 0.5, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(tr('email'), userEmail.isNotEmpty ? userEmail : '—'),
                    const Divider(height: 16, thickness: 0.5, color: Color(0xFFF1F5F9)),
                    _buildInfoRow('Role', 'Primary Administrator'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // VyaparAI Copilot & Services Section
              _buildSectionTitle('Services & Automation'),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildInfoRow(tr('voice_assistant'), tr('active'), isBadge: true),
                    const Divider(height: 16, thickness: 0.5, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(tr('ai_copilot'), tr('connected'), isBadge: true),
                    const Divider(height: 16, thickness: 0.5, color: Color(0xFFF1F5F9)),
                    _buildInfoRow(tr('auto_fetch_messages'), 'Realtime Listening', isBadge: true),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Subscription & Plan Section
              _buildSectionTitle(tr('subscription_plan')),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    _buildInfoRow('Current Plan', 'VyaparAI Pro'),
                    const Divider(height: 16, thickness: 0.5, color: Color(0xFFF1F5F9)),
                    _buildInfoRow('Status', tr('active'), isBadge: true),
                    const Divider(height: 16, thickness: 0.5, color: Color(0xFFF1F5F9)),
                    _buildInfoRow('App Version', 'v1.0.0 Production'),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF475569),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBadge = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: isBadge
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                : Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }
}
