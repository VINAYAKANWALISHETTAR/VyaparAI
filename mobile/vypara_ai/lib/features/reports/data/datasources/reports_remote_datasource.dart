import 'package:vypara_ai/core/constants/api_endpoints.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/reports/data/models/financial_report_model.dart';
import 'package:vypara_ai/features/transactions/data/models/transaction_model.dart';

class ReportsRemoteDataSource {
  final ApiClient apiClient;

  ReportsRemoteDataSource(this.apiClient);

  Future<String?> getDefaultBusinessId() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.businesses);
      if (res.data is List && (res.data as List).isNotEmpty) {
        return (res.data as List).first['id']?.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<FinancialReportModel> getReport({String period = 'month'}) async {
    final bizId = await getDefaultBusinessId();
    final queryParams = bizId != null ? {'business_id': bizId} : <String, dynamic>{};

    final apiPeriod = (period == 'all') ? 'month' : period;

    double income = 0.0;
    double expenses = 0.0;
    double profit = 0.0;
    int count = 0;
    List<CategoryBreakdownItem> incomeBreakdown = [];
    List<CategoryBreakdownItem> expenseBreakdown = [];

    try {
      final incomeRes = await apiClient.dio.get(
        '/financials/income/$apiPeriod',
        queryParameters: queryParams,
      );
      if (incomeRes.data is Map) {
        final data = incomeRes.data as Map<String, dynamic>;
        income = (data['total_income'] as num?)?.toDouble() ?? 0.0;
        if (data['breakdown'] is List) {
          final list = data['breakdown'] as List;
          incomeBreakdown = list
              .map((e) => CategoryBreakdownItem.fromJson(e as Map<String, dynamic>, income))
              .toList();
        }
      }
    } catch (_) {}

    try {
      final expenseRes = await apiClient.dio.get(
        '/financials/expenses/$apiPeriod',
        queryParameters: queryParams,
      );
      if (expenseRes.data is Map) {
        final data = expenseRes.data as Map<String, dynamic>;
        expenses = (data['total_expenses'] as num?)?.toDouble() ??
            (data['total_expense'] as num?)?.toDouble() ??
            0.0;
        if (data['breakdown'] is List) {
          final list = data['breakdown'] as List;
          expenseBreakdown = list
              .map((e) => CategoryBreakdownItem.fromJson(e as Map<String, dynamic>, expenses))
              .toList();
        }
      }
    } catch (_) {}

    try {
      final profitRes = await apiClient.dio.get(
        '/financials/profit/$apiPeriod',
        queryParameters: queryParams,
      );
      if (profitRes.data is Map) {
        final data = profitRes.data as Map<String, dynamic>;
        profit = (data['profit'] as num?)?.toDouble() ?? (income - expenses);
        count = (data['transaction_count'] as num?)?.toInt() ?? 0;
      }
    } catch (_) {
      profit = income - expenses;
    }

    // Fetch transactions for real daily chart points
    List<DailyChartPoint> chartPoints = [];
    try {
      final txRes = await apiClient.dio.get(
        ApiEndpoints.transactions,
        queryParameters: queryParams,
      );
      if (txRes.data is List) {
        final txList = (txRes.data as List)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();

        chartPoints = _buildChartPoints(txList, period);
      }
    } catch (_) {}

    if (chartPoints.isEmpty) {
      chartPoints = _buildDefaultEmptyPoints(period);
    }

    return FinancialReportModel(
      period: period,
      totalIncome: income,
      totalExpenses: expenses,
      netProfit: profit,
      transactionCount: count,
      incomeBreakdown: incomeBreakdown,
      expenseBreakdown: expenseBreakdown,
      chartPoints: chartPoints,
    );
  }

  List<DailyChartPoint> _buildChartPoints(List<TransactionModel> txList, String period) {
    final now = DateTime.now();

    if (period == 'week') {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      return List.generate(7, (i) {
        final dayDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + i);
        double dayIncome = 0;
        double dayExpense = 0;

        for (final tx in txList) {
          if (tx.date != null &&
              tx.date!.year == dayDate.year &&
              tx.date!.month == dayDate.month &&
              tx.date!.day == dayDate.day) {
            if (tx.type == 'income') {
              dayIncome += tx.amount;
            } else {
              dayExpense += tx.amount;
            }
          }
        }

        return DailyChartPoint(
          label: days[i],
          date: dayDate,
          income: dayIncome,
          expense: dayExpense,
        );
      });
    }

    // Default to last 5 weeks or intervals for month / all
    final points = <DailyChartPoint>[];
    for (int i = 4; i >= 0; i--) {
      final weekDate = now.subtract(Duration(days: i * 6));
      final weekStart = weekDate.subtract(const Duration(days: 6));
      double wIncome = 0;
      double wExpense = 0;

      for (final tx in txList) {
        if (tx.date != null &&
            tx.date!.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
            tx.date!.isBefore(weekDate.add(const Duration(days: 1)))) {
          if (tx.type == 'income') {
            wIncome += tx.amount;
          } else {
            wExpense += tx.amount;
          }
        }
      }

      points.add(DailyChartPoint(
        label: 'W${5 - i}',
        date: weekDate,
        income: wIncome,
        expense: wExpense,
      ));
    }

    return points;
  }

  List<DailyChartPoint> _buildDefaultEmptyPoints(String period) {
    if (period == 'week') {
      final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days.map((d) => DailyChartPoint(label: d, date: DateTime.now(), income: 0, expense: 0)).toList();
    }
    return [
      DailyChartPoint(label: 'W1', date: DateTime.now(), income: 0, expense: 0),
      DailyChartPoint(label: 'W2', date: DateTime.now(), income: 0, expense: 0),
      DailyChartPoint(label: 'W3', date: DateTime.now(), income: 0, expense: 0),
      DailyChartPoint(label: 'W4', date: DateTime.now(), income: 0, expense: 0),
    ];
  }

  Future<String> exportReportCsv({String period = 'month'}) async {
    final bizId = await getDefaultBusinessId();
    final queryParams = <String, dynamic>{'period': period};
    if (bizId != null) queryParams['business_id'] = bizId;

    final res = await apiClient.dio.get<String>(
      '/financials/export/csv',
      queryParameters: queryParams,
    );
    return res.data ?? '';
  }
}
