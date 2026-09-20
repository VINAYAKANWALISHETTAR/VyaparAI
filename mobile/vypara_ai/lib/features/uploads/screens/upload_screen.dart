import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/app/theme/app_shadows.dart';
import 'package:vypara_ai/features/home/providers/home_provider.dart';
import 'package:vypara_ai/features/transactions/providers/transactions_provider.dart';
import 'package:vypara_ai/features/uploads/providers/upload_provider.dart';

class UploadScreenPlaceholder extends ConsumerStatefulWidget {
  const UploadScreenPlaceholder({super.key});

  @override
  ConsumerState<UploadScreenPlaceholder> createState() =>
      _UploadScreenPlaceholderState();
}

class _UploadScreenPlaceholderState
    extends ConsumerState<UploadScreenPlaceholder> {
  final List<({String label, IconData icon})> _options = const [
    (label: 'Camera', icon: Icons.camera_alt_outlined),
    (label: 'Gallery', icon: Icons.photo_library_outlined),
    (label: 'Video', icon: Icons.videocam_outlined),
    (label: 'Audio', icon: Icons.graphic_eq_outlined),
    (label: 'Documents', icon: Icons.folder_open_outlined),
    (label: 'Screenshot', icon: Icons.phone_android_outlined),
  ];

  void _triggerUpload(String source) async {
    final uploadNotifier = ref.read(uploadProvider.notifier);

    // Show processing indicator
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(color: AppColors.primary),
              SizedBox(height: 16),
              Text(
                'Extracting with VyaparaAI OCR...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Process extraction with backend
    await uploadNotifier.processUpload(
      fileName: 'invoice_$source.jpg',
    );

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    _showReviewBottomSheet();
  }

  void _showReviewBottomSheet() {
    final result = ref.read(uploadProvider).result;
    if (result == null) return;

    final vendorController = TextEditingController(text: result.customerName ?? 'ABC Traders');
    final amountController = TextEditingController(text: result.totalAmount.toStringAsFixed(0));
    final invoiceNumController = TextEditingController(text: result.invoiceNumber ?? 'INV-2024-001');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.successSurface,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Text(
                      '98% Match',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              TextField(
                controller: vendorController,
                decoration: InputDecoration(
                  labelText: 'Vendor / Customer',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: invoiceNumController,
                decoration: InputDecoration(
                  labelText: 'Invoice / Receipt #',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Total Amount (₹)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                  Navigator.pop(ctx);

                  await ref.read(uploadProvider.notifier).confirmAndSave(
                        vendor: vendorController.text.trim(),
                        amount: amount,
                        invoiceNum: invoiceNumController.text.trim(),
                      );

                  // Refresh transactions and home dashboard
                  ref.read(transactionsProvider.notifier).loadTransactions();
                  ref.read(homeProvider.notifier).loadDashboard();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Document extracted and saved to Records successfully!'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    context.go('/app/records');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Confirm & Save to Records',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title - Screen 6
              const Text(
                'Upload to VyaparaAI',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle - Screen 6
              const Text(
                "Upload bills, invoices, screenshots, videos, or voice recordings, I'll extract the details for you.",
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Big Center Upload Dropzone Container - Screen 6
              InkWell(
                onTap: () => _triggerUpload('Files'),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FE),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: const Color(0xFFC7D7FE),
                      width: 1.5,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
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
                      const SizedBox(height: 2),
                      const Text(
                        'or drag and drop',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Images, PDF, Videos, Audio\n(Max 50 MB)',
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

              // 6 Options Grid - Screen 6
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _options.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, index) {
                  final opt = _options[index];
                  return InkWell(
                    onTap: () => _triggerUpload(opt.label),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: AppShadows.subtle,
                        border: Border.all(color: const Color(0xFFF2F4F7), width: 1),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF4FF),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Icon(opt.icon, color: AppColors.primary, size: 24),
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
            ],
          ),
        ),
      ),
    );
  }
}
