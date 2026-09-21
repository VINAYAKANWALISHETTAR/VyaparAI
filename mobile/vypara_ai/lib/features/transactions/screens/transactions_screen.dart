import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  void _openAddTransactionModal() {
    final amountController = TextEditingController();
    final categoryController = TextEditingController(text: 'Sale');
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

                  TextField(
                    controller: categoryController,
                    decoration: InputDecoration(
                      labelText: 'Description / Item Name',
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
                      if (amount <= 0) return;
                      final desc = categoryController.text.trim().isEmpty ? 'Transaction' : categoryController.text.trim();

                      Navigator.pop(ctx);
                      await ref.read(transactionsProvider.notifier).addTransaction(
                        type: selectedType,
                        amount: amount,
                        category: desc,
                        description: desc,
                      );
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

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionsProvider);

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
                      // Filter button
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
                  _buildGroupHeader('TODAY', '2 items'),
                  const SizedBox(height: 10),

                  // Dynamic live transactions from backend if available
                  ...txState.transactions
                      .where((tx) =>
                          _searchQuery.isEmpty ||
                          (tx.description?.toLowerCase().contains(_searchQuery) ?? false) ||
                          tx.category.toLowerCase().contains(_searchQuery))
                      .map((tx) => Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: _buildTransactionCard(
                              icon: tx.type.toLowerCase() == 'income'
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              iconBg: tx.type.toLowerCase() == 'income'
                                  ? const Color(0xFFECFDF5)
                                  : const Color(0xFFFFF1F2),
                              iconColor: tx.type.toLowerCase() == 'income'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              title: (tx.description != null && tx.description!.isNotEmpty) ? tx.description! : tx.category,
                              subtitle: '${tx.category} • Today',
                              amount: '₹${tx.amount.toStringAsFixed(0)}',
                              statusLabel: tx.type.toLowerCase() == 'income' ? 'Received' : 'Paid',
                              statusColor: tx.type.toLowerCase() == 'income'
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              statusBg: tx.type.toLowerCase() == 'income'
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                            ),
                          )),

                  // Card 1: GST Tax Invoice - Krishna Traders
                  if (_shouldShow('document', 'gst tax invoice - krishna traders'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: _buildTransactionCard(
                        icon: Icons.document_scanner_rounded,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'GST Tax Invoice - Krishna Traders',
                        subtitle: 'Scanned OCR • 7:24 AM',
                        amount: '₹8,450',
                        statusLabel: 'Processed',
                        statusColor: const Color(0xFF16A34A),
                        statusBg: const Color(0xFFDCFCE7),
                      ),
                    ),

                  // Card 2: Voice Order - 5x Rice Bags
                  if (_shouldShow('chat', 'voice order - 5x rice bags'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: _buildTransactionCard(
                        icon: Icons.mic_rounded,
                        iconBg: const Color(0xFFF5F3FF),
                        iconColor: const Color(0xFF7C3AED),
                        title: 'Voice Order - 5x Rice Bags',
                        subtitle: 'Voice Assistant • 6:09 AM',
                        amount: '₹2,100',
                        statusLabel: 'Recorded',
                        statusColor: const Color(0xFF7C3AED),
                        statusBg: const Color(0xFFF3E8FF),
                      ),
                    ),

                  const SizedBox(height: 14),

                  // ── 5. GROUP: YESTERDAY ─────────────────────────────────────
                  _buildGroupHeader('YESTERDAY', '2 items'),
                  const SizedBox(height: 10),

                  // Card 3: Wholesale Purchase Receipt #882
                  if (_shouldShow('document', 'wholesale purchase receipt #882'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: _buildTransactionCard(
                        icon: Icons.receipt_long_rounded,
                        iconBg: const Color(0xFFFFF7ED),
                        iconColor: const Color(0xFFEA580C),
                        title: 'Wholesale Purchase Receipt #882',
                        subtitle: 'Uploaded Doc • Yesterday',
                        amount: '₹14,200',
                        statusLabel: 'Verified',
                        statusColor: const Color(0xFF2563EB),
                        statusBg: const Color(0xFFEFF6FF),
                      ),
                    ),

                  // Card 4: WhatsApp Payment Alert - Suresh Gowda
                  if (_shouldShow('chat', 'whatsapp payment alert - suresh gowda'))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: _buildTransactionCard(
                        icon: Icons.chat_bubble_rounded,
                        iconBg: const Color(0xFFECFDF5),
                        iconColor: const Color(0xFF10B981),
                        title: 'WhatsApp Payment Alert - Suresh Gowda',
                        subtitle: 'Message Auto-Detect • Yesterday',
                        amount: '₹5,000',
                        statusLabel: 'Confirmed',
                        statusColor: const Color(0xFF16A34A),
                        statusBg: const Color(0xFFDCFCE7),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // ── 6. BOTTOM PROMOTIONAL BANNER ────────────────────────────
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

  bool _shouldShow(String itemType, String title) {
    if (_searchQuery.isNotEmpty && !title.contains(_searchQuery)) {
      return false;
    }
    if (_selectedFilter == TransactionFilter.all) return true;
    if (_selectedFilter == TransactionFilter.documents && itemType == 'document') return true;
    if (_selectedFilter == TransactionFilter.chats && itemType == 'chat') return true;
    if (_selectedFilter == TransactionFilter.transactions) return true;
    return false;
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

  Widget _buildTransactionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String amount,
    required String statusLabel,
    required Color statusColor,
    required Color statusBg,
  }) {
    return Container(
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
                amount,
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
            onTap: () => context.go('/app/reports'),
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
