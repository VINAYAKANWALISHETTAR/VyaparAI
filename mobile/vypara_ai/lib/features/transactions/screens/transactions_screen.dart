import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/app/theme/app_shadows.dart';
import 'package:vypara_ai/features/home/providers/home_provider.dart';
import 'package:vypara_ai/features/transactions/providers/transactions_provider.dart';

class TransactionsScreenPlaceholder extends ConsumerStatefulWidget {
  const TransactionsScreenPlaceholder({super.key});

  @override
  ConsumerState<TransactionsScreenPlaceholder> createState() =>
      _TransactionsScreenPlaceholderState();
}

class _TransactionsScreenPlaceholderState
    extends ConsumerState<TransactionsScreenPlaceholder> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    final str = amount.toStringAsFixed(0);
    if (str.length > 3) {
      String lastThree = str.substring(str.length - 3);
      String remaining = str.substring(0, str.length - 3);
      String formatted = '';
      while (remaining.length > 2) {
        formatted = ',${remaining.substring(remaining.length - 2)}$formatted';
        remaining = remaining.substring(0, remaining.length - 2);
      }
      return '₹$remaining$formatted,$lastThree';
    }
    return '₹$str';
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
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }
  }

  void _openAddTransactionSheet() {
    final amountController = TextEditingController();
    final categoryController = TextEditingController(text: 'Payment Received');
    final descController = TextEditingController();
    String selectedType = 'Income';

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
                      const Text(
                        'Add Transaction',
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
                  const SizedBox(height: 16),

                  // Income / Expense Toggle
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setModalState(() => selectedType = 'Income'),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == 'Income'
                                  ? AppColors.success
                                  : AppColors.background,
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
                          onTap: () => setModalState(() => selectedType = 'Expense'),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == 'Expense'
                                  ? AppColors.error
                                  : AppColors.background,
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
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      hintText: 'e.g. 5000',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category
                  TextField(
                    controller: categoryController,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      hintText: 'e.g. Sales, Purchase, Utility',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description / Contact (Optional)',
                      hintText: 'Enter party name or description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                      if (amount <= 0) return;
                      Navigator.pop(ctx);

                      await ref.read(transactionsProvider.notifier).addTransaction(
                            type: selectedType,
                            amount: amount,
                            category: categoryController.text.trim(),
                            description: descController.text.trim().isNotEmpty
                                ? descController.text.trim()
                                : null,
                          );

                      // Also refresh dashboard metrics
                      ref.read(homeProvider.notifier).loadDashboard();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save Transaction', style: TextStyle(fontWeight: FontWeight.bold)),
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
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionsProvider);
    final filters = ['All', 'Income', 'Expense', 'Pending'];

    final displayList = txState.filteredTransactions;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Search & Filter Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surface,
            child: Column(
              children: [
                // Search Input
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        ref.read(transactionsProvider.notifier).search(val),
                    decoration: const InputDecoration(
                      hintText: 'Search transactions...',
                      hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: AppColors.textTertiary, size: 20),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filters Row - Screen 7
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filters.map((f) {
                      final isSelected = txState.activeFilter == f;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () =>
                              ref.read(transactionsProvider.notifier).setFilter(f),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.outline,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              f,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Transactions List - Screen 7
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () =>
                  ref.read(transactionsProvider.notifier).loadTransactions(),
              child: txState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : txState.error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.wifi_off_outlined, size: 48, color: AppColors.textTertiary),
                                const SizedBox(height: 12),
                                Text(
                                  txState.error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () => ref.read(transactionsProvider.notifier).loadTransactions(),
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Retry'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: const StadiumBorder(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : displayList.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textTertiary),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No transactions yet',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Add your first transaction to get started tracking income and expenses.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    ElevatedButton.icon(
                                      onPressed: _openAddTransactionSheet,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Add Transaction'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        shape: const StadiumBorder(),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: displayList.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final item = displayList[index];
                                final isIncome = item.type == 'income';

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    boxShadow: AppShadows.subtle,
                                  ),
                                  child: Row(
                                    children: [
                                      // Type / Category Icon
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isIncome
                                              ? const Color(0xFFE8F8F0)
                                              : const Color(0xFFEFF4FF),
                                          borderRadius: BorderRadius.circular(AppRadius.md),
                                        ),
                                        child: Icon(
                                          isIncome
                                              ? Icons.arrow_downward_rounded
                                              : Icons.arrow_upward_rounded,
                                          color: isIncome
                                              ? const Color(0xFF0F764F)
                                              : AppColors.primary,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Category and Description
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.category,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.description ?? 'General',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Amount and Date
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            _formatAmount(item.amount),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: isIncome
                                                  ? const Color(0xFF0F764F)
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _formatDate(item.date),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ),

          // Bottom "+ Add Transaction" Button - Screen 7
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _openAddTransactionSheet,
                icon: const Icon(Icons.add, size: 20, color: Colors.white),
                label: const Text(
                  'Add Transaction',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
