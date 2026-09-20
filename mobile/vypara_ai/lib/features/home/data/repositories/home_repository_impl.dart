import 'package:vypara_ai/features/home/data/datasources/home_remote_datasource.dart';
import 'package:vypara_ai/features/home/data/models/dashboard_summary_model.dart';
import 'package:vypara_ai/features/home/repositories/home_repository.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl(this.remoteDataSource);

  @override
  Future<DashboardSummaryModel> getDashboardSummary() {
    return remoteDataSource.getDashboardSummary();
  }
}
