class DashboardSummaryModel {
  final double todayIncome;
  final double? incomeChange;
  final double todayExpenses;
  final double? expenseChange;
  final double todayProfit;
  final double totalCash;
  final double receivables;
  final double liabilities;
  final List<String> insights;

  const DashboardSummaryModel({
    this.todayIncome = 0.0,
    this.incomeChange,
    this.todayExpenses = 0.0,
    this.expenseChange,
    this.todayProfit = 0.0,
    this.totalCash = 0.0,
    this.receivables = 0.0,
    this.liabilities = 0.0,
    this.insights = const [],
  });
}
