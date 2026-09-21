import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
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
        final biz = (res.data as List).first as Map<String, dynamic>;
        return biz['id']?.toString() ?? biz['_id']?.toString();
      }
    } catch (_) {}
    return null;
  }

  Future<OcrResultModel> uploadInvoice({
    required Uint8List fileBytes,
    required String fileName,
    void Function(int sent, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    final businessId = await getDefaultBusinessId();

    // Detect MIME type from filename
    final mimeType = lookupMimeType(fileName) ?? 'image/jpeg';
    final mimeParts = mimeType.split('/');
    final mimeMainType = mimeParts[0];
    final mimeSubType = mimeParts.length > 1 ? mimeParts[1] : 'jpeg';

    // Backend only accepts image/* for /ocr/invoice
    if (mimeMainType != 'image') {
      throw UnsupportedError(
        'Only image files are supported for OCR. Received: $mimeType',
      );
    }

    final formFields = <String, dynamic>{
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
        contentType: DioMediaType(mimeMainType, mimeSubType),
      ),
    };
    if (businessId != null) {
      formFields['business_id'] = businessId;
    }

    final formData = FormData.fromMap(formFields);

    final response = await apiClient.dio.post(
      ApiEndpoints.ocrInvoice,
      data: formData,
      cancelToken: cancelToken,
      onSendProgress: onProgress,
    );

    if (response.data is Map) {
      return OcrResultModel.fromJson(response.data as Map<String, dynamic>);
    }
    throw const FormatException('Unexpected OCR response format');
  }

  Future<bool> confirmInvoice({
    required String customerName,
    required double amount,
    String? invoiceNumber,
    String? description,
    DateTime? dueDate,
  }) async {
    final businessId = await getDefaultBusinessId();

    final cleanName = customerName.trim();
    if (cleanName.isEmpty) {
      throw ArgumentError('Customer or vendor name cannot be empty');
    }
    if (amount <= 0) {
      throw ArgumentError('Invoice amount must be greater than zero');
    }

    final body = <String, dynamic>{
      'customer_name': cleanName,
      'amount': amount,
    };
    if (businessId != null) body['business_id'] = businessId;
    if (invoiceNumber != null && invoiceNumber.trim().isNotEmpty) {
      body['invoice_number'] = invoiceNumber.trim();
    }
    if (description != null && description.trim().isNotEmpty) {
      body['description'] = description.trim();
    }
    final effectiveDue = dueDate ?? DateTime.now();
    body['due_date'] = '${effectiveDue.year.toString().padLeft(4, '0')}-${effectiveDue.month.toString().padLeft(2, '0')}-${effectiveDue.day.toString().padLeft(2, '0')}';

    await apiClient.dio.post(
      ApiEndpoints.ocrInvoiceConfirm,
      data: body,
    );
    return true;
  }

  /// Legacy method kept for backward compatibility.
  Future<bool> confirmExtraction({
    required String category,
    required double amount,
    String? description,
    String? referenceId,
  }) async {
    final name = (description != null && description.trim().isNotEmpty)
        ? description.trim()
        : 'Customer';
    return confirmInvoice(
      customerName: name,
      amount: amount,
      invoiceNumber: referenceId,
      description: category,
    );
  }
}
