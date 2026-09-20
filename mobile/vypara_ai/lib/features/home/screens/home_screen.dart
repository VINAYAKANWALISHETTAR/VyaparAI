import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/app/theme/app_shadows.dart';

class HomeScreenPlaceholder extends StatelessWidget {
  const HomeScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // Top Metric Cards (Income & Expenses)
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
                        const Text(
                          '₹ 18,500',
                          style: TextStyle(
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
                        Row(
                          children: const [
                            Icon(Icons.arrow_upward, size: 12, color: Color(0xFF0F764F)),
                            SizedBox(width: 2),
                            Text(
                              '12%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F764F),
                              ),
                            ),
                          ],
                        ),
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
                        const Text(
                          '₹ 6,200',
                          style: TextStyle(
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
                        Row(
                          children: const [
                            Icon(Icons.arrow_downward, size: 12, color: Color(0xFFD92D20)),
                            SizedBox(width: 2),
                            Text(
                              '4%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD92D20),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Today's Profit Card
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
                    children: const [
                      Text(
                        '₹ 12,300',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
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

            // Center Voice Assistant / AI Mic Wave Button (Screen 3 & 4)
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => context.push('/app/voice'),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer animated soundwaves
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
                        // Center Circular Button
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

            // Quick Actions Row (Upload, Camera, Record, More)
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
