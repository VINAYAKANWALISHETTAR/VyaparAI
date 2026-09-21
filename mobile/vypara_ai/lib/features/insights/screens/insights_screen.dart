import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
import 'package:vypara_ai/features/insights/providers/insights_provider.dart';

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
    final tr = ref.watch(appTranslationsProvider);
    final state = ref.watch(insightsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/app/home');
            }
          },
        ),
        title: Text(
          tr('insights'),
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(insightsProvider.notifier).fetchAll(),
        color: AppColors.primary,
        child: Column(
          children: [
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
                tabs: [
                  Tab(text: tr('insights')),
                  Tab(text: tr('risks')),
                  Tab(text: tr('suggestions')),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildInsightsTab(state),
                        _buildRisksTab(state),
                        _buildSuggestionsTab(state),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab(InsightsState state) {
    if (state.insights.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.auto_awesome_rounded,
        title: 'No Trends Detected Yet',
        description: 'As you record more daily sales and expense transactions, VyaparAI will automatically detect business trends and revenue patterns.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.insights.length,
      itemBuilder: (context, index) {
        final item = state.insights[index];
        final isHigh = item.priority.toLowerCase() == 'high';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildInsightCard(
            icon: isHigh ? Icons.trending_up_rounded : Icons.insights_rounded,
            iconColor: isHigh ? const Color(0xFF10B981) : const Color(0xFF2563EB),
            bgColor: isHigh ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
            title: item.title,
            body: item.description,
            tag: item.priority.toUpperCase(),
            tagColor: isHigh ? const Color(0xFF10B981) : const Color(0xFF2563EB),
          ),
        );
      },
    );
  }

  Widget _buildRisksTab(InsightsState state) {
    if (state.anomalies.isEmpty) {
      return _buildEmptyTab(
        icon: Icons.shield_outlined,
        title: 'All Systems Normal',
        description: 'No financial anomalies or risk factors detected in your recent records. Your transactions and cash flow are in good health.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.anomalies.length,
      itemBuilder: (context, index) {
        final item = state.anomalies[index];
        final isCritical = item.severity.toLowerCase() == 'high';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildInsightCard(
            icon: Icons.warning_amber_rounded,
            iconColor: isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
            bgColor: isCritical ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
            title: item.type.replaceAll('_', ' ').toUpperCase(),
            body: item.description,
            tag: item.severity.toUpperCase(),
            tagColor: isCritical ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
          ),
        );
      },
    );
  }

  Widget _buildSuggestionsTab(InsightsState state) {
    // Generate context-aware recommendations based on real anomaly/insight counts
    final suggestions = <Map<String, String>>[];

    if (state.anomalies.isNotEmpty) {
      suggestions.add({
        'title': 'Resolve Flagged Transactions',
        'body': 'You have ${state.anomalies.length} item(s) flagged for review. Checking them ensures your books remain accurate.',
        'tag': 'High Priority',
        'priority': 'high',
      });
    }

    suggestions.add({
      'title': 'Daily Transaction Reconciliation',
      'body': 'Record all customer payments and expense receipts daily to keep cash flow forecasts precise.',
      'tag': 'Best Practice',
      'priority': 'normal',
    });

    suggestions.add({
      'title': 'Automate Due Payment Reminders',
      'body': 'Set timely reminders for overdue customer invoices to speed up cash collections.',
      'tag': 'Receivables',
      'priority': 'normal',
    });

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final s = suggestions[index];
        final isHigh = s['priority'] == 'high';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildInsightCard(
            icon: Icons.lightbulb_outline_rounded,
            iconColor: isHigh ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
            bgColor: isHigh ? const Color(0xFFFEF2F2) : const Color(0xFFF0F9FF),
            title: s['title']!,
            body: s['body']!,
            tag: s['tag']!,
            tagColor: isHigh ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
          ),
        );
      },
    );
  }

  Widget _buildEmptyTab({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
      ),
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
              Expanded(
                child: Row(
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
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
