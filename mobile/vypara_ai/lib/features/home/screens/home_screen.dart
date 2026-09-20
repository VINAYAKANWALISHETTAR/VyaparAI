import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/app/theme/app_shadows.dart';
import 'package:vypara_ai/features/home/providers/home_provider.dart';

class HomeScreenPlaceholder extends ConsumerWidget {
  const HomeScreenPlaceholder({super.key});

  String _formatCurrency(double amount) {
    if (amount == 0) return '₹ 0';
    final parts = amount.toStringAsFixed(0).split('.');
    String intPart = parts[0];
    if (intPart.length > 3) {
      String lastThree = intPart.substring(intPart.length - 3);
      String remaining = intPart.substring(0, intPart.length - 3);
      String formatted = '';
      while (remaining.length > 2) {
        formatted = ',${remaining.substring(remaining.length - 2)}$formatted';
        remaining = remaining.substring(0, remaining.length - 2);
      }
      intPart = '$remaining$formatted,$lastThree';
    }
    return '₹ $intPart';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeProvider);
    final summary = homeState.summary;

    final incomeStr = summary != null ? _formatCurrency(summary.todayIncome) : '₹ 0';
    final expenseStr = summary != null ? _formatCurrency(summary.todayExpenses) : '₹ 0';
    final profitStr = summary != null ? _formatCurrency(summary.todayProfit) : '₹ 0';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(homeProvider.notifier).loadDashboard(),
        child: homeState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error Banner
                    if (homeState.error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEECEB),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFD92D20), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                homeState.error!,
                                style: const TextStyle(fontSize: 13, color: Color(0xFFD92D20)),
                              ),
                            ),
                            TextButton(
                              onPressed: () => ref.read(homeProvider.notifier).loadDashboard(),
                              child: const Text('Retry', style: TextStyle(fontSize: 12, color: Color(0xFFD92D20))),
                            ),
                          ],
                        ),
                      ),

                    // Subtitle
                    const Text(
                      "Here's your business overview for today",
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Top Metric Cards (Income & Expenses) - Screen 3
                    Row(
                      children: [
                        // Today's Income
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8F0),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  incomeStr,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F764F),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Today's Income",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (summary?.incomeChange != null) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        summary!.incomeChange! >= 0
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        size: 12,
                                        color: summary.incomeChange! >= 0
                                            ? const Color(0xFF0F764F)
                                            : const Color(0xFFD92D20),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${summary.incomeChange!.abs().toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: summary.incomeChange! >= 0
                                              ? const Color(0xFF0F764F)
                                              : const Color(0xFFD92D20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  const Text(
                                    '—',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Today's Expenses
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEECEB),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expenseStr,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFD92D20),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Today's Expenses",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (summary?.expenseChange != null) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        // Expenses going UP is bad (red ↑), going DOWN is good (green ↓)
                                        summary!.expenseChange! >= 0
                                            ? Icons.arrow_upward
                                            : Icons.arrow_downward,
                                        size: 12,
                                        color: summary.expenseChange! >= 0
                                            ? const Color(0xFFD92D20)
                                            : const Color(0xFF0F764F),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${summary.expenseChange!.abs().toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: summary.expenseChange! >= 0
                                              ? const Color(0xFFD92D20)
                                              : const Color(0xFF0F764F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  const Text(
                                    '—',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Today's Profit Card - Screen 3
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadows.card,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profitStr,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Today's Profit",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(Icons.bar_chart, color: AppColors.primary, size: 24),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Center Voice Assistant Button - Screen 3 & 4
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => context.push('/app/voice'),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 170,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF2155F5).withAlpha(15),
                                        const Color(0xFF6C3EF0).withAlpha(35),
                                        const Color(0xFF2155F5).withAlpha(15),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(35),
                                  ),
                                ),
                                Container(
                                  width: 68,
                                  height: 68,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF2155F5), Color(0xFF6C3EF0)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2155F5).withAlpha(80),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.mic,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tap to talk with VyaparaAI',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Quick Actions Row (Upload, Camera, Record, More) - Screen 3
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickActionButton(
                            icon: Icons.upload_outlined,
                            label: 'Upload',
                            onTap: () => context.push('/app/upload'),
                          ),
                          _buildQuickActionButton(
                            icon: Icons.camera_alt_outlined,
                            label: 'Camera',
                            onTap: () => context.push('/app/upload'),
                          ),
                          _buildQuickActionButton(
                            icon: Icons.mic_none_outlined,
                            label: 'Record',
                            iconColor: AppColors.error,
                            onTap: () => context.push('/app/voice'),
                          ),
                          _buildQuickActionButton(
                            icon: Icons.more_horiz,
                            label: 'More',
                            onTap: () => _showMoreMenu(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'More Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.receipt_long, color: AppColors.primary),
                  title: const Text('Transactions & Invoices'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/app/transactions');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.people, color: AppColors.primary),
                  title: const Text('Customers & Suppliers'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/app/customers');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.trending_up, color: AppColors.primary),
                  title: const Text('Cash Flow Forecast'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/app/cash-flow');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.alarm, color: AppColors.primary),
                  title: const Text('Payment Reminders'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/app/reminders');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
