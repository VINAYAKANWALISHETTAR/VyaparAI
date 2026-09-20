import 'package:vypara_ai/features/home/data/models/dashboard_summary_model.dart';

abstract class HomeRepository {
  Future<DashboardSummaryModel> getDashboardSummary();
}
