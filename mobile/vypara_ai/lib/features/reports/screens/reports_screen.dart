import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/app/theme/app_shadows.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
import 'package:vypara_ai/core/utils/file_downloader.dart';
import 'package:vypara_ai/features/reports/data/models/financial_report_model.dart';
import 'package:vypara_ai/features/reports/providers/reports_provider.dart';

class ReportsScreenPlaceholder extends ConsumerStatefulWidget {
  const ReportsScreenPlaceholder({super.key});

  @override
  ConsumerState<ReportsScreenPlaceholder> createState() => _ReportsScreenPlaceholderState();
}

class _ReportsScreenPlaceholderState extends ConsumerState<ReportsScreenPlaceholder> {
  String _activeCategoryTab = 'Income';

  String _formatAmount(double amount) {
    if (amount == 0) return '₹ 0';
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final str = absAmount.toStringAsFixed(0);
    String formatted = '';

    if (str.length > 3) {
      final lastThree = str.substring(str.length - 3);
      String remaining = str.substring(0, str.length - 3);
      while (remaining.length > 2) {
        formatted = ',${remaining.substring(remaining.length - 2)}$formatted';
        remaining = remaining.substring(0, remaining.length - 2);
      }
      formatted = '₹ $remaining$formatted,$lastThree';
    } else {
      formatted = '₹ $str';
    }

    return isNegative ? '-$formatted' : formatted;
  }

