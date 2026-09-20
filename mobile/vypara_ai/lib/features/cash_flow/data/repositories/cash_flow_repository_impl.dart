import 'package:vypara_ai/features/cash_flow/data/datasources/cash_flow_remote_datasource.dart';
import 'package:vypara_ai/features/cash_flow/data/models/cash_flow_model.dart';
import 'package:vypara_ai/features/cash_flow/repositories/cash_flow_repository.dart';

class CashFlowRepositoryImpl implements CashFlowRepository {
  final CashFlowRemoteDataSource _remoteDataSource;

  CashFlowRepositoryImpl(this._remoteDataSource);

  @override
  Future<CashFlowModel> getCashFlow({int days = 30}) {
    return _remoteDataSource.getCashFlow(days: days);
  }
}
