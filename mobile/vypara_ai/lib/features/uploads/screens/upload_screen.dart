import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mime/mime.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/app/theme/app_shadows.dart';
import 'package:vypara_ai/features/home/providers/home_provider.dart';
import 'package:vypara_ai/features/transactions/providers/transactions_provider.dart';
import 'package:vypara_ai/features/uploads/data/models/ocr_result_model.dart';
import 'package:vypara_ai/features/uploads/providers/upload_provider.dart';

class UploadScreenPlaceholder extends ConsumerStatefulWidget {
  const UploadScreenPlaceholder({super.key});

  @override
  ConsumerState<UploadScreenPlaceholder> createState() =>
      _UploadScreenPlaceholderState();
}

class _UploadScreenPlaceholderState
    extends ConsumerState<UploadScreenPlaceholder> {
  final ImagePicker _imagePicker = ImagePicker();

  /// Source options shown in the grid.
  final List<({String label, IconData icon, List<String> extensions})>
  _options = const [
    (
      label: 'Camera',
      icon: Icons.camera_alt_outlined,
      extensions: ['jpg', 'jpeg', 'png'],
    ),
    (
      label: 'Gallery',
      icon: Icons.photo_library_outlined,
      extensions: ['jpg', 'jpeg', 'png', 'webp'],
    ),
    (
      label: 'Documents',
      icon: Icons.folder_open_outlined,
      extensions: ['jpg', 'jpeg', 'png'],
    ),
    (
      label: 'Screenshot',
      icon: Icons.phone_android_outlined,
      extensions: ['jpg', 'jpeg', 'png'],
    ),
    (
      label: 'Invoice',
      icon: Icons.receipt_outlined,
      extensions: ['jpg', 'jpeg', 'png'],
    ),
    (
      label: 'Any Image',
      icon: Icons.attach_file_outlined,
      extensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'],
    ),
  ];

  // ──────────────────────────────────────────────────────────────────────────
  // File picking + upload flow
  // ──────────────────────────────────────────────────────────────────────────

  Future<void> _handleOptionTap(String label, List<String> extensions) async {
    if (label == 'Camera') {
      await _pickFromCamera();
    } else if (label == 'Gallery' || label == 'Screenshot') {
      await _pickFromGallery();
    } else {
      await _pickAndUpload(allowedExtensions: extensions);
    }
  }

  Future<void> _pickFromCamera() async {
    ref.read(uploadProvider.notifier).reset();
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      await _processFileBytes(bytes, file.name.isNotEmpty ? file.name : 'camera_capture.jpg');
    } catch (_) {
      // Fallback to file picker if camera plugin is unsupported on current platform
      await _pickAndUpload(allowedExtensions: ['jpg', 'jpeg', 'png']);
    }
  }

  Future<void> _pickFromGallery() async {
    ref.read(uploadProvider.notifier).reset();
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      await _processFileBytes(bytes, file.name.isNotEmpty ? file.name : 'gallery_image.jpg');
    } catch (_) {
      // Fallback to file picker if gallery is unsupported on current platform
      await _pickAndUpload(allowedExtensions: ['jpg', 'jpeg', 'png', 'webp']);
    }
  }

  Future<void> _pickAndUpload({List<String>? allowedExtensions}) async {
    ref.read(uploadProvider.notifier).reset();

    try {
      final file = await FilePicker.pickFile(
        type:
            allowedExtensions != null ? FileType.custom : FileType.image,
        allowedExtensions: allowedExtensions,
      );

      if (file == null) return; // user cancelled

      final Uint8List bytes = await file.readAsBytes();
      final String name = file.name;

      if (bytes.isEmpty) {
        if (mounted) {
          _showErrorSnackbar(
            'Could not read file. Please try again.',
            allowRetry: false,
          );
        }
        return;
      }

      await _processFileBytes(bytes, name);
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Failed to pick file. Please try again.');
      }
    }
  }

  Future<void> _processFileBytes(Uint8List bytes, String name) async {
    final mimeType = lookupMimeType(name);
    if (mimeType == null || !mimeType.startsWith('image/')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"$name" is not a supported image. Please upload JPG, JPEG or PNG.',
            ),
            backgroundColor: AppColors.warning,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

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
      _showErrorSnackbar(uploadState.error!);
      return;
    }
    if (uploadState.result != null) {
      final res = uploadState.result!;
      if (res.ocrStatus == 'unreadable') {
        _showErrorSnackbar(
          res.message ?? 'Could not detect readable text in this image. Please take a clearer photo.',
          allowRetry: true,
        );
      } else if (res.ocrStatus == 'unsupported') {
        _showErrorSnackbar(
          res.message ?? 'This image does not appear to contain an invoice or receipt.',
          allowRetry: true,
        );
      } else {
        _showReviewBottomSheet(res);
      }
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Processing dialog (with progress bar)
  // ──────────────────────────────────────────────────────────────────────────

  void _showProcessingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => Consumer(
            builder: (context, ref, _) {
              final uploadState = ref.watch(uploadProvider);
              final progress = uploadState.uploadProgress;
              final uploading = uploadState.isProcessing && progress < 1.0;

              return AlertDialog(
                backgroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 20),
                    Text(
                      uploading
                          ? 'Uploading…'
                          : 'Extracting with VyparaAI OCR…',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (progress > 0 && progress < 1.0) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          color: AppColors.primary,
                          backgroundColor: AppColors.primaryLight,
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        ref.read(uploadProvider.notifier).cancelUpload();
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Error snackbar
  // ──────────────────────────────────────────────────────────────────────────

  void _showErrorSnackbar(String message, {bool allowRetry = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
        action:
            allowRetry
                ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _pickAndUpload(),
                )
                : null,
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Review / confirm bottom sheet
  // ──────────────────────────────────────────────────────────────────────────

  void _showReviewBottomSheet(OcrResultModel result) {
    final vendorController = TextEditingController(
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

    final confidencePct = (result.confidence * 100).toInt();
    final hasWarning =
        result.ocrStatus == 'needs_confirmation' ||
        result.customerName == null ||
        result.customerName!.trim().isEmpty ||
        result.totalAmount == null ||
        result.totalAmount == 0 ||
        result.validationWarnings.isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      builder: (ctx) {
        return Padding(
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
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Extracted Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: hasWarning
                          ? AppColors.warningSurface
                          : AppColors.successSurface,
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      hasWarning
                          ? 'Review Required'
                          : '$confidencePct% Match',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: hasWarning
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),

              // Backend message / warning banner
              if (result.message != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningSurface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          result.message!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Vendor field
              TextField(
                controller: vendorController,
                decoration: InputDecoration(
                  labelText: 'Vendor / Customer *',
                  hintText: 'Enter vendor name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Invoice # field
              TextField(
                controller: invoiceNumController,
                decoration: InputDecoration(
                  labelText: 'Invoice / Receipt #',
                  hintText: 'Auto-extracted (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Amount field
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Total Amount (₹) *',
                  hintText: 'Enter amount',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // Extracted line items (up to 3)
              if (result.items.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Extracted Items (${result.items.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                ...result.items.take(3).map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Confirm button (watches state for loading indicator)
              Consumer(
                builder: (context, ref, _) {
                  final uploadState = ref.watch(uploadProvider);
                  return ElevatedButton(
                    onPressed:
                        uploadState.isProcessing
                            ? null
                            : () async {
                              final vendor = vendorController.text.trim();
                              final amount = double.tryParse(
                                    amountController.text
                                        .replaceAll(',', '')
                                        .trim(),
                                  ) ??
                                  0.0;

                              if (vendor.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter vendor/customer name',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }
                              if (amount <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter a valid amount',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                                return;
                              }

                              final success = await ref
                                  .read(uploadProvider.notifier)
                                  .confirmAndSave(
                                    vendor: vendor,
                                    amount: amount,
                                    invoiceNum:
                                        invoiceNumController.text.trim(),
                                  );

                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);

                              if (success) {
                                ref
                                    .read(transactionsProvider.notifier)
                                    .loadTransactions();
                                ref
                                    .read(homeProvider.notifier)
                                    .loadDashboard();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Document saved to records successfully! ✓',
                                      ),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                  context.go('/app/records');
                                }
                              } else {
                                final err = ref.read(uploadProvider).error;
                                if (mounted && err != null) {
                                  _showErrorSnackbar(err, allowRetry: false);
                                }
                              }
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withValues(alpha: 0.5),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child:
                        uploadState.isProcessing
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              'Confirm & Save to Records',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Build
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 20,
                color: AppColors.textPrimary,
              ),
              onPressed: () => context.pop(),
            )
            : null,
        title: const Text(
          'Upload to VyparaAI',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload bills, invoices, screenshots or photos — '
                "I'll extract the details for you.",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // ── Main dropzone ──────────────────────────────────────────
              InkWell(
                onTap: () => _pickAndUpload(
                  allowedExtensions: ['jpg', 'jpeg', 'png'],
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FE),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: const Color(0xFFC7D7FE),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_upload_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tap to upload',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Images: JPG, PNG (Max 50MB)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Source grid label ──────────────────────────────────────
              const Text(
                'Or choose source',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // ── 6-option grid ─────────────────────────────────────────
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _options.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.95,
                    ),
                itemBuilder: (context, index) {
                  final opt = _options[index];
                  return InkWell(
                    onTap: () =>
                        _handleOptionTap(opt.label, opt.extensions),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadows.subtle,
                        border: Border.all(
                          color: const Color(0xFFF2F4F7),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(
                              opt.icon,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            opt.label,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── Info note ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: const Color(0xFFD0DCFF)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Currently supported: JPG, JPEG, PNG images. '
                        'Upload invoices, bills, receipts or financial '
                        'documents for automatic data extraction.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
