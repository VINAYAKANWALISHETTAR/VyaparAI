import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/app/theme/app_shadows.dart';
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
    final amountController = TextEditingController();
    final categoryController = TextEditingController(
      text: initialType == 'Income' ? 'Sale' : 'General Expense',
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
                        selectedType == 'Income' ? 'Add Sale / Income' : 'Add Expense',
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
                              if (categoryController.text == 'General Expense') {
                                categoryController.text = 'Sale';
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
                                'Income',
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
                              if (categoryController.text == 'Sale') {
                                categoryController.text = 'General Expense';
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
                                'Expense',
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
                      labelText: 'Amount (₹)',
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
                      labelText: 'Category / Source',
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
                      labelText: 'Description / Customer Name (Optional)',
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
                          const SnackBar(content: Text('Please enter a valid amount')),
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
                                '$selectedType of ₹${amount.toStringAsFixed(0)} added successfully!',
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
                    child: const Text(
                      'Save Record',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
    final homeState = ref.watch(homeProvider);
    final txState = ref.watch(transactionsProvider);
    final summary = homeState.summary;

    final incomeStr = summary != null ? _formatCurrency(summary.todayIncome) : '₹ 0';
    final expenseStr = summary != null ? _formatCurrency(summary.todayExpenses) : '₹ 0';
    final profitStr = summary != null ? _formatCurrency(summary.todayProfit) : '₹ 0';
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
                              child: const Text(
                                'Retry',
                                style: TextStyle(fontSize: 12, color: Color(0xFFD92D20)),
                              ),
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
                    const SizedBox(height: 14),

                    // Top Metric Cards (Income & Expenses) - Screen 2 / 3
                    Row(
                      children: [
                        // Today's Income / Revenue
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8F0),
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              border: Border.all(color: const Color(0xFFD1FADF), width: 1),
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
                                  "Today Revenue",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF0F764F),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (summary?.incomeChange != null) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        summary!.incomeChange! >= 0
                                            ? Icons.arrow_upward_rounded
                                            : Icons.arrow_downward_rounded,
                                        size: 13,
                                        color: summary.incomeChange! >= 0
                                            ? const Color(0xFF0F764F)
                                            : const Color(0xFFD92D20),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${summary.incomeChange! >= 0 ? '+' : ''}${summary.incomeChange!.toStringAsFixed(0)}%',
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
                              border: Border.all(color: const Color(0xFFFECDCA), width: 1),
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
                                  "Today Expense",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFD92D20),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (summary?.expenseChange != null) ...[
                                  Row(
                                    children: [
                                      Icon(
                                        summary!.expenseChange! >= 0
                                            ? Icons.arrow_upward_rounded
                                            : Icons.arrow_downward_rounded,
                                        size: 13,
                                        color: summary.expenseChange! >= 0
                                            ? const Color(0xFFD92D20)
                                            : const Color(0xFF0F764F),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        '${summary.expenseChange! >= 0 ? '+' : ''}${summary.expenseChange!.toStringAsFixed(0)}%',
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

                    // Today's Profit Card - Screen 2 / 3
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: AppShadows.subtle,
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
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Today's Profit",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: const Icon(
                              Icons.bar_chart_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Center Glowing Voice Assistant Button - Screen 2 / 3
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => context.push('/app/voice'),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        const Color(0xFF2155F5).withValues(alpha: 0.15),
                                        const Color(0xFF6C3EF0).withValues(alpha: 0.05),
                                        Colors.transparent,
                                      ],
                                      stops: const [0.3, 0.7, 1.0],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF2155F5), Color(0xFF6C3EF0)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF2155F5).withValues(alpha: 0.4),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.mic_rounded,
                                    color: Colors.white,
                                    size: 34,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Tap to talk with VyaparaAI',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Quick Actions Section (4 Round Buttons: Add Sale, Add Expense, Upload, Ask AI)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRoundActionTile(
                            icon: Icons.add_rounded,
                            label: 'Add Sale',
                            iconColor: const Color(0xFF10B981),
                            bgColor: const Color(0xFFE8F8F0),
                            onTap: () => _openAddTransactionSheet(context, ref, initialType: 'Income'),
                          ),
                          _buildRoundActionTile(
                            icon: Icons.remove_rounded,
                            label: 'Add Expense',
                            iconColor: const Color(0xFFEF4444),
                            bgColor: const Color(0xFFFEECEB),
                            onTap: () => _openAddTransactionSheet(context, ref, initialType: 'Expense'),
                          ),
                          _buildRoundActionTile(
                            icon: Icons.cloud_upload_outlined,
                            label: 'Upload',
                            iconColor: const Color(0xFF2155F5),
                            bgColor: const Color(0xFFEFF6FF),
                            onTap: () => context.push('/app/upload'),
                          ),
                          _buildRoundActionTile(
                            icon: Icons.auto_awesome_rounded,
                            label: 'Ask AI',
                            iconColor: const Color(0xFF7C3AED),
                            bgColor: const Color(0xFFF5F3FF),
                            onTap: () => context.push('/app/voice'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Recent Activity Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent Activity',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/app/transactions'),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Recent Activity List
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
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'No recent transactions',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Record a sale or upload an invoice to see activity',
                              style: TextStyle(
                                fontSize: 12,
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
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isIncome
                                        ? const Color(0xFFE8F8F0)
                                        : const Color(0xFFFEECEB),
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
                                      size: 20,
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
                                          fontSize: 14,
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
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildRoundActionTile({
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
