import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
import 'package:vypara_ai/features/home/providers/home_provider.dart';
import 'package:vypara_ai/features/transactions/providers/transactions_provider.dart';
import 'package:vypara_ai/features/uploads/data/models/ocr_result_model.dart';
import 'package:vypara_ai/features/uploads/providers/upload_provider.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  String _selectedMode = 'Document'; // Photo, Document, Auto Capture
  bool _isFlashOn = false;

  Future<void> _captureFromCamera() async {
    ref.read(uploadProvider.notifier).reset();
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      await _processOcrBytes(bytes, file.name.isNotEmpty ? file.name : 'camera_scan.jpg');
    } catch (_) {
      _showSnackbar('Camera error. Please pick from gallery.');
    }
  }

  Future<void> _pickFromGallery() async {
    ref.read(uploadProvider.notifier).reset();
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      await _processOcrBytes(bytes, file.name.isNotEmpty ? file.name : 'gallery_scan.jpg');
    } catch (_) {
      _showSnackbar('Gallery error.');
    }
  }

  Future<void> _processOcrBytes(Uint8List bytes, String name) async {
    if (!mounted) return;
    _showProcessingDialog();

    await ref.read(uploadProvider.notifier).processUpload(
      bytes: bytes,
      fileName: name,
    );

    if (!mounted) return;
    try {
      Navigator.of(context, rootNavigator: true).pop();
    } catch (_) {}

    final uploadState = ref.read(uploadProvider);
    if (uploadState.isCancelled) return;
    if (uploadState.error != null) {
      _showSnackbar(uploadState.error!);
      return;
    }
    if (uploadState.result != null) {
      _showReviewBottomSheet(uploadState.result!);
    }
  }

  void _showProcessingDialog() {
    final tr = ref.read(appTranslationsProvider);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 18),
                  Text(
                    tr('scanning_extracting'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showReviewBottomSheet(OcrResultModel result) {
    final tr = ref.read(appTranslationsProvider);
    final customerController = TextEditingController(
      text: result.customerName ?? result.businessName ?? '',
    );
    final amountController = TextEditingController(
      text: (result.totalAmount != null && result.totalAmount! > 0)
          ? result.totalAmount!.toStringAsFixed(2)
          : '',
    );
    final invoiceNumController = TextEditingController(
      text: result.invoiceNumber ?? '',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        tr('extracted_document'),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (result.ocrStatus == 'extracted' && result.confidence > 0.6)
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      (result.ocrStatus == 'extracted' && result.confidence > 0.6)
                          ? '${tr('ai_confidence')}: ${(result.confidence * 100).toInt()}%'
                          : tr('review_required'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: (result.ocrStatus == 'extracted' && result.confidence > 0.6)
                            ? const Color(0xFF059669)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ),
                ],
              ),
              if (result.message != null && result.message!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    result.message!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: customerController,
                decoration: InputDecoration(
                  labelText: '${tr('customer_vendor_name')} *',
                  hintText: tr('customer_vendor_name'),
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${tr('invoice_amount')} *',
                  hintText: tr('enter_amount'),
                  prefixIcon: const Icon(Icons.currency_rupee),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: invoiceNumController,
                decoration: InputDecoration(
                  labelText: tr('invoice_num_optional'),
                  prefixIcon: const Icon(Icons.tag),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final amt = double.tryParse(amountController.text.replaceAll(',', '').trim()) ?? 0;
                  final cust = customerController.text.trim();
                  final inv = invoiceNumController.text.trim();

                  if (cust.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr('enter_customer_vendor_name')),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }
                  if (amt <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr('enter_valid_amount')),
                        backgroundColor: AppColors.error,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx);

                  final success = await ref.read(uploadProvider.notifier).confirmAndSave(
                    vendor: cust,
                    amount: amt,
                    invoiceNum: inv,
                  );

                  if (mounted) {
                    if (success) {
                      ref.read(homeProvider.notifier).loadDashboard();
                      ref.read(transactionsProvider.notifier).loadTransactions();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tr('document_recorded_success', {'amount': amt.toStringAsFixed(0)})),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      context.pop();
                    } else {
                      _showSnackbar(tr('failed_confirm_invoice'));
                    }
                  }
                },
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: Text(
                  tr('confirm_record_sale'),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSnackbar(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(appTranslationsProvider);

    final modes = [
      (key: 'Photo', label: tr('mode_photo')),
      (key: 'Document', label: tr('mode_document')),
      (key: 'Auto Capture', label: tr('mode_auto_capture')),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          tr('scan_document'),
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
            ),
            onPressed: () => setState(() => _isFlashOn = !_isFlashOn),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Viewfinder Area (Matches Screen 7)
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155), width: 1.5),
                ),
                child: Stack(
                  children: [
                    // Mock Document Texture / Guide Frame
                    Center(
                      child: Container(
                        margin: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.04),
                          border: Border.all(
                            color: const Color(0xFF60A5FA),
                            width: 2.0,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.document_scanner_outlined,
                                size: 54,
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                tr('position_doc_frame'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Top/Bottom corner indicators
                    Positioned(
                      top: 24,
                      left: 24,
                      child: _buildCornerBracket(isTop: true, isLeft: true),
                    ),
                    Positioned(
                      top: 24,
                      right: 24,
                      child: _buildCornerBracket(isTop: true, isLeft: false),
                    ),
                    Positioned(
                      bottom: 24,
                      left: 24,
                      child: _buildCornerBracket(isTop: false, isLeft: true),
                    ),
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: _buildCornerBracket(isTop: false, isLeft: false),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Mode Selector Pill ([Photo], [Document], [Auto Capture])
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Row(
                children: modes.map((m) {
                  final isSelected = _selectedMode == m.key;
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedMode = m.key),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Center(
                          child: Text(
                            m.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.black : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Bottom Shutter & Controls Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Gallery Pick Button
                  IconButton(
                    icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 28),
                    onPressed: _pickFromGallery,
                    tooltip: tr('gallery'),
                  ),

                  // Shutter Capture Button
                  GestureDetector(
                    onTap: _captureFromCamera,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                      child: Center(
                        child: Container(
                          width: 54,
                          height: 54,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Camera Switch / Settings
                  IconButton(
                    icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white, size: 28),
                    onPressed: _captureFromCamera,
                    tooltip: tr('camera'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerBracket({required bool isTop, required bool isLeft}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Color(0xFF3B82F6), width: 3) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Color(0xFF3B82F6), width: 3) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Color(0xFF3B82F6), width: 3) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Color(0xFF3B82F6), width: 3) : BorderSide.none,
        ),
      ),
    );
  }
}
