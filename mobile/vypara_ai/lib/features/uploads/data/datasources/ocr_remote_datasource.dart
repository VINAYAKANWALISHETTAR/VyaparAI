import 'package:dio/dio.dart';
import 'package:vypara_ai/core/constants/api_endpoints.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/uploads/data/models/ocr_result_model.dart';

class OcrRemoteDataSource {
  final ApiClient apiClient;

  OcrRemoteDataSource(this.apiClient);

  Future<String?> getDefaultBusinessId() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.businesses);
      if (res.data is List && (res.data as List).isNotEmpty) {
        return (res.data as List).first['id']?.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<OcrResultModel?> uploadInvoice({
    required List<int> fileBytes,
    required String fileName,
  }) async {
    try {
      final businessId = await getDefaultBusinessId();

      final ext = fileName.split('.').last.toLowerCase();
      final mimeSubtype = (ext == 'png') ? 'png' : 'jpeg';
      final formData = FormData.fromMap({
        'business_id': ?businessId,
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: DioMediaType('image', mimeSubtype),
        ),
      });

      final response = await apiClient.dio.post(
        ApiEndpoints.ocrInvoice,
        data: formData,
      );

      if (response.data is Map) {
        final resMap = response.data as Map<String, dynamic>;
        final extracted = (resMap['extracted'] ?? resMap['extracted_data'] ?? resMap) as Map<String, dynamic>;
        return OcrResultModel.fromJson(extracted);
      }
    } catch (_) {}
    return null;
  }

  Future<bool> confirmExtraction({
    required String category,
    required double amount,
    String? description,
    String? referenceId,
  }) async {
    try {
      final businessId = await getDefaultBusinessId();
      await apiClient.dio.post(
        ApiEndpoints.transactions,
        data: {
          'business_id': ?businessId,
          'type': 'expense',
          'amount': amount,
          'category': category,
          'description': ?description,
          'reference_id': ?referenceId,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
