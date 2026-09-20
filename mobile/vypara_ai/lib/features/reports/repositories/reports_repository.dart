import 'package:vypara_ai/features/reports/data/models/financial_report_model.dart';

abstract class ReportsRepository {
  Future<FinancialReportModel> getReport({String period = 'month'});
}
