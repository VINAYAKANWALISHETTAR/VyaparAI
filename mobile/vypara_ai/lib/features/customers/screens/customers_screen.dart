import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/app/theme/app_shadows.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
import 'package:vypara_ai/features/customers/data/models/party_model.dart';
import 'package:vypara_ai/features/customers/providers/parties_provider.dart';

class CustomersScreenPlaceholder extends ConsumerStatefulWidget {
  final String initialTab;
  const CustomersScreenPlaceholder({super.key, this.initialTab = 'Customers'});

  @override
  ConsumerState<CustomersScreenPlaceholder> createState() =>
      _CustomersScreenPlaceholderState();
}

class _CustomersScreenPlaceholderState
    extends ConsumerState<CustomersScreenPlaceholder> {
  final _searchController = TextEditingController();
  String _subFilter = 'All'; // 'All', 'Due', 'Paid', 'Active'
  final List<String> _filterOptions = const ['All', 'Due', 'Paid', 'Active'];

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != 'Customers') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(partiesProvider.notifier).setTab(widget.initialTab);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    if (amount == 0) return '₹ 0';
    final isNegative = amount < 0;
    final absAmount = amount.abs();
    final str = absAmount.toStringAsFixed(0);
    String formatted = '';

    if (str.length > 3) {
      final lastThree = str.substring(str.length - 3);
      String remaining = str.substring(0, str.length - 3);
      while (remaining.length > 2) {
        formatted = ',${remaining.substring(remaining.length - 2)}$formatted';
        remaining = remaining.substring(0, remaining.length - 2);
      }
      formatted = '₹ $remaining$formatted,$lastThree';
    } else {
      formatted = '₹ $str';
    }

    return isNegative ? '-$formatted' : formatted;
  }

  void _showAddPartyModal(BuildContext context, bool isCustomer) {
    final tr = ref.read(appTranslationsProvider);
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final refController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isCustomer ? tr('add_new_customer') : tr('add_new_supplier'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: isCustomer ? tr('customer_business_name') : tr('supplier_name'),
                    hintText: isCustomer ? tr('customer_business_name') : tr('supplier_name'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: isCustomer ? tr('opening_due_balance') : tr('opening_balance_bill'),
                    hintText: '0.00',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refController,
                  decoration: InputDecoration(
                    labelText: isCustomer ? tr('invoice_num_optional') : tr('category_optional'),
                    hintText: isCustomer ? tr('invoice_num_optional') : tr('category_optional'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: tr('description_notes'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final amount = double.tryParse(amountController.text.trim()) ?? 0.0;
                    if (name.isEmpty || amount <= 0) return;

                    Navigator.pop(ctx);

                    if (isCustomer) {
                      await ref.read(partiesProvider.notifier).addCustomer(
                            name: name,
                            amount: amount,
                            invoiceNumber: refController.text.trim(),
                            description: descController.text.trim(),
                          );
                    } else {
                      await ref.read(partiesProvider.notifier).addSupplier(
                            name: name,
                            amount: amount,
                            category: refController.text.trim().isNotEmpty
                                ? refController.text.trim()
                                : 'Supplier Payment',
                          );
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isCustomer
                                ? '$name: ${tr('saved')}'
                                : '$name: ${tr('saved')}',
                          ),
                          backgroundColor: const Color(0xFF0F764F),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    isCustomer ? tr('save_customer') : tr('save_supplier'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRecordPaymentModal(BuildContext context, PartyModel party) {
    final tr = ref.read(appTranslationsProvider);
    final payController = TextEditingController(text: party.outstandingAmount.toStringAsFixed(0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr('record_payment_from', {'name': party.name}),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  tr('outstanding_balance_label', {'amount': _formatAmount(party.outstandingAmount)}),
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: payController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: tr('payment_received_inr'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final amt = double.tryParse(payController.text.trim()) ?? 0.0;
                    if (amt <= 0) return;
                    Navigator.pop(ctx);

                    if (party.lastInvoiceId != null) {
                      await ref.read(partiesProvider.notifier).recordPayment(
                            invoiceId: party.lastInvoiceId!,
                            amount: amt,
                          );
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tr('payment_recorded', {'amount': _formatAmount(amt)})),
                          backgroundColor: const Color(0xFF0F764F),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F764F),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(tr('confirm_payment'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showReminderPreview(BuildContext context, PartyModel party) {
    final tr = ref.read(appTranslationsProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Row(
          children: [
            const Icon(Icons.message_outlined, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Text(tr('payment_reminder'), style: const TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('msg_preview_label'),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.outline),
              ),
              child: Text(
                tr('payment_reminder_template', {
                  'name': party.name,
                  'amount': _formatAmount(party.outstandingAmount),
                }),
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(tr('cancel')),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final reminderText = tr('payment_reminder_template', {
                'name': party.name,
                'amount': _formatAmount(party.outstandingAmount),
              });
              try {
                await SharePlus.instance.share(ShareParams(text: reminderText, subject: 'VyaparAI Payment Reminder: ${party.name}'));
              } catch (_) {}
            },
            icon: const Icon(Icons.share, size: 16),
            label: Text(tr('send_reminder')),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F764F),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(appTranslationsProvider);
    final state = ref.watch(partiesProvider);
    final isCustomer = state.activeTab == 'Customers';
    final parties = state.currentList;

    final filterLabels = {
      'All': tr('filter_all'),
      'Due': tr('due_label'),
      'Paid': tr('paid'),
      'Active': tr('active'),
    };

    final filteredParties = parties.where((p) {
      if (_subFilter == 'Due') return p.outstandingAmount > 0;
      if (_subFilter == 'Paid') return p.outstandingAmount <= 0;
      if (_subFilter == 'Active') return p.count > 0;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(partiesProvider.notifier).loadParties(),
        child: Column(
          children: [
            // Top Toggle & Search Bar Container
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Segmented Switch - Screen 9
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      children: [
                        _buildTab('${tr('customers')} (${state.customers.length})', 'Customers', state.activeTab),
                        _buildTab('${tr('suppliers')} (${state.suppliers.length})', 'Suppliers', state.activeTab),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Search input
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => ref.read(partiesProvider.notifier).search(v),
                    decoration: InputDecoration(
                      hintText: isCustomer
                          ? '${tr('customers')}...'
                          : '${tr('suppliers')}...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textTertiary),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // KPI Summary Strip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isCustomer ? const Color(0xFFE8F8F0) : const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCustomer ? tr('you_will_get') : tr('you_will_give'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isCustomer ? const Color(0xFF0F764F) : AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _formatAmount(isCustomer ? state.totalReceivables : state.totalPayables),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isCustomer ? const Color(0xFF0F764F) : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${parties.length} ${isCustomer ? tr('parties') : tr('suppliers')}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isCustomer ? const Color(0xFF0F764F) : AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Sub-filter horizontal chips (All, Due, Paid, Active)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _filterOptions.map((f) {
                    final isSel = _subFilter == f;
                    final labelText = filterLabels[f] ?? f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          labelText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                            color: isSel ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        selected: isSel,
                        selectedColor: AppColors.primary,
                        backgroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        side: BorderSide(
                          color: isSel ? AppColors.primary : const Color(0xFFE2E8F0),
                        ),
                        onSelected: (_) => setState(() => _subFilter = f),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // Party List
            Expanded(
              child: filteredParties.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCustomer ? Icons.people_outline : Icons.local_shipping_outlined,
                            size: 52,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isCustomer ? tr('no_customers_found') : tr('no_suppliers_found'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              isCustomer ? tr('tap_add_customer') : tr('tap_add_supplier'),
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredParties.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final party = filteredParties[index];
                        final hasDue = party.outstandingAmount > 0;
                        final initial = party.name.isNotEmpty ? party.name[0].toUpperCase() : 'P';

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            boxShadow: AppShadows.subtle,
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  // Initial Avatar
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: isCustomer
                                        ? const Color(0xFFE8F8F0)
                                        : const Color(0xFFFFF0F0),
                                    child: Text(
                                      initial,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isCustomer
                                            ? const Color(0xFF0F764F)
                                            : AppColors.error,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name and count
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          party.name,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${party.count} ${isCustomer ? tr('invoices') : tr('records')}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Outstanding badge
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          _formatAmount(party.outstandingAmount),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            color: hasDue
                                                ? (isCustomer ? AppColors.error : const Color(0xFF0F764F))
                                                : const Color(0xFF0F764F),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: hasDue
                                              ? (isCustomer
                                                  ? const Color(0xFFFFF0F0)
                                                  : const Color(0xFFE8F8F0))
                                              : const Color(0xFFE8F8F0),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          hasDue ? tr('due_label') : tr('settled'),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: hasDue
                                                ? (isCustomer ? AppColors.error : const Color(0xFF0F764F))
                                                : const Color(0xFF0F764F),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              if (isCustomer && hasDue) ...[
                                const Divider(height: 20),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Wrap(
                                    alignment: WrapAlignment.end,
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: [
                                      OutlinedButton.icon(
                                        onPressed: () => _showReminderPreview(context, party),
                                        icon: const Icon(Icons.notifications_active_outlined, size: 14),
                                        label: Text(tr('remind'), style: const TextStyle(fontSize: 12)),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.primary,
                                          side: const BorderSide(color: AppColors.primary),
                                          shape: const StadiumBorder(),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _showRecordPaymentModal(context, party),
                                        icon: const Icon(Icons.check_circle_outline, size: 14),
                                        label: Text(tr('payment'), style: const TextStyle(fontSize: 12)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0F764F),
                                          foregroundColor: Colors.white,
                                          shape: const StadiumBorder(),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPartyModal(context, isCustomer),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(
          isCustomer ? tr('add_customer') : tr('add_supplier'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildTab(String title, String key, String activeTab) {
    final isSelected = activeTab == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(partiesProvider.notifier).setTab(key),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