  Future<void> _handleExportCsv(BuildContext context, String Function(String, [Map<String, dynamic>?]) tr) async {
    final period = ref.read(reportsProvider).selectedPeriod;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('generating_csv')),
        duration: const Duration(seconds: 1),
      ),
    );
    try {
      final csvData = await ref.read(reportsProvider.notifier).exportReportCsv();
      if (csvData.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('no_report_data')),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
        return;
      }
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final fileName = 'vyapar_financial_report_${period}_$dateStr.csv';
      final savedPath = await FileDownloader.download(
        csvData,
        fileName,
        mimeType: 'text/csv',
        subject: 'VyaparAI Financial Report CSV ($period)',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr('export_csv')} $fileName ✓'),
            backgroundColor: const Color(0xFF10B981),
            action: savedPath != null
                ? SnackBarAction(
                    label: tr('share'),
                    textColor: Colors.white,
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(
                          files: [XFile(savedPath, mimeType: 'text/csv', name: fileName)],
                          subject: 'VyaparAI Financial Report CSV ($period)',
                        ),
                      );
                    },
                  )
                : null,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('failed_export_csv')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _handleDownloadPdf(BuildContext context, String Function(String, [Map<String, dynamic>?]) tr) async {
    final period = ref.read(reportsProvider).selectedPeriod;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('generating_pdf')),
        duration: const Duration(seconds: 1),
      ),
    );
    try {
      final pdfBytes = await ref.read(reportsProvider.notifier).downloadReportPdf();
      if (pdfBytes.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('no_report_data')),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
        return;
      }
      final now = DateTime.now();
      final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final fileName = 'vyapar_financial_report_${period}_$dateStr.pdf';
      final savedPath = await FileDownloader.downloadBytes(
        pdfBytes,
        fileName,
        mimeType: 'application/pdf',
        subject: 'VyaparAI Financial Report ($period)',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr('download_pdf')} $fileName ✓'),
            backgroundColor: const Color(0xFF10B981),
            action: savedPath != null
                ? SnackBarAction(
                    label: tr('share'),
                    textColor: Colors.white,
                    onPressed: () {
                      SharePlus.instance.share(
                        ShareParams(
                          files: [XFile(savedPath, mimeType: 'application/pdf', name: fileName)],
                          subject: 'VyaparAI Financial Report ($period)',
                        ),
                      );
                    },
                  )
                : null,
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('failed_export_pdf')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _handleShareReport(BuildContext context, FinancialReportModel? report, String period, String Function(String, [Map<String, dynamic>?]) tr) async {
    if (report == null) return;
    final income = report.totalIncome;
    final expenses = report.totalExpenses;
    final profit = report.netProfit;
    final count = report.transactionCount;

    final shareText = '''
📊 VyaparAI ${tr('financial_overview')} (${period.toUpperCase()})
━━━━━━━━━━━━━━━━━━━━
💰 ${tr('total_revenue')}: ${_formatAmount(income)}
📉 ${tr('total_expenses')}: ${_formatAmount(expenses)}
📈 ${tr('net_profit')}: ${_formatAmount(profit)}
🧾 ${tr('transactions')}: $count

Generated securely via VyaparAI
'''.trim();

    try {
      await SharePlus.instance.share(ShareParams(text: shareText, subject: 'VyaparAI Financial Report ($period)'));
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: shareText));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('report_summary_copied')),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportsProvider);
    final tr = ref.watch(appTranslationsProvider);
    final report = reportState.report;
    final period = reportState.selectedPeriod;

    final incCount = report?.incomeBreakdown.fold<int>(0, (sum, item) => sum + item.count) ?? 0;
    final expCount = report?.expenseBreakdown.fold<int>(0, (sum, item) => sum + item.count) ?? 0;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(reportsProvider.notifier).loadReport(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 110),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Filter Pill Tabs - Screen 8
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: AppShadows.subtle,
                ),
                child: Row(
                  children: [
                    _buildPeriodTab(tr('today'), 'today', period),
                    _buildPeriodTab(tr('this_week'), 'week', period),
                    _buildPeriodTab(tr('this_month'), 'month', period),
                    _buildPeriodTab(tr('all_time'), 'all', period),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (reportState.isLoading && report == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              else ...[
                // Top KPI Summary Cards (Income & Expenses)
                Row(
                  children: [
                    // Total Income Card
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
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F764F).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_upward_rounded,
                                    color: Color(0xFF0F764F),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tr('income'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0F764F),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _formatAmount(report?.totalIncome ?? 0),
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F764F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$incCount ${tr('transactions_label')}',
                              style: TextStyle(
                                fontSize: 11,
                                color: const Color(0xFF0F764F).withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Total Expenses Card
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F0),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_downward_rounded,
                                    color: AppColors.error,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tr('expenses'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _formatAmount(report?.totalExpenses ?? 0),
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$expCount ${tr('transactions_label')}',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.error.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Net Profit Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.subtle,
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('net_profit'),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatAmount(report?.netProfit ?? 0),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: (report?.netProfit ?? 0) >= 0
                                    ? AppColors.primary
                                    : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (report?.netProfit ?? 0) >= 0
                              ? const Color(0xFFE8F8F0)
                              : const Color(0xFFFFF0F0),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${(report?.profitMargin ?? 0) >= 0 ? '+' : ''}${(report?.profitMargin ?? 0).toStringAsFixed(1)}% ${tr('margin_label')}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: (report?.netProfit ?? 0) >= 0
                                ? const Color(0xFF0F764F)
                                : AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Comparison Bar Chart Card - Screen 8
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.subtle,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr('income_vs_expenses'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              _buildLegend(tr('income'), const Color(0xFF0F764F)),
                              const SizedBox(width: 12),
                              _buildLegend(tr('expense'), AppColors.error),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildBarChart(report?.chartPoints ?? [], tr),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Category Breakdown Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: AppShadows.subtle,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr('category_breakdown'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Row(
                              children: [
                                _buildCategoryToggle(tr('income'), 'Income'),
                                _buildCategoryToggle(tr('expense'), 'Expense'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildCategoryList(
                        _activeCategoryTab == 'Income'
                            ? (report?.incomeBreakdown ?? [])
                            : (report?.expenseBreakdown ?? []),
                        _activeCategoryTab == 'Income'
                            ? const Color(0xFF0F764F)
                            : AppColors.error,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // PDF & CSV Export & Share Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleDownloadPdf(context, tr),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
                    label: Text(
                      tr('download_pdf'),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleExportCsv(context, tr),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(tr('export_csv')),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleShareReport(context, report, period, tr),
                        icon: const Icon(Icons.share_rounded, size: 18),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(tr('share_report')),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F764F),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      );
  }

  Widget _buildPeriodTab(String title, String key, String activeKey) {
    final isSelected = activeKey == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(reportsProvider.notifier).setPeriod(key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildCategoryToggle(String title, String tabKey) {
    final isSelected = _activeCategoryTab == tabKey;
    return GestureDetector(
      onTap: () => setState(() => _activeCategoryTab = tabKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<DailyChartPoint> points, String Function(String, [Map<String, dynamic>?]) tr) {
    if (points.isEmpty) {
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(tr('no_tx_data_period'), style: const TextStyle(color: AppColors.textTertiary)),
        ),
      );
    }

    double maxVal = 0;
    for (final p in points) {
      maxVal = max(maxVal, max(p.income, p.expense));
    }
    if (maxVal == 0) maxVal = 1000;

    return SizedBox(
      height: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((p) {
          final incRatio = (p.income / maxVal).clamp(0.05, 1.0);
          final expRatio = (p.expense / maxVal).clamp(0.05, 1.0);

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 10,
                    height: 90 * incRatio,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F764F),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 10,
                    height: 90 * expRatio,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                p.label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryList(List<CategoryBreakdownItem> items, Color themeColor) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No ${_activeCategoryTab.toLowerCase()} recorded in this period',
            style: const TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: themeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Icon(
                          _activeCategoryTab == 'Income'
                              ? Icons.shopping_bag_outlined
                              : Icons.receipt_outlined,
                          size: 16,
                          color: themeColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${item.count})',
                        style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  Text(
                    _formatAmount(item.amount),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (item.percentage / 100).clamp(0.0, 1.0),
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
