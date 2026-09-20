import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'AI Business Insights',
          style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Tabs (Insights, Risks, Suggestions - Matches Screen 14)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppColors.primary,
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'Insights'),
                Tab(text: 'Risks'),
                Tab(text: 'Suggestions'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildInsightsTab(),
                _buildRisksTab(),
                _buildSuggestionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildInsightCard(
          icon: Icons.trending_up_rounded,
          iconColor: const Color(0xFF10B981),
          bgColor: const Color(0xFFECFDF5),
          title: 'Sales Growth Trending Up',
          body: 'Sales are 18% higher this month compared to last month. Revenue increased by ₹ 24,850.',
          tag: 'Positive Trend',
          tagColor: const Color(0xFF10B981),
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          icon: Icons.star_rounded,
          iconColor: const Color(0xFF2563EB),
          bgColor: const Color(0xFFEFF6FF),
          title: 'Top Customer Contribution',
          body: 'Priya Stores contributes 28% of total monthly sales (₹ 48,200). Highest repeat order rate.',
          tag: 'Key Customer',
          tagColor: const Color(0xFF2563EB),
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          icon: Icons.receipt_long_rounded,
          iconColor: const Color(0xFF7C3AED),
          bgColor: const Color(0xFFF5F3FF),
          title: 'GST Input Tax Credit',
          body: 'You may be eligible for GST input tax credit of ₹ 4,200 on recent purchase invoices.',
          tag: 'Tax Benefit',
          tagColor: const Color(0xFF7C3AED),
        ),
      ],
    );
  }

  Widget _buildRisksTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildInsightCard(
          icon: Icons.warning_amber_rounded,
          iconColor: const Color(0xFFEF4444),
          bgColor: const Color(0xFFFEF2F2),
          title: '3 Overdue Payments',
          body: 'Ramesh Traders and 2 other clients have payments overdue past 15 days. Total overdue: ₹ 24,000.',
          tag: 'High Priority',
          tagColor: const Color(0xFFEF4444),
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: const Color(0xFFF59E0B),
          bgColor: const Color(0xFFFFFBEB),
          title: 'Cash Flow Dip Expected',
          body: 'Upcoming supplier payouts of ₹ 23,350 scheduled next week may temporarily decrease liquidity.',
          tag: 'Liquidity Alert',
          tagColor: const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildSuggestionsTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildInsightCard(
          icon: Icons.lightbulb_outline_rounded,
          iconColor: const Color(0xFF0284C7),
          bgColor: const Color(0xFFF0F9FF),
          title: 'Optimize Raw Material Costs',
          body: 'Consider negotiating raw material costs with suppliers. Recent procurement is 5% higher than market average.',
          tag: 'Cost Savings',
          tagColor: const Color(0xFF0284C7),
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          icon: Icons.alarm_rounded,
          iconColor: const Color(0xFF059669),
          bgColor: const Color(0xFFECFDF5),
          title: 'Send Automated Reminders',
          body: 'Sending 1-tap WhatsApp reminders on the due date improves collection speed by 42%.',
          tag: 'Action Recommended',
          tagColor: const Color(0xFF059669),
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String body,
    required String tag,
    required Color tagColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: tagColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: tagColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
