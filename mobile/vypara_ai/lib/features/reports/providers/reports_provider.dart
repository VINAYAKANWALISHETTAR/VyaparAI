import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:vypara_ai/features/reports/data/models/financial_report_model.dart';
import 'package:vypara_ai/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:vypara_ai/features/reports/repositories/reports_repository.dart';

class ReportsState {
  final bool isLoading;
  final String selectedPeriod;
  final FinancialReportModel? report;
  final String? error;

  const ReportsState({
    this.isLoading = false,
    this.selectedPeriod = 'month',
    this.report,
    this.error,
  });

  ReportsState copyWith({
    bool? isLoading,
    String? selectedPeriod,
    FinancialReportModel? report,
    String? error,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      report: report ?? this.report,
      error: error,
    );
  }
}

class ReportsProvider extends Notifier<ReportsState> {
  late final ReportsRepository repository;

  @override
  ReportsState build() {
    repository = ReportsRepositoryImpl(
      ReportsRemoteDataSource(ApiClient()),
    );
    Future.microtask(() => loadReport());
    return const ReportsState(isLoading: true);
  }

  Future<void> loadReport() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rep = await repository.getReport(period: state.selectedPeriod);
      state = state.copyWith(isLoading: false, report: rep);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to load report');
    }
  }

  void setPeriod(String period) {
    if (state.selectedPeriod == period) return;
    state = state.copyWith(selectedPeriod: period);
    loadReport();
  }

  Future<String> exportReportCsv() async {
    return repository.exportReportCsv(period: state.selectedPeriod);
  }

  Future<List<int>> downloadReportPdf() async {
    return repository.downloadReportPdf(period: state.selectedPeriod);
  }
}

final reportsProvider =
    NotifierProvider<ReportsProvider, ReportsState>(ReportsProvider.new);
