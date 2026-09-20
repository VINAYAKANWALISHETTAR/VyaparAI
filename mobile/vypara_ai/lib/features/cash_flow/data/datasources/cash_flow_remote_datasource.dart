import 'package:vypara_ai/core/constants/api_endpoints.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/cash_flow/data/models/cash_flow_model.dart';

class CashFlowRemoteDataSource {
  final ApiClient apiClient;

  CashFlowRemoteDataSource(this.apiClient);

  Future<CashFlowModel> getCashFlow({int days = 30}) async {
    final res = await apiClient.dio.get(
      ApiEndpoints.financialCashFlow,
      queryParameters: {'days': days},
    );

    return CashFlowModel.fromJson(res.data as Map<String, dynamic>);
  }
}
