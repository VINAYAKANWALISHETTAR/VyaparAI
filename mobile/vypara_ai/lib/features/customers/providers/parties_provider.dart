import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/customers/data/datasources/parties_remote_datasource.dart';
import 'package:vypara_ai/features/customers/data/models/party_model.dart';
import 'package:vypara_ai/features/customers/data/repositories/parties_repository_impl.dart';
import 'package:vypara_ai/features/customers/repositories/parties_repository.dart';

class PartiesState {
  final bool isLoading;
  final String activeTab; // 'Customers' or 'Suppliers'
  final String searchQuery;
  final List<PartyModel> customers;
  final List<PartyModel> suppliers;
  final double totalReceivables;
  final double totalPayables;
  final String? error;

  const PartiesState({
    this.isLoading = false,
    this.activeTab = 'Customers',
    this.searchQuery = '',
    this.customers = const [],
    this.suppliers = const [],
    this.totalReceivables = 0.0,
    this.totalPayables = 0.0,
    this.error,
  });

  List<PartyModel> get currentList {
    final list = activeTab == 'Customers' ? customers : suppliers;
    if (searchQuery.isEmpty) return list;
    final q = searchQuery.toLowerCase();
    return list.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  PartiesState copyWith({
    bool? isLoading,
    String? activeTab,
    String? searchQuery,
    List<PartyModel>? customers,
    List<PartyModel>? suppliers,
    double? totalReceivables,
    double? totalPayables,
    String? error,
  }) {
    return PartiesState(
      isLoading: isLoading ?? this.isLoading,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
      customers: customers ?? this.customers,
      suppliers: suppliers ?? this.suppliers,
      totalReceivables: totalReceivables ?? this.totalReceivables,
      totalPayables: totalPayables ?? this.totalPayables,
      error: error,
    );
  }
}

class PartiesProvider extends Notifier<PartiesState> {
  late final PartiesRepository repository;

  @override
  PartiesState build() {
    repository = PartiesRepositoryImpl(
      PartiesRemoteDataSource(ApiClient()),
    );
    Future.microtask(() => loadParties());
    return const PartiesState(isLoading: true);
  }

  Future<void> loadParties() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final custData = await repository.getCustomersData();
      final suppData = await repository.getSuppliersData();

      state = state.copyWith(
        isLoading: false,
        customers: custData['parties'] as List<PartyModel>,
        totalReceivables: custData['total'] as double,
        suppliers: suppData['parties'] as List<PartyModel>,
        totalPayables: suppData['total'] as double,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to load parties');
    }
  }

  void setTab(String tab) {
    if (state.activeTab == tab) return;
    state = state.copyWith(activeTab: tab);
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> addCustomer({
    required String name,
    required double amount,
    String? invoiceNumber,
    String? description,
    DateTime? dueDate,
  }) async {
    state = state.copyWith(isLoading: true);
    final success = await repository.addCustomerInvoice(
      customerName: name,
      amount: amount,
      invoiceNumber: invoiceNumber,
      description: description,
      dueDate: dueDate,
    );
    await loadParties();
    return success;
  }

  Future<bool> addSupplier({
    required String name,
    required double amount,
    String? category,
  }) async {
    state = state.copyWith(isLoading: true);
    final success = await repository.addSupplierExpense(
      supplierName: name,
      amount: amount,
      category: category,
    );
    await loadParties();
    return success;
  }

  Future<bool> recordPayment({
    required String invoiceId,
    required double amount,
  }) async {
    state = state.copyWith(isLoading: true);
    final success = await repository.recordPayment(
      invoiceId: invoiceId,
      amount: amount,
    );
    await loadParties();
    return success;
  }
}

final partiesProvider =
    NotifierProvider<PartiesProvider, PartiesState>(PartiesProvider.new);
