class CategoryBreakdownItem {
  final String category;
  final double amount;
  final int count;
  final double percentage;

  const CategoryBreakdownItem({
    required this.category,
    required this.amount,
    required this.count,
    required this.percentage,
  });

  factory CategoryBreakdownItem.fromJson(Map<String, dynamic> json, double total) {
    final amt = (json['amount'] as num?)?.toDouble() ?? 0.0;
    final pct = total > 0 ? (amt / total) * 100.0 : 0.0;
    return CategoryBreakdownItem(
      category: json['category']?.toString() ?? 'General',
      amount: amt,
      count: (json['count'] as num?)?.toInt() ?? 1,
      percentage: pct,
    );
  }
}

class DailyChartPoint {
  final String label;
  final DateTime date;
  final double income;
  final double expense;

  const DailyChartPoint({
    required this.label,
    required this.date,
    required this.income,
    required this.expense,
  });
}

class FinancialReportModel {
  final String period;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final int transactionCount;
  final List<CategoryBreakdownItem> incomeBreakdown;
  final List<CategoryBreakdownItem> expenseBreakdown;
  final List<DailyChartPoint> chartPoints;

  const FinancialReportModel({
    required this.period,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.transactionCount,
    required this.incomeBreakdown,
    required this.expenseBreakdown,
    required this.chartPoints,
  });

  double get profitMargin {
    if (totalIncome <= 0) return 0.0;
    return (netProfit / totalIncome) * 100.0;
  }
}
