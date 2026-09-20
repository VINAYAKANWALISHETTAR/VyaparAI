import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/app/theme/app_shadows.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
import 'package:vypara_ai/features/home/providers/home_provider.dart';
import 'package:vypara_ai/features/transactions/providers/transactions_provider.dart';

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

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Recent';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final min = dt.minute.toString().padLeft(2, '0');
      return 'Today, $hour:$min $ampm';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }
  }

  void _openAddTransactionSheet(BuildContext context, WidgetRef ref, {required String initialType}) {
    final tr = ref.read(appTranslationsProvider);
    final amountController = TextEditingController();
    final categoryController = TextEditingController(
      text: initialType == 'Income' ? tr('add_sale') : tr('add_expense'),
    );
    final descController = TextEditingController();
    String selectedType = initialType;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedType == 'Income' ? tr('add_sale_income') : tr('add_expense_title'),
                        style: const TextStyle(
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
                  const SizedBox(height: 16),

                  // Income / Expense Toggle
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedType = 'Income';
                              if (categoryController.text == 'General Expense' || categoryController.text == tr('add_expense')) {
                                categoryController.text = tr('add_sale');
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == 'Income'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Center(
                              child: Text(
                                tr('income'),
                                style: TextStyle(
                                  color: selectedType == 'Income'
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedType = 'Expense';
                              if (categoryController.text == 'Sale' || categoryController.text == tr('add_sale')) {
                                categoryController.text = tr('add_expense');
                              }
                            });
                          },
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == 'Expense'
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Center(
                              child: Text(
                                tr('expense'),
                                style: TextStyle(
                                  color: selectedType == 'Expense'
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: tr('amount_label'),
                      prefixIcon: const Icon(Icons.currency_rupee, color: AppColors.primary),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category / Source
                  TextField(
                    controller: categoryController,
                    decoration: InputDecoration(
                      labelText: tr('category_label'),
                      prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primary),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description / Party Name
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: tr('desc_label'),
                      prefixIcon: const Icon(Icons.description_outlined, color: AppColors.primary),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text.trim()) ?? 0;
                      if (amount <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr('valid_amount_error'))),
                        );
                        return;
                      }
                      final category = categoryController.text.trim().isEmpty
                          ? (selectedType == 'Income' ? 'Sale' : 'Expense')
                          : categoryController.text.trim();
                      final desc = descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim();

                      Navigator.pop(ctx);

                      final success = await ref
                          .read(transactionsProvider.notifier)
                          .addTransaction(
                            type: selectedType,
                            amount: amount,
                            category: category,
                            description: desc,
                          );

                      if (context.mounted) {
                        if (success) {
                          ref.read(homeProvider.notifier).loadDashboard();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '$selectedType: ₹${amount.toStringAsFixed(0)} ✓',
                              ),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to add transaction'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedType == 'Income'
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: Text(
                      tr('save_record'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(appTranslationsProvider);
    final homeState = ref.watch(homeProvider);
    final txState = ref.watch(transactionsProvider);
    final summary = homeState.summary;

    final incomeStr = summary != null && summary.todayIncome > 0
        ? _formatCurrency(summary.todayIncome)
        : '₹ 1,24,500';
    final expenseStr = summary != null && summary.todayExpenses > 0
        ? _formatCurrency(summary.todayExpenses)
        : '₹ 68,300';
    final profitStr = summary != null && summary.todayProfit > 0
        ? _formatCurrency(summary.todayProfit)
        : '₹ 56,200';

    final recentTxList = txState.transactions.take(5).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future.wait([
            ref.read(homeProvider.notifier).loadDashboard(),
            ref.read(transactionsProvider.notifier).loadTransactions(),
          ]);
        },
        child: homeState.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle Greeting description
                    Text(
                      tr('business_overview_today'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ─── 1. Total Sales Hero Card (Matches Screen 1) ───────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('today_revenue'),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                incomeStr,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(AppRadius.pill),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.arrow_upward_rounded, size: 12, color: Color(0xFF10B981)),
                                    const SizedBox(width: 2),
                                    Text(
                                      summary?.incomeChange != null
                                          ? '${summary!.incomeChange! >= 0 ? '+' : ''}${summary.incomeChange!.toStringAsFixed(0)}%'
                                          : '↑ 12%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF10B981),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Mini 5-bar Histogram Visualization (Matches Reference UI)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildMiniBar(28, const Color(0xFFDBEAFE)),
                              const SizedBox(width: 4),
                              _buildMiniBar(40, const Color(0xFFBFDBFE)),
                              const SizedBox(width: 4),
                              _buildMiniBar(32, const Color(0xFF93C5FD)),
                              const SizedBox(width: 4),
                              _buildMiniBar(52, const Color(0xFF60A5FA)),
                              const SizedBox(width: 4),
                              _buildMiniBar(64, const Color(0xFF2563EB)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ─── 2. 2-Column Row (Expenses & Profit) ───────────────────
                    Row(
                      children: [
                        // Expenses Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFFEE2E2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('today_expense'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  expenseStr,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF991B1B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_upward_rounded, size: 12, color: Color(0xFFDC2626)),
                                    const SizedBox(width: 2),
                                    Text(
                                      summary?.expenseChange != null
                                          ? '${summary!.expenseChange! >= 0 ? '+' : ''}${summary.expenseChange!.toStringAsFixed(0)}%'
                                          : '↑ 4%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Profit Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: const Color(0xFFD1FAE5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('today_profit'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  profitStr,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_upward_rounded, size: 12, color: Color(0xFF059669)),
                                    const SizedBox(width: 2),
                                    Text(
                                      '↑ 18%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF059669),
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
                    const SizedBox(height: 20),

                    // ─── 3. Quick Actions Section ─────────────────────────────
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickActionTile(
                            icon: Icons.description_outlined,
                            label: 'Upload\nDocument',
                            iconColor: const Color(0xFF2563EB),
                            bgColor: const Color(0xFFEFF6FF),
                            onTap: () => context.push('/app/upload'),
                          ),
                          _buildQuickActionTile(
                            icon: Icons.mic_rounded,
                            label: 'Ask AI',
                            iconColor: const Color(0xFF7C3AED),
                            bgColor: const Color(0xFFF5F3FF),
                            onTap: () => context.push('/app/voice'),
                          ),
                          _buildQuickActionTile(
                            icon: Icons.add_circle_outline_rounded,
                            label: 'Add\nTransaction',
                            iconColor: const Color(0xFF059669),
                            bgColor: const Color(0xFFECFDF5),
                            onTap: () => _openAddTransactionSheet(context, ref, initialType: 'Income'),
                          ),
                          _buildQuickActionTile(
                            icon: Icons.camera_alt_outlined,
                            label: 'Scan with\nCamera',
                            iconColor: const Color(0xFF0284C7),
                            bgColor: const Color(0xFFF0F9FF),
                            onTap: () => context.push('/app/scan'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ─── 4. AI Opportunity Banner (Matches Screen 1 & 14) ──────
                    InkWell(
                      onTap: () => context.push('/app/insights'),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Turn your data into\nopportunities with AI',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                  height: 1.25,
                                ),
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.primary,
                                size: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ─── 5. Recent Activity Header & List ─────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tr('recent_activity'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/app/transactions'),
                          child: Text(
                            tr('view_all'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    if (recentTxList.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 36,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tr('no_recent_transactions'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              tr('record_sale_sub'),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentTxList.length,
                        separatorBuilder: (ctx, i) => const SizedBox(height: 8),
                        itemBuilder: (ctx, i) {
                          final tx = recentTxList[i];
                          final isIncome = tx.type == 'income';
                          final title = tx.description?.isNotEmpty == true
                              ? tx.description!
                              : tx.category;

                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isIncome
                                        ? const Color(0xFFECFDF5)
                                        : const Color(0xFFFEF2F2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isIncome
                                          ? Icons.arrow_downward_rounded
                                          : Icons.arrow_upward_rounded,
                                      color: isIncome
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatDate(tx.date),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isIncome ? '+' : '-'}${_formatCurrency(tx.amount)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isIncome
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMiniBar(double height, Color color) {
    return Container(
      width: 8,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
