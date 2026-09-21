import 'package:vypara_ai/core/constants/api_endpoints.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/transactions/data/models/transaction_model.dart';

class TransactionsRemoteDataSource {
  final ApiClient apiClient;

  TransactionsRemoteDataSource(this.apiClient);

  Future<List<TransactionModel>> getTransactions({
    String? type,
    String? category,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        if (type != null && type.isNotEmpty && type != 'all') 'type': type,
        if (category != null && category.isNotEmpty) 'category': category,
      };

      final response = await apiClient.dio.get(
        ApiEndpoints.transactions,
        queryParameters: queryParams,
      );

      if (response.data is List) {
        return (response.data as List)
            .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<String?> getDefaultBusinessId() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.businesses);
      if (res.data is List && (res.data as List).isNotEmpty) {
        final first = (res.data as List).first;
        return first['id']?.toString() ?? first['_id']?.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<TransactionModel?> createTransaction(Map<String, dynamic> data) async {
    try {
      final payload = Map<String, dynamic>.from(data);
      if (!payload.containsKey('business_id') || payload['business_id'] == null) {
        final bizId = await getDefaultBusinessId();
        if (bizId != null) {
          payload['business_id'] = bizId;
        }
      }

      final response = await apiClient.dio.post(
        ApiEndpoints.transactions,
        data: payload,
      );
      if (response.data is Map) {
        return TransactionModel.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
