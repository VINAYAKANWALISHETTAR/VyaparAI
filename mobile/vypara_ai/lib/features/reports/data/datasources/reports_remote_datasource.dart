import 'package:dio/dio.dart';
import 'package:vypara_ai/core/constants/api_endpoints.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/reports/data/models/financial_report_model.dart';
import 'package:vypara_ai/features/transactions/data/models/transaction_model.dart';

class ReportsRemoteDataSource {
  final ApiClient apiClient;

  ReportsRemoteDataSource(this.apiClient);

  String? _cachedBusinessId;

  Future<String?> getDefaultBusinessId() async {
    if (_cachedBusinessId != null) return _cachedBusinessId;
    try {
      final res = await apiClient.dio.get(ApiEndpoints.businesses);
      if (res.data is List && (res.data as List).isNotEmpty) {
        _cachedBusinessId = (res.data as List).first['id']?.toString();
        return _cachedBusinessId;
      }
    } catch (_) {}
    return null;
  }

  Future<FinancialReportModel> getReport({String period = 'month'}) async {
    final apiPeriod = period;

    // 1. High-Speed Consolidated Endpoint Call (sub-50ms)
    try {
      final overviewRes = await apiClient.dio.get(
        '/financials/report-overview/$apiPeriod',
      );

      if (overviewRes.data is Map) {
        final data = overviewRes.data as Map<String, dynamic>;
        final double income = (data['total_income'] as num?)?.toDouble() ?? 0.0;
        final double expenses = (data['total_expenses'] as num?)?.toDouble() ?? 0.0;
        final double profit = (data['net_profit'] as num?)?.toDouble() ?? (income - expenses);
        final int count = (data['transaction_count'] as num?)?.toInt() ?? 0;

        List<CategoryBreakdownItem> incomeBreakdown = [];
        if (data['income_breakdown'] is List) {
          incomeBreakdown = (data['income_breakdown'] as List)
              .map((e) => CategoryBreakdownItem.fromJson(e as Map<String, dynamic>, income))
              .toList();
        }

        List<CategoryBreakdownItem> expenseBreakdown = [];
        if (data['expense_breakdown'] is List) {
          expenseBreakdown = (data['expense_breakdown'] as List)
              .map((e) => CategoryBreakdownItem.fromJson(e as Map<String, dynamic>, expenses))
              .toList();
        }

        List<DailyChartPoint> chartPoints = [];
        if (data['transactions'] is List) {
          final txList = (data['transactions'] as List)
              .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
              .toList();
          chartPoints = _buildChartPoints(txList, period);
        }

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
    } catch (_) {
      // Fallback to parallel execution below if overview endpoint has issues
    }

    // 2. Parallel Fallback (Runs all 4 requests concurrently via Future.wait)
    double income = 0.0;
    double expenses = 0.0;
    double profit = 0.0;
    int count = 0;
    List<CategoryBreakdownItem> incomeBreakdown = [];
    List<CategoryBreakdownItem> expenseBreakdown = [];
    List<DailyChartPoint> chartPoints = [];

    try {
      final results = await Future.wait([
        apiClient.dio.get('/financials/income/$apiPeriod').catchError((_) => null as dynamic),
        apiClient.dio.get('/financials/expenses/$apiPeriod').catchError((_) => null as dynamic),
        apiClient.dio.get('/financials/profit/$apiPeriod').catchError((_) => null as dynamic),
        apiClient.dio.get(ApiEndpoints.transactions).catchError((_) => null as dynamic),
      ]);

      final incomeRes = results[0];
      if (incomeRes.data is Map) {
        final data = incomeRes.data as Map<String, dynamic>;
        income = (data['total_income'] as num?)?.toDouble() ?? 0.0;
        if (data['breakdown'] is List) {
          incomeBreakdown = (data['breakdown'] as List)
              .map((e) => CategoryBreakdownItem.fromJson(e as Map<String, dynamic>, income))
              .toList();
        }
      }

      final expenseRes = results[1];
      if (expenseRes.data is Map) {
        final data = expenseRes.data as Map<String, dynamic>;
        expenses = (data['total_expenses'] as num?)?.toDouble() ?? 0.0;
        if (data['breakdown'] is List) {
          expenseBreakdown = (data['breakdown'] as List)
              .map((e) => CategoryBreakdownItem.fromJson(e as Map<String, dynamic>, expenses))
              .toList();
        }
      }

      final profitRes = results[2];
      if (profitRes.data is Map) {
        final data = profitRes.data as Map<String, dynamic>;
        profit = (data['profit'] as num?)?.toDouble() ?? (income - expenses);
        count = (data['transaction_count'] as num?)?.toInt() ?? 0;
      } else {
        profit = income - expenses;
      }

      final txRes = results[3];
      if (txRes.data is List) {
        final txList = (txRes.data as List)
            .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
            .toList();
        chartPoints = _buildChartPoints(txList, period);
      }
    } catch (_) {
      profit = income - expenses;
    }

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
    final queryParams = <String, dynamic>{'period': period};

    final res = await apiClient.dio.get<String>(
      '/financials/export/csv',
      queryParameters: queryParams,
      options: Options(responseType: ResponseType.plain),
    );
    return res.data ?? '';
  }

  Future<List<int>> downloadReportPdf({String period = 'month'}) async {
    final res = await apiClient.dio.get<List<int>>(
      '/financials/report-pdf/$period',
      options: Options(responseType: ResponseType.bytes),
    );
    return res.data ?? <int>[];
  }
}
