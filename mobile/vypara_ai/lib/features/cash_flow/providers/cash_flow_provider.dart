import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/cash_flow/data/datasources/cash_flow_remote_datasource.dart';
import 'package:vypara_ai/features/cash_flow/data/models/cash_flow_model.dart';
import 'package:vypara_ai/features/cash_flow/data/repositories/cash_flow_repository_impl.dart';
import 'package:vypara_ai/features/cash_flow/repositories/cash_flow_repository.dart';

class CashFlowState {
  final bool isLoading;
  final int selectedDays; // 7, 15, 30, 60
  final CashFlowModel? data;
  final int? selectedIndex;
  final String? error;

  const CashFlowState({
    this.isLoading = false,
    this.selectedDays = 30,
    this.data,
    this.selectedIndex,
    this.error,
  });

  CashFlowState copyWith({
    bool? isLoading,
    int? selectedDays,
    CashFlowModel? data,
    int? selectedIndex,
    String? error,
  }) {
    return CashFlowState(
      isLoading: isLoading ?? this.isLoading,
      selectedDays: selectedDays ?? this.selectedDays,
      data: data ?? this.data,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      error: error,
    );
  }
}

class CashFlowProvider extends Notifier<CashFlowState> {
  late final CashFlowRepository repository;

  @override
  CashFlowState build() {
    repository = CashFlowRepositoryImpl(
      CashFlowRemoteDataSource(ApiClient()),
    );
    Future.microtask(() => loadCashFlow(30));
    return const CashFlowState(isLoading: true);
  }

  Future<void> loadCashFlow(int days) async {
    state = state.copyWith(isLoading: true, selectedDays: days, error: null);
    try {
      final res = await repository.getCashFlow(days: days);
      final defaultIdx = res.timeline.isNotEmpty ? (res.timeline.length - 1) : null;
      state = state.copyWith(
        isLoading: false,
        data: res,
        selectedIndex: defaultIdx,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void selectIndex(int index) {
    state = state.copyWith(selectedIndex: index);
  }
}

final cashFlowProvider =
    NotifierProvider<CashFlowProvider, CashFlowState>(CashFlowProvider.new);
