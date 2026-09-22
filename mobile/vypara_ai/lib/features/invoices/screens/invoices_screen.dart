import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/app/theme/app_shadows.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
import 'package:vypara_ai/features/invoices/data/models/invoice_model.dart';
import 'package:vypara_ai/features/invoices/providers/invoices_provider.dart';

// Backward compatibility alias for router.dart
typedef InvoicesScreenPlaceholder = InvoicesScreen;

class InvoicesScreen extends ConsumerStatefulWidget {
  const InvoicesScreen({super.key});

  @override
  ConsumerState<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends ConsumerState<InvoicesScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹ ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(appTranslationsProvider);
    final state = ref.watch(invoicesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              context.pop();
            } else {
              context.go('/app/home');
            }
          },
        ),
        title: Text(
          tr('invoices'),
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 24),
            tooltip: tr('create_invoice'),
            onPressed: () => _showCreateInvoiceSheet(context, tr),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(invoicesProvider.notifier).fetchInvoices(),
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Top Metrics Banner
            SliverToBoxAdapter(
              child: _buildSummaryBanner(state, tr),
            ),

            // Filter Chips
            SliverToBoxAdapter(
              child: _buildFilterChips(state, tr),
            ),

            // Invoices List or Empty State
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (state.filteredInvoices.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(context, state.filter, tr),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final invoice = state.filteredInvoices[index];
                      return _buildInvoiceCard(context, invoice, tr);
                    },
                    childCount: state.filteredInvoices.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateInvoiceSheet(context, tr),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          tr('new_invoice'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSummaryBanner(InvoicesState state, dynamic tr) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppShadows.subtle,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('total_outstanding_due'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _currencyFormat.format(state.totalOutstanding),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: const Color(0xFFE2E8F0),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('total_invoiced'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _currencyFormat.format(state.totalInvoiced),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${tr('total_invoices')}: ${state.invoices.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                '${tr('paid')}: ${_currencyFormat.format(state.totalPaid)}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(InvoicesState state, String Function(String, [Map<String, dynamic>?]) tr) {
    final filters = [
      {'id': 'all', 'label': tr('filter_all')},
      {'id': 'unpaid', 'label': tr('unpaid')},
      {'id': 'overdue', 'label': tr('overdue')},
      {'id': 'paid', 'label': tr('paid')},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final isSelected = state.filter == f['id'];
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: Text(
                  f['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                ),
                onSelected: (_) {
                  ref.read(invoicesProvider.notifier).setFilter(f['id']!);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context, InvoiceModel invoice, String Function(String, [Map<String, dynamic>?]) tr) {
    Color statusColor;
    Color statusBgColor;
    String statusText;

    switch (invoice.status) {
      case 'paid':
        statusColor = const Color(0xFF10B981);
        statusBgColor = const Color(0xFFECFDF5);
        statusText = tr('paid').toUpperCase();
        break;
      case 'overdue':
        statusColor = const Color(0xFFEF4444);
        statusBgColor = const Color(0xFFFEF2F2);
        statusText = tr('overdue').toUpperCase();
        break;
      case 'partially_paid':
        statusColor = const Color(0xFF3B82F6);
        statusBgColor = const Color(0xFFEFF6FF);
        statusText = tr('partial').toUpperCase();
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusBgColor = const Color(0xFFFFFBEB);
        statusText = tr('unpaid').toUpperCase();
    }

    final dateStr = invoice.dueDate != null
        ? DateFormat('dd MMM yyyy').format(invoice.dueDate!)
        : tr('no_due_date');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: AppShadows.subtle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (invoice.invoiceNumber != null && invoice.invoiceNumber!.isNotEmpty)
                        Text(
                          '#${invoice.invoiceNumber}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('amount_label'),
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    ),
                    Text(
                      _currencyFormat.format(invoice.amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                if (invoice.status != 'paid')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        tr('due_label'),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      ),
                      Text(
                        _currencyFormat.format(invoice.outstandingAmount),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          dateStr,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (invoice.status != 'paid') ...[
                      TextButton(
                        onPressed: () => _showRecordPaymentDialog(context, invoice, tr),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          tr('record_payment'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF64748B)),
                      onSelected: (val) async {
                        if (val == 'mark_paid') {
                          final ok = await ref.read(invoicesProvider.notifier).markPaid(invoice.id);
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(tr('invoice_marked_paid'))),
                            );
                          }
                        } else if (val == 'delete') {
                          final ok = await ref.read(invoicesProvider.notifier).deleteInvoice(invoice.id);
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(tr('invoice_deleted'))),
                            );
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        if (invoice.status != 'paid')
                          PopupMenuItem(
                            value: 'mark_paid',
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 18),
                                const SizedBox(width: 8),
                                Text(tr('mark_as_paid')),
                              ],
                            ),
                          ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                              const SizedBox(width: 8),
                              Text(tr('delete_invoice')),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String filter, String Function(String, [Map<String, dynamic>?]) tr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr('no_invoices'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('create_invoices_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateInvoiceSheet(context, tr),
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: Text(tr('create_first_invoice')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateInvoiceSheet(BuildContext context, String Function(String, [Map<String, dynamic>?]) tr) {
    final formKey = GlobalKey<FormState>();
    final customerCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final invoiceNumCtrl = TextEditingController(text: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}');
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 15));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tr('create_new_invoice'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(sheetCtx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: customerCtrl,
                        decoration: InputDecoration(
                          labelText: tr('customer_name_required'),
                          hintText: tr('eg_party_name'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? tr('enter_customer_name') : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: amountCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                labelText: tr('amount_required'),
                                hintText: '5000',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.currency_rupee),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return tr('enter_amount');
                                final num = double.tryParse(v);
                                if (num == null || num <= 0) return tr('valid_amount');
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: invoiceNumCtrl,
                              decoration: InputDecoration(
                                labelText: tr('invoice_num_opt'),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.tag),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today, color: AppColors.primary),
                        title: Text(tr('due_date'), style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                          DateFormat('dd MMMM yyyy').format(selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: sheetCtx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setSheetState(() => selectedDate = picked);
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: tr('description_notes'),
                          hintText: tr('items_or_terms'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState?.validate() ?? false) {
                              final amt = double.parse(amountCtrl.text.trim());
                              final ok = await ref.read(invoicesProvider.notifier).createInvoice(
                                customerName: customerCtrl.text.trim(),
                                amount: amt,
                                invoiceNumber: invoiceNumCtrl.text.trim(),
                                dueDate: selectedDate,
                                description: descCtrl.text.trim(),
                              );
                              if (sheetCtx.mounted) {
                                Navigator.pop(sheetCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(ok ? tr('invoice_created_success') : tr('invoice_create_failed')),
                                    backgroundColor: ok ? const Color(0xFF10B981) : AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: Text(
                            tr('save_invoice'),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showRecordPaymentDialog(BuildContext context, InvoiceModel invoice, String Function(String, [Map<String, dynamic>?]) tr) {
    final amountCtrl = TextEditingController(text: invoice.outstandingAmount.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dlgCtx) {
        return AlertDialog(
          title: Text('${tr('record_payment')} - ${invoice.customerName}'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${tr('outstanding_due')}: ${_currencyFormat.format(invoice.outstandingAmount)}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: tr('amount_required'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.currency_rupee),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return tr('enter_amount');
                    final val = double.tryParse(v);
                    if (val == null || val <= 0) return tr('valid_amount');
                    if (val > invoice.outstandingAmount) return tr('cannot_exceed_due');
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dlgCtx),
              child: Text(tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final payAmt = double.parse(amountCtrl.text.trim());
                  final ok = await ref.read(invoicesProvider.notifier).recordPayment(invoice.id, payAmt);
                  if (dlgCtx.mounted) {
                    Navigator.pop(dlgCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(ok ? tr('payment_recorded_success') : tr('payment_record_failed')),
                        backgroundColor: ok ? const Color(0xFF10B981) : AppColors.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(tr('confirm_payment'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
