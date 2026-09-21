import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/uploads/data/datasources/ocr_remote_datasource.dart';
import 'package:vypara_ai/features/uploads/data/models/ocr_result_model.dart';

class UploadState {
  final bool isProcessing;
  final double uploadProgress; // 0.0 to 1.0
  final OcrResultModel? result;
  final String? error;
  final bool isConfirmed;
  final bool isCancelled;

  const UploadState({
    this.isProcessing = false,
    this.uploadProgress = 0.0,
    this.result,
    this.error,
    this.isConfirmed = false,
    this.isCancelled = false,
  });

  UploadState copyWith({
    bool? isProcessing,
    double? uploadProgress,
    OcrResultModel? result,
    String? error,
    bool? isConfirmed,
    bool? isCancelled,
  }) {
    return UploadState(
      isProcessing: isProcessing ?? this.isProcessing,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      result: result ?? this.result,
      // Passing null for error clears it; passing a value sets it.
      error: error,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }
}

class UploadProvider extends Notifier<UploadState> {
  late final OcrRemoteDataSource dataSource;
  CancelToken? _cancelToken;

  @override
  UploadState build() {
    dataSource = OcrRemoteDataSource(ApiClient());
    return const UploadState();
  }

  Future<void> processUpload({
    Uint8List? bytes,
    Uint8List? legacyBytes,
    String? fileName,
    String? language,
  }) async {
    final fileBytes =
        bytes ?? (legacyBytes != null ? Uint8List.fromList(legacyBytes) : null);
    if (fileBytes == null || fileBytes.isEmpty) {
      state = const UploadState(error: 'No file selected or file is empty.');
      return;
    }
    if (fileName == null || fileName.isEmpty) {
      state = const UploadState(error: 'Invalid filename.');
      return;
    }

    _cancelToken = CancelToken();
    state = const UploadState(isProcessing: true, uploadProgress: 0.0);

    try {
      final result = await dataSource.uploadInvoice(
        fileBytes: fileBytes,
        fileName: fileName,
        language: language,
        cancelToken: _cancelToken,
        onProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(
              uploadProgress: (sent / total).clamp(0.0, 1.0),
            );
          }
        },
      );
      state = state.copyWith(
        isProcessing: false,
        uploadProgress: 1.0,
        result: result,
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // User cancelled
        state = const UploadState(isCancelled: true);
      } else {
        final msg = _parseDioError(e);
        state = UploadState(error: msg);
      }
    } on UnsupportedError catch (e) {
      state = UploadState(
        error: e.message ?? 'Unsupported file type.',
      );
    } catch (_) {
      state = const UploadState(
        error: 'Failed to process document. Please try again.',
      );
    } finally {
      _cancelToken = null;
    }
  }

  void cancelUpload() {
    _cancelToken?.cancel('Cancelled by user');
    state = const UploadState(isCancelled: true);
  }

  String _parseDioError(DioException e) {
    if (e.type == DioExceptionType.connectionError) {
      return 'No internet connection. Please check your network.';
    }
    if (e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Request timed out. Please try again.';
    }
    final statusCode = e.response?.statusCode;
    final detail = e.response?.data is Map
        ? (e.response!.data as Map)['detail']?.toString()
        : null;
    if (statusCode == 400) {
      return detail ?? 'Invalid file or request. Please check the file and try again.';
    }
    if (statusCode == 401) return 'Session expired. Please log in again.';
    if (statusCode == 413) return 'File too large. Maximum size is 50MB.';
    if (statusCode == 422) return 'Unsupported file type or format.';
    if (statusCode == 500) {
      return 'Server error during OCR processing. Please try again.';
    }
    return detail ?? 'Upload failed. Please try again.';
  }

  Future<bool> confirmAndSave({
    required String vendor,
    required double amount,
    required String invoiceNum,
    String? description,
    DateTime? dueDate,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final success = await dataSource.confirmInvoice(
        customerName: vendor,
        amount: amount,
        invoiceNumber: invoiceNum.isNotEmpty ? invoiceNum : null,
        description: description,
        dueDate: dueDate,
      );
      state = state.copyWith(isProcessing: false, isConfirmed: success);
      return success;
    } on DioException catch (e) {
      final msg = _parseDioError(e);
      state = UploadState(
        result: state.result,
        error: msg,
      );
      return false;
    } catch (_) {
      state = UploadState(
        result: state.result,
        error: 'Failed to save. Please try again.',
      );
      return false;
    }
  }

  void reset() {
    state = const UploadState();
  }
}

final uploadProvider =
    NotifierProvider<UploadProvider, UploadState>(UploadProvider.new);
