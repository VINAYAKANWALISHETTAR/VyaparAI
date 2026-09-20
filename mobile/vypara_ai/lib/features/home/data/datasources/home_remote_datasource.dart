import 'package:dio/dio.dart';
import 'package:vypara_ai/core/constants/api_endpoints.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/home/data/models/dashboard_summary_model.dart';

class HomeRemoteDataSource {
  final ApiClient apiClient;

  HomeRemoteDataSource(this.apiClient);

  Future<DashboardSummaryModel> getDashboardSummary() async {
    double income = 0.0;
    double? incomeChange;
    double expenses = 0.0;
    double? expenseChange;
    double profit = 0.0;
    double cash = 0.0;
    List<String> insights = [];

    try {
      final responses = await Future.wait([
        apiClient.dio.get(ApiEndpoints.financialIncomeToday).catchError((_) => Response(requestOptions: RequestOptions())),
        apiClient.dio.get(ApiEndpoints.financialExpensesToday).catchError((_) => Response(requestOptions: RequestOptions())),
        apiClient.dio.get(ApiEndpoints.financialProfitToday).catchError((_) => Response(requestOptions: RequestOptions())),
        apiClient.dio.get(ApiEndpoints.financialCashPosition).catchError((_) => Response(requestOptions: RequestOptions())),
        apiClient.dio.get(ApiEndpoints.financialInsights).catchError((_) => Response(requestOptions: RequestOptions())),
      ]);

      // Income response
      if (responses[0].data is Map) {
        final data = responses[0].data as Map<String, dynamic>;
        income = (data['total_income'] as num?)?.toDouble() ?? 0.0;
        incomeChange = (data['change_percentage'] as num?)?.toDouble();
      }

      // Expenses response
      if (responses[1].data is Map) {
        final data = responses[1].data as Map<String, dynamic>;
        expenses = (data['total_expense'] as num?)?.toDouble() ?? 0.0;
        expenseChange = (data['change_percentage'] as num?)?.toDouble();
      }

      // Profit response
      if (responses[2].data is Map) {
        final data = responses[2].data as Map<String, dynamic>;
        profit = (data['net_profit'] as num?)?.toDouble() ?? (income - expenses);
      } else {
        profit = income - expenses;
      }

      // Cash position response
      if (responses[3].data is Map) {
        final data = responses[3].data as Map<String, dynamic>;
        cash = (data['total_cash'] as num?)?.toDouble() ?? 0.0;
      }

      // Insights response
      if (responses[4].data is Map && responses[4].data['insights'] is List) {
        final list = responses[4].data['insights'] as List;
        insights = list.map((item) {
          if (item is Map && item.containsKey('content')) {
            return item['content'].toString();
          }
          return item.toString();
        }).toList();
      }
    } catch (_) {
      // Return safe defaults if any unexpected error occurs
    }

    return DashboardSummaryModel(
      todayIncome: income,
      incomeChange: incomeChange,
      todayExpenses: expenses,
      expenseChange: expenseChange,
      todayProfit: profit,
      totalCash: cash,
      insights: insights,
    );
  }
}
