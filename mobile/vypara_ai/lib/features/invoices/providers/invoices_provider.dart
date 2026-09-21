import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/invoices/data/datasources/invoices_remote_datasource.dart';
import 'package:vypara_ai/features/invoices/data/models/invoice_model.dart';

class InvoicesState {
  final bool isLoading;
  final bool isSubmitting;
  final List<InvoiceModel> invoices;
  final String filter; // 'all', 'unpaid', 'paid', 'overdue'
  final String? error;

  const InvoicesState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.invoices = const [],
    this.filter = 'all',
    this.error,
  });

  List<InvoiceModel> get filteredInvoices {
    if (filter == 'all') return invoices;
    return invoices.where((inv) => inv.status == filter).toList();
  }

  double get totalInvoiced =>
      invoices.fold(0.0, (sum, inv) => sum + inv.amount);

  double get totalOutstanding =>
      invoices.fold(0.0, (sum, inv) => sum + inv.outstandingAmount);

  double get totalPaid =>
      invoices.fold(0.0, (sum, inv) => sum + inv.paidAmount);

  InvoicesState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<InvoiceModel>? invoices,
    String? filter,
    String? error,
  }) {
    return InvoicesState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      invoices: invoices ?? this.invoices,
      filter: filter ?? this.filter,
      error: error,
    );
  }
}

class InvoicesNotifier extends Notifier<InvoicesState> {
  late final InvoicesRemoteDataSource _dataSource;

  @override
  InvoicesState build() {
    _dataSource = InvoicesRemoteDataSource(ApiClient());
    // Fetch initial list
    Future.microtask(() => fetchInvoices());
    return const InvoicesState(isLoading: true);
  }

  Future<void> fetchInvoices() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _dataSource.getInvoices();
      state = state.copyWith(isLoading: false, invoices: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setFilter(String f) {
    state = state.copyWith(filter: f);
  }

  Future<bool> createInvoice({
    required String customerName,
    required double amount,
    String? invoiceNumber,
    DateTime? dueDate,
    String? description,
  }) async {
    state = state.copyWith(isSubmitting: true);
    try {
      final inv = await _dataSource.createInvoice({
        'customer_name': customerName,
        'amount': amount,
        if (invoiceNumber != null && invoiceNumber.isNotEmpty)
          'invoice_number': invoiceNumber,
        if (dueDate != null) 'due_date': dueDate.toIso8601String().split('T').first,
        if (description != null && description.isNotEmpty)
          'description': description,
      });
      state = state.copyWith(isSubmitting: false);
      if (inv != null) {
        state = state.copyWith(invoices: [inv, ...state.invoices]);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  Future<bool> recordPayment(String invoiceId, double amount) async {
    try {
      final ok = await _dataSource.recordPayment(invoiceId, amount);
      if (ok) {
        await fetchInvoices();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markPaid(String invoiceId) async {
    try {
      final ok = await _dataSource.updateStatus(invoiceId, 'paid');
      if (ok) {
        await fetchInvoices();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteInvoice(String invoiceId) async {
    try {
      final ok = await _dataSource.deleteInvoice(invoiceId);
      if (ok) {
        state = state.copyWith(
          invoices: state.invoices.where((i) => i.id != invoiceId).toList(),
        );
      }
      return ok;
    } catch (_) {
      return false;
    }
  }
}

final invoicesProvider =
    NotifierProvider<InvoicesNotifier, InvoicesState>(InvoicesNotifier.new);
