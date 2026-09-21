import 'package:vypara_ai/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:vypara_ai/features/reports/data/models/financial_report_model.dart';
import 'package:vypara_ai/features/reports/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  final ReportsRemoteDataSource remoteDataSource;

  ReportsRepositoryImpl(this.remoteDataSource);

  @override
  Future<FinancialReportModel> getReport({String period = 'month'}) {
    return remoteDataSource.getReport(period: period);
  }

  @override
  Future<String> exportReportCsv({String period = 'month'}) {
    return remoteDataSource.exportReportCsv(period: period);
  }
}
