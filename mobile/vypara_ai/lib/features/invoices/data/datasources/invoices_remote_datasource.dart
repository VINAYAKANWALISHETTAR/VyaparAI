import 'package:vypara_ai/core/constants/api_endpoints.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/invoices/data/models/invoice_model.dart';

class InvoicesRemoteDataSource {
  final ApiClient apiClient;

  InvoicesRemoteDataSource(this.apiClient);

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

  Future<List<InvoiceModel>> getInvoices() async {
    try {
      final response = await apiClient.dio.get(ApiEndpoints.invoices);
      if (response.data is List) {
        return (response.data as List)
            .map((item) => InvoiceModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<InvoiceModel?> createInvoice(Map<String, dynamic> data) async {
    try {
      final payload = Map<String, dynamic>.from(data);
      if (!payload.containsKey('business_id') || payload['business_id'] == null) {
        final bizId = await getDefaultBusinessId();
        if (bizId != null) {
          payload['business_id'] = bizId;
        }
      }

      final response = await apiClient.dio.post(
        ApiEndpoints.invoices,
        data: payload,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return InvoiceModel.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateStatus(String invoiceId, String status) async {
    try {
      final response = await apiClient.dio.patch(
        '${ApiEndpoints.invoices}$invoiceId/status',
        data: {'status': status},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> recordPayment(String invoiceId, double amount) async {
    try {
      final response = await apiClient.dio.post(
        '${ApiEndpoints.invoices}$invoiceId/payments',
        data: {'amount': amount},
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteInvoice(String invoiceId) async {
    try {
      final response = await apiClient.dio.delete(
        '${ApiEndpoints.invoices}$invoiceId',
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
