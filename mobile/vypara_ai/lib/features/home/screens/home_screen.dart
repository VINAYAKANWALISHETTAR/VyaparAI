import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/features/auth/presentation/providers/auth_provider.dart';
import 'package:vypara_ai/features/home/providers/home_provider.dart';
import 'package:vypara_ai/features/transactions/providers/transactions_provider.dart';

class HomeScreenPlaceholder extends ConsumerStatefulWidget {
  const HomeScreenPlaceholder({super.key});

  @override
  ConsumerState<HomeScreenPlaceholder> createState() => _HomeScreenPlaceholderState();
}

class _HomeScreenPlaceholderState extends ConsumerState<HomeScreenPlaceholder> {
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
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]}';
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

                  // Amount
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

                  // Category
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

                  // Description / Note
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeProvider);
    final txState = ref.watch(transactionsProvider);
    final auth = ref.watch(authProvider);
    final summary = homeState.summary;

    // Real User Name from Auth or default to 'vinayaka'
    final userName = (auth.user?.name.isNotEmpty == true)
        ? auth.user!.name.split(' ').first
        : 'vinayaka';

    // Real Metrics from backend
    final double incomeVal = summary?.todayIncome ?? 0.0;
    final double expenseVal = summary?.todayExpenses ?? 0.0;
    final double profitVal = summary?.todayProfit ?? (incomeVal - expenseVal);

    final String incomeStr = _formatCurrency(incomeVal);
    final String expenseStr = _formatCurrency(expenseVal);
    final String profitStr = _formatCurrency(profitVal);

    // Calculate real short badge (e.g. ₹ 1.24L, ₹ 5K, ₹ 500)
    final String incomeBadge = incomeVal >= 100000
        ? '₹ ${(incomeVal / 100000).toStringAsFixed(2)}L'
        : (incomeVal >= 1000 ? '₹ ${(incomeVal / 1000).toStringAsFixed(1)}K' : '₹ ${incomeVal.toStringAsFixed(0)}');

    final double incomeChange = summary?.incomeChange ?? 0.0;
    final String incomeChangeStr = incomeChange >= 0
        ? '+${incomeChange.toStringAsFixed(0)}%'
        : '${incomeChange.toStringAsFixed(0)}%';

    final double expenseChange = summary?.expenseChange ?? 0.0;
    final String expenseChangeStr = expenseChange >= 0
        ? '+${expenseChange.toStringAsFixed(0)}%'
        : '${expenseChange.toStringAsFixed(0)}%';

    final String profitChangeStr = profitVal >= 0 ? '+100%' : '-100%';

    final recentTransactions = txState.transactions.take(4).toList();

    return Stack(
      children: [
        // Ambient soft gradient wash in top-right
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
                  const Color(0xFF38BDF8).withValues(alpha: 0.14),
                  const Color(0xFF818CF8).withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Scrollable content (Header and Bottom Bar are fixed in AppShell)
        RefreshIndicator(
          color: const Color(0xFF2563EB),
          onRefresh: () async {
            await Future.wait([
              ref.read(homeProvider.notifier).loadDashboard(),
              ref.read(transactionsProvider.notifier).loadTransactions(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // ── 1. GREETING & QUOTE SECTION ─────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting on Left
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Good Morning,',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$userName \u{1F44B}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            "Here's your business overview for today",
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quote on Right with Sparkle
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                '"Small steps',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: Color(0xFF7C3AED),
                              ),
                            ],
                          ),
                          const Text(
                            'build big businesses"',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ── 2. TODAY'S REVENUE CARD ────────────────────────────────
                _buildRevenueCard(
                  incomeStr: incomeStr,
                  badgeStr: incomeBadge,
                  changeStr: incomeChangeStr,
                  incomeVal: incomeVal,
                ),

                const SizedBox(height: 14),

                // ── 3. EXPENSE + PROFIT CARDS (SIDE BY SIDE) ──────────────
                Row(
                  children: [
                    // Today Expense Card
                    Expanded(
                      child: _buildExpenseCard(
                        expenseStr: expenseStr,
                        changeStr: expenseChangeStr,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Today Profit Card
                    Expanded(
                      child: _buildProfitCard(
                        profitStr: profitStr,
                        changeStr: profitChangeStr,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── 4. QUICK ACTIONS SECTION ───────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/app/transactions'),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'See All',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Quick Actions Card Container
                _buildQuickActionsContainer(context),

                const SizedBox(height: 16),

                // ── 5. AI PROMOTIONAL BANNER CARD ──────────────────────────
                _buildAiPromotionalCard(context),

                const SizedBox(height: 20),

                // ── 6. RECENT ACTIVITY SECTION ─────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/app/transactions'),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View All',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: Color(0xFF2563EB),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Recent Activity Card (Real items if present, or clean empty state)
                if (recentTransactions.isNotEmpty)
                  ...recentTransactions.map(
                    (tx) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: tx.type.toLowerCase() == 'income'
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFFF1F2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                tx.type.toLowerCase() == 'income'
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: tx.type.toLowerCase() == 'income'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (tx.description != null && tx.description!.isNotEmpty)
                                        ? tx.description!
                                        : tx.category,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${tx.category} • ${_formatDate(tx.date)}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: Color(0xFF64748B),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${tx.type.toLowerCase() == 'income' ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: tx.type.toLowerCase() == 'income'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  _buildRecentActivityEmptyState(context),

                // Safe bottom padding to scroll comfortably above fixed navigation bar
                const SizedBox(height: 110),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── REVENUE CARD BUILDER ──────────────────────────────────────────────────
  Widget _buildRevenueCard({
    required String incomeStr,
    required String badgeStr,
    required String changeStr,
    required double incomeVal,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle soft blue glow in the bottom-right corner
          Positioned(
            right: -20,
            bottom: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF38BDF8).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Icon + Label + Dynamic Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.bar_chart_rounded,
                        color: Color(0xFF2563EB),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Today's Revenue",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const Spacer(),
                  // Dynamic Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Text(
                      badgeStr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Content Row: Big Amount & Pill on Left, Ascending Bar Chart on Right
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Left side
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incomeStr,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -1.0,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.arrow_upward_rounded, size: 12, color: Color(0xFF16A34A)),
                                  const SizedBox(width: 2),
                                  Text(
                                    changeStr,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'vs. yesterday',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right side: Modern Ascending Bar Chart
                  _buildAscendingBarChart(incomeVal),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAscendingBarChart(double incomeVal) {
    // Dynamic proportionate bars
    final bars = [
      {'height': 16.0, 'color': const Color(0xFFDBEAFE)},
      {'height': 24.0, 'color': const Color(0xFFBFDBFE)},
      {'height': 34.0, 'color': const Color(0xFF93C5FD)},
      {'height': 44.0, 'color': const Color(0xFF60A5FA)},
      {'height': 56.0, 'color': const Color(0xFF3B82F6)},
      {'height': 70.0, 'color': const Color(0xFF2563EB)},
    ];

    return SizedBox(
      height: 72,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((bar) {
          return Container(
            width: 8,
            height: bar['height'] as double,
            margin: const EdgeInsets.symmetric(horizontal: 2.5),
            decoration: BoxDecoration(
              color: bar['color'] as Color,
              borderRadius: BorderRadius.circular(5),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── EXPENSE CARD BUILDER ──────────────────────────────────────────────────
  Widget _buildExpenseCard({
    required String expenseStr,
    required String changeStr,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFE4E6)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4E6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: Color(0xFFEF4444),
              size: 18,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Today Expense',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            expenseStr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_upward_rounded, size: 10, color: Color(0xFFEF4444)),
                    const SizedBox(width: 2),
                    Text(
                      changeStr,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'vs. yesterday',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── PROFIT CARD BUILDER ───────────────────────────────────────────────────
  Widget _buildProfitCard({
    required String profitStr,
    required String changeStr,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCFCE7)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Today's Profit",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            profitStr,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_upward_rounded, size: 10, color: Color(0xFF16A34A)),
                    const SizedBox(width: 2),
                    Text(
                      changeStr,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Expanded(
                child: Text(
                  'vs. yesterday',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── QUICK ACTIONS CONTAINER BUILDER ───────────────────────────────────────
  Widget _buildQuickActionsContainer(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Upload Document
          _buildQuickActionItem(
            icon: Icons.description_rounded,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF2563EB),
            title: 'Upload\nDocument',
            onTap: () => context.push('/app/upload'),
          ),

          // 2. Ask AI
          _buildQuickActionItem(
            icon: Icons.auto_awesome_rounded,
            iconBg: const Color(0xFFF5F3FF),
            iconColor: const Color(0xFF8B5CF6),
            title: 'Ask AI\n',
            onTap: () => context.push('/app/voice'),
          ),

          // 3. Add Transaction
          _buildQuickActionItem(
            icon: Icons.add_circle_outline_rounded,
            iconBg: const Color(0xFFECFDF5),
            iconColor: const Color(0xFF10B981),
            title: 'Add\nTransaction',
            onTap: () => _openAddTransactionSheet(context, ref, initialType: 'Income'),
          ),

          // 4. Scan with Camera
          _buildQuickActionItem(
            icon: Icons.camera_alt_rounded,
            iconBg: const Color(0xFFF0F9FF),
            iconColor: const Color(0xFF0284C7),
            title: 'Scan with\nCamera',
            onTap: () => context.push('/app/upload'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 24),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── AI PROMOTIONAL BANNER BUILDER ─────────────────────────────────────────
  Widget _buildAiPromotionalCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF4FF), Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E7FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Sparkle Icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF7C3AED),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Turn your data into opportunities with AI',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Get insights, recommendations and grow your business faster.',
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
          // CTA Button
          InkWell(
            onTap: () => context.push('/app/voice'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Explore with AI',
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

  // ── RECENT ACTIVITY EMPTY STATE CARD BUILDER ──────────────────────────────
  Widget _buildRecentActivityEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Decorative background custom paint with paper plane & flight curve
            Positioned.fill(
              child: CustomPaint(
                painter: _PaperPlaneDecorPainter(),
              ),
            ),

            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.article_outlined,
                    size: 38,
                    color: Color(0xFF94A3B8),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'No recent transactions',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Record a sale or upload an invoice to see activity',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── CUSTOM PAINTER FOR PAPER PLANE & DASHED TRAIL ───────────────────────────
class _PaperPlaneDecorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Faint subtle circle at bottom-left
    final circlePaint = Paint()
      ..color = const Color(0xFFEFF6FF).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.05, h * 0.9), 45, circlePaint);

    // Dotted flight trail swooping from bottom-left to top-right
    final path = Path()
      ..moveTo(w * 0.65, h * 0.85)
      ..quadraticBezierTo(w * 0.78, h * 0.75, w * 0.88, h * 0.35);

    final dashPaint = Paint()
      ..color = const Color(0xFFBFDBFE).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw dashed path
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      const dashLength = 4.0;
      const gapLength = 4.0;
      while (distance < metric.length) {
        final extract = metric.extractPath(distance, distance + dashLength);
        canvas.drawPath(extract, dashPaint);
        distance += dashLength + gapLength;
      }
    }

    // Modern Paper Plane Graphic at top-right
    final planeCenter = Offset(w * 0.88, h * 0.35);
    final planePaint = Paint()
      ..color = const Color(0xFF93C5FD)
      ..style = PaintingStyle.fill;

    final planePath = Path()
      ..moveTo(planeCenter.dx + 16, planeCenter.dy - 12)
      ..lineTo(planeCenter.dx - 14, planeCenter.dy + 4)
      ..lineTo(planeCenter.dx - 4, planeCenter.dy)
      ..close();

    final planeShadow = Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.fill;

    final foldPath = Path()
      ..moveTo(planeCenter.dx + 16, planeCenter.dy - 12)
      ..lineTo(planeCenter.dx - 4, planeCenter.dy)
      ..lineTo(planeCenter.dx - 2, planeCenter.dy + 8)
      ..close();

    canvas.drawPath(planePath, planePaint);
    canvas.drawPath(foldPath, planeShadow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
