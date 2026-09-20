import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/transactions/data/datasources/transactions_remote_datasource.dart';
import 'package:vypara_ai/features/transactions/data/models/transaction_model.dart';
import 'package:vypara_ai/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:vypara_ai/features/transactions/repositories/transactions_repository.dart';

class TransactionsState {
  final bool isLoading;
  final List<TransactionModel> transactions;
  final String activeFilter; // 'All', 'Income', 'Expense', 'Pending'
  final String searchQuery;
  final String? error;

  const TransactionsState({
    this.isLoading = false,
    this.transactions = const [],
    this.activeFilter = 'All',
    this.searchQuery = '',
    this.error,
  });

  List<TransactionModel> get filteredTransactions {
    return transactions.where((t) {
      if (activeFilter == 'Income' && t.type != 'income') return false;
      if (activeFilter == 'Expense' && t.type != 'expense') return false;
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchCat = t.category.toLowerCase().contains(q);
        final matchDesc = t.description?.toLowerCase().contains(q) ?? false;
        final matchRef = t.referenceId?.toLowerCase().contains(q) ?? false;
        if (!matchCat && !matchDesc && !matchRef) return false;
      }
      return true;
    }).toList();
  }

  TransactionsState copyWith({
    bool? isLoading,
    List<TransactionModel>? transactions,
    String? activeFilter,
    String? searchQuery,
    String? error,
  }) {
    return TransactionsState(
      isLoading: isLoading ?? this.isLoading,
      transactions: transactions ?? this.transactions,
      activeFilter: activeFilter ?? this.activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }
}

class TransactionsProvider extends Notifier<TransactionsState> {
  late final TransactionsRepository repository;

  @override
  TransactionsState build() {
    repository = TransactionsRepositoryImpl(
      TransactionsRemoteDataSource(ApiClient()),
    );
    Future.microtask(() => loadTransactions());
    return const TransactionsState(isLoading: true);
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      String? apiType;
      if (state.activeFilter == 'Income') apiType = 'income';
      if (state.activeFilter == 'Expense') apiType = 'expense';

      final list = await repository.getTransactions(type: apiType);
      state = state.copyWith(isLoading: false, transactions: list);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to load transactions');
    }
  }

  void setFilter(String filter) {
    state = state.copyWith(activeFilter: filter);
  }

  void search(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> addTransaction({
    required String type,
    required double amount,
    required String category,
    String? description,
  }) async {
    state = state.copyWith(isLoading: true);
    final payload = <String, dynamic>{
      'type': type.toLowerCase(),
      'amount': amount,
      'category': category,
    };
    if (description != null) {
      payload['description'] = description;
    }
    final result = await repository.createTransaction(payload);
    await loadTransactions();
    return result != null;
  }
}

final transactionsProvider =
    NotifierProvider<TransactionsProvider, TransactionsState>(TransactionsProvider.new);
