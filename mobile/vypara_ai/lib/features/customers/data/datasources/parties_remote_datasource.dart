import 'package:vypara_ai/core/constants/api_endpoints.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/customers/data/models/party_model.dart';

class PartiesRemoteDataSource {
  final ApiClient apiClient;

  PartiesRemoteDataSource(this.apiClient);

  Future<String?> getDefaultBusinessId() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.businesses);
      if (res.data is List && (res.data as List).isNotEmpty) {
        return (res.data as List).first['id']?.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> getCustomersData() async {
    final bizId = await getDefaultBusinessId();
    final query = bizId != null ? {'business_id': bizId} : <String, dynamic>{};

    double totalReceivables = 0.0;
    List<PartyModel> customers = [];

    try {
      final res = await apiClient.dio.get(
        ApiEndpoints.financialReceivablesCustomerSummary,
        queryParameters: query,
      );
      if (res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        totalReceivables = (data['total_receivables'] as num?)?.toDouble() ?? 0.0;
        if (data['customers'] is List) {
          customers = (data['customers'] as List)
              .map((c) => PartyModel.fromCustomerJson(c as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}

    // Cross-link with live invoices list to enrich invoice IDs
    try {
      final invRes = await apiClient.dio.get(ApiEndpoints.invoices);
      if (invRes.data is List) {
        final invList = invRes.data as List;
        for (int i = 0; i < customers.length; i++) {
          final c = customers[i];
          final matching = invList.firstWhere(
            (inv) => inv['customer_name'] == c.name,
            orElse: () => null,
          );
          if (matching != null && matching is Map) {
            customers[i] = PartyModel(
              id: c.id,
              name: c.name,
              type: 'customer',
              totalAmount: c.totalAmount,
              paidAmount: c.paidAmount,
              outstandingAmount: c.outstandingAmount,
              count: c.count,
              lastInvoiceId: matching['id']?.toString(),
            );
          }
        }
      }
    } catch (_) {}

    return {
      'total': totalReceivables,
      'parties': customers,
    };
  }

  Future<Map<String, dynamic>> getSuppliersData() async {
    final bizId = await getDefaultBusinessId();
    final query = bizId != null ? {'business_id': bizId} : <String, dynamic>{};

    double totalPayables = 0.0;
    List<PartyModel> suppliers = [];

    try {
      final res = await apiClient.dio.get(
        ApiEndpoints.financialLiabilitiesSupplierSummary,
        queryParameters: query,
      );
      if (res.data is Map) {
        final data = res.data as Map<String, dynamic>;
        totalPayables = (data['total_payables'] as num?)?.toDouble() ?? 0.0;
        if (data['suppliers'] is List) {
          suppliers = (data['suppliers'] as List)
              .map((s) => PartyModel.fromSupplierJson(s as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (_) {}

    return {
      'total': totalPayables,
      'parties': suppliers,
    };
  }

  Future<bool> addCustomerInvoice({
    required String customerName,
    required double amount,
    String? invoiceNumber,
    String? description,
    DateTime? dueDate,
  }) async {
    try {
      final bizId = await getDefaultBusinessId();
      if (bizId == null) return false;

      final formattedDate = (dueDate ?? DateTime.now().add(const Duration(days: 15)))
          .toIso8601String()
          .split('T')
          .first;

      await apiClient.dio.post(
        ApiEndpoints.invoices,
        data: {
          'business_id': bizId,
          'customer_name': customerName,
          'amount': amount,
          'due_date': formattedDate,
          if (invoiceNumber != null && invoiceNumber.isNotEmpty)
            'invoice_number': invoiceNumber,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addSupplierExpense({
    required String supplierName,
    required double amount,
    String? category,
  }) async {
    try {
      final bizId = await getDefaultBusinessId();
      if (bizId == null) return false;

      await apiClient.dio.post(
        ApiEndpoints.transactions,
        data: {
          'business_id': bizId,
          'type': 'expense',
          'amount': amount,
          'category': category ?? 'Supplier Payment',
          'description': supplierName,
          'date': DateTime.now().toIso8601String().split('T').first,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> recordPayment({
    required String invoiceId,
    required double amount,
  }) async {
    try {
      await apiClient.dio.post(
        '/payments',
        data: {'amount': amount},
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
