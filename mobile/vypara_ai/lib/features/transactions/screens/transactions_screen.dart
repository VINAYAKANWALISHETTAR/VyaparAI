import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/features/home/providers/home_provider.dart';
import 'package:vypara_ai/features/transactions/data/models/transaction_model.dart';
import 'package:vypara_ai/features/transactions/providers/transactions_provider.dart';

enum TransactionFilter { all, documents, chats, transactions }

class TransactionsScreenPlaceholder extends ConsumerStatefulWidget {
  const TransactionsScreenPlaceholder({super.key});

  @override
  ConsumerState<TransactionsScreenPlaceholder> createState() =>
      _TransactionsScreenPlaceholderState();
}

class _TransactionsScreenPlaceholderState
    extends ConsumerState<TransactionsScreenPlaceholder> {
  final _searchController = TextEditingController();
  TransactionFilter _selectedFilter = TransactionFilter.all;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    if (amount == 0) return '₹0';
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
    return '₹$intPart';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return 'Recent';
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min $ampm';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Recent';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0 && dt.day == now.day) {
      return 'Today, ${_formatTime(dt)}';
    } else if (diff.inDays == 1 || (diff.inDays == 0 && dt.day != now.day)) {
      return 'Yesterday, ${_formatTime(dt)}';
    } else {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]}, ${_formatTime(dt)}';
    }
  }

  bool _isToday(DateTime? dt) {
    if (dt == null) return true;
    final now = DateTime.now();
    return dt.year == now.year && dt.month == now.month && dt.day == now.day;
  }

  bool _isYesterday(DateTime? dt) {
    if (dt == null) return false;
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;
  }

  void _openAddTransactionModal() {
    final amountController = TextEditingController();
    final categoryController = TextEditingController(text: 'Sale');
    final descController = TextEditingController();
    String selectedType = 'Income';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Toggle Income / Expense
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            setModalState(() {
                              selectedType = 'Income';
                              categoryController.text = 'Sale';
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == 'Income'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Income',
                                style: TextStyle(
                                  color: selectedType == 'Income'
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
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
                              categoryController.text = 'General Expense';
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedType == 'Expense'
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Expense',
                                style: TextStyle(
                                  color: selectedType == 'Expense'
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount field
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xFF2563EB)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category field
                  TextField(
                    controller: categoryController,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF2563EB)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description / Note field
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description / Note',
                      prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFF2563EB)),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
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
                      final cat = categoryController.text.trim().isEmpty
                          ? (selectedType == 'Income' ? 'Sale' : 'General Expense')
                          : categoryController.text.trim();
                      final desc = descController.text.trim().isEmpty ? null : descController.text.trim();

                      Navigator.pop(ctx);
                      final success = await ref.read(transactionsProvider.notifier).addTransaction(
                            type: selectedType,
                            amount: amount,
                            category: cat,
                            description: desc,
                          );

                      if (context.mounted) {
                        if (success) {
                          ref.read(homeProvider.notifier).loadDashboard();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$selectedType of ₹${amount.toStringAsFixed(0)} saved! ✓'),
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to save transaction'),
                              backgroundColor: Color(0xFFEF4444),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Save Record', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showTransactionDetails(TransactionModel tx) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isIncome = tx.type.toLowerCase() == 'income';
        final displayTitle = (tx.description != null && tx.description!.isNotEmpty)
            ? tx.description!
            : tx.category;

        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      displayTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isIncome ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isIncome ? 'Income' : 'Expense',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isIncome ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _detailRow('Amount', '${isIncome ? '+' : '-'}₹${tx.amount.toStringAsFixed(2)}',
                        valueColor: isIncome ? const Color(0xFF16A34A) : const Color(0xFFEF4444)),
                    const Divider(height: 18),
                    _detailRow('Category', tx.category),
                    const Divider(height: 18),
                    _detailRow('Date & Time', _formatDate(tx.date)),
                    if (tx.source != null && tx.source!.isNotEmpty) ...[
                      const Divider(height: 18),
                      _detailRow('Source Channel', tx.source!.toUpperCase()),
                    ],
                    if (tx.referenceId != null && tx.referenceId!.isNotEmpty) ...[
                      const Divider(height: 18),
                      _detailRow('Reference ID', tx.referenceId!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Close', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: valueColor ?? const Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  bool _matchesFilter(TransactionModel tx) {
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final titleMatch = (tx.description?.toLowerCase().contains(q) ?? false);
      final catMatch = tx.category.toLowerCase().contains(q);
      final srcMatch = (tx.source?.toLowerCase().contains(q) ?? false);
      if (!titleMatch && !catMatch && !srcMatch) return false;
    }

    if (_selectedFilter == TransactionFilter.all) return true;

    if (_selectedFilter == TransactionFilter.documents) {
      final src = tx.source?.toLowerCase() ?? '';
      final cat = tx.category.toLowerCase();
      final desc = tx.description?.toLowerCase() ?? '';
      return src == 'ocr' ||
          src == 'invoice' ||
          cat.contains('invoice') ||
          cat.contains('receipt') ||
          cat.contains('document') ||
          desc.contains('invoice') ||
          desc.contains('receipt');
    }

    if (_selectedFilter == TransactionFilter.chats) {
      final src = tx.source?.toLowerCase() ?? '';
      final cat = tx.category.toLowerCase();
      final desc = tx.description?.toLowerCase() ?? '';
      return src == 'voice' ||
          src == 'chat' ||
          src == 'whatsapp' ||
          cat.contains('voice') ||
          cat.contains('chat') ||
          cat.contains('order') ||
          desc.contains('voice') ||
          desc.contains('whatsapp') ||
          desc.contains('order');
    }

    if (_selectedFilter == TransactionFilter.transactions) {
      return true;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionsProvider);
    final allTxs = txState.transactions;
    final filtered = allTxs.where(_matchesFilter).toList();

    final todayTxs = filtered.where((t) => _isToday(t.date)).toList();
    final yesterdayTxs = filtered.where((t) => _isYesterday(t.date)).toList();
    final olderTxs = filtered.where((t) => !_isToday(t.date) && !_isYesterday(t.date)).toList();

    return Stack(
      children: [
        // Ambient soft gradient in top-right
        Positioned(
          top: -60,
          right: -60,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF38BDF8).withValues(alpha: 0.12),
                  const Color(0xFF818CF8).withValues(alpha: 0.06),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        RefreshIndicator(
          color: const Color(0xFF2563EB),
          onRefresh: () => ref.read(transactionsProvider.notifier).loadTransactions(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // ── 1. HEADER TITLE & INSIGHTS PILL ─────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Transactions',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Manage all your business records in one place',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    // Insights Pill
                    InkWell(
                      onTap: () => context.go('/app/reports'),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bar_chart_rounded, size: 16, color: Color(0xFF2563EB)),
                            SizedBox(width: 4),
                            Text(
                              'Insights',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF2563EB)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ── 2. SEARCH & FILTER ROW ──────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val.trim().toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search records, documents, chats...',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: Color(0xFF64748B),
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 18, color: Color(0xFF94A3B8)),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _searchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Filter / Add button
                    InkWell(
                      onTap: _openAddTransactionModal,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.tune_rounded,
                            color: Color(0xFF0F172A),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── 3. FILTER TABS (All, Documents, Chats, Transactions) ─────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterPill(
                        label: 'All',
                        filter: TransactionFilter.all,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        label: 'Documents',
                        icon: Icons.description_outlined,
                        filter: TransactionFilter.documents,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        label: 'Chats',
                        icon: Icons.chat_bubble_outline_rounded,
                        filter: TransactionFilter.chats,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterPill(
                        label: 'Transactions',
                        icon: Icons.credit_card_rounded,
                        filter: TransactionFilter.transactions,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── 4. GROUP: TODAY ─────────────────────────────────────────
                if (todayTxs.isNotEmpty) ...[
                  _buildGroupHeader('TODAY', '${todayTxs.length} items'),
                  const SizedBox(height: 10),
                  ...todayTxs.map((tx) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: _buildTransactionCardFromModel(tx),
                      )),
                  const SizedBox(height: 14),
                ],

                // ── 5. GROUP: YESTERDAY ─────────────────────────────────────
                if (yesterdayTxs.isNotEmpty) ...[
                  _buildGroupHeader('YESTERDAY', '${yesterdayTxs.length} items'),
                  const SizedBox(height: 10),
                  ...yesterdayTxs.map((tx) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: _buildTransactionCardFromModel(tx),
                      )),
                  const SizedBox(height: 14),
                ],

                // ── 6. GROUP: EARLIER / OLDER ────────────────────────────────
                if (olderTxs.isNotEmpty) ...[
                  _buildGroupHeader('EARLIER', '${olderTxs.length} items'),
                  const SizedBox(height: 10),
                  ...olderTxs.map((tx) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: _buildTransactionCardFromModel(tx),
                      )),
                  const SizedBox(height: 14),
                ],

                // ── EMPTY STATE IF NO TRANSACTIONS ──────────────────────────
                if (filtered.isEmpty) ...[
                  _buildEmptyState(),
                  const SizedBox(height: 20),
                ],

                // ── 7. BOTTOM PROMOTIONAL BANNER ────────────────────────────
                _buildPromoCard(context),

                // Safe scroll buffer for the floating bottom navigation bar
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupHeader(String title, String count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF64748B),
            letterSpacing: 0.8,
          ),
        ),
        Text(
          count,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill({
    required String label,
    IconData? icon,
    required TransactionFilter filter,
  }) {
    final isSelected = _selectedFilter == filter;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCardFromModel(TransactionModel tx) {
    final isIncome = tx.type.toLowerCase() == 'income';
    final src = tx.source?.toLowerCase() ?? '';
    final cat = tx.category.toLowerCase();
    final desc = tx.description?.toLowerCase() ?? '';

    IconData icon;
    Color iconBg;
    Color iconColor;
    String subtitle;
    String statusLabel;
    Color statusColor;
    Color statusBg;

    if (src == 'ocr' || src == 'invoice' || cat.contains('invoice') || cat.contains('document') || desc.contains('invoice')) {
      icon = Icons.document_scanner_rounded;
      iconBg = const Color(0xFFEFF6FF);
      iconColor = const Color(0xFF2563EB);
      subtitle = 'Scanned OCR • ${_formatTime(tx.date)}';
      statusLabel = 'Processed';
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFDCFCE7);
    } else if (src == 'receipt' || cat.contains('receipt') || desc.contains('receipt')) {
      icon = Icons.receipt_long_rounded;
      iconBg = const Color(0xFFFFF7ED);
      iconColor = const Color(0xFFEA580C);
      subtitle = 'Uploaded Doc • ${_formatTime(tx.date)}';
      statusLabel = 'Verified';
      statusColor = const Color(0xFF2563EB);
      statusBg = const Color(0xFFEFF6FF);
    } else if (src == 'voice' || cat.contains('voice') || desc.contains('voice')) {
      icon = Icons.mic_rounded;
      iconBg = const Color(0xFFF5F3FF);
      iconColor = const Color(0xFF7C3AED);
      subtitle = 'Voice Assistant • ${_formatTime(tx.date)}';
      statusLabel = 'Recorded';
      statusColor = const Color(0xFF7C3AED);
      statusBg = const Color(0xFFF3E8FF);
    } else if (src == 'chat' || src == 'whatsapp' || desc.contains('whatsapp') || desc.contains('chat')) {
      icon = Icons.chat_bubble_rounded;
      iconBg = const Color(0xFFECFDF5);
      iconColor = const Color(0xFF10B981);
      subtitle = 'Message Auto-Detect • ${_formatTime(tx.date)}';
      statusLabel = 'Confirmed';
      statusColor = const Color(0xFF16A34A);
      statusBg = const Color(0xFFDCFCE7);
    } else if (isIncome) {
      icon = Icons.arrow_downward_rounded;
      iconBg = const Color(0xFFECFDF5);
      iconColor = const Color(0xFF10B981);
      subtitle = '${tx.category} • ${_formatTime(tx.date)}';
      statusLabel = 'Received';
      statusColor = const Color(0xFF10B981);
      statusBg = const Color(0xFFDCFCE7);
    } else {
      icon = Icons.arrow_upward_rounded;
      iconBg = const Color(0xFFFFF1F2);
      iconColor = const Color(0xFFEF4444);
      subtitle = '${tx.category} • ${_formatTime(tx.date)}';
      statusLabel = 'Paid';
      statusColor = const Color(0xFFEF4444);
      statusBg = const Color(0xFFFEE2E2);
    }

    final title = (tx.description != null && tx.description!.isNotEmpty)
        ? tx.description!
        : tx.category;

    return InkWell(
      onTap: () => _showTransactionDetails(tx),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Amount & Status Pill & Arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(tx.amount),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF2563EB),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No records found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Record sales, upload invoices, or speak to AI Assistant to populate your business ledger.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openAddTransactionModal,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Record'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF4FF), Color(0xFFF3E8FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E7FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Folders graphic
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Icon(
                Icons.folder_shared_rounded,
                color: Color(0xFF6366F1),
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'All your business records\nin one place',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Search, filter and manage documents, chats and transactions easily.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context.push('/app/upload'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Learn More',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
