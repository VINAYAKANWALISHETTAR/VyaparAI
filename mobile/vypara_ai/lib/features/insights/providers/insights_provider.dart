import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/insights/data/datasources/insights_remote_datasource.dart';

class InsightsState {
  final bool isLoading;
  final List<InsightItem> insights;
  final List<AnomalyItem> anomalies;
  final String? error;

  const InsightsState({
    this.isLoading = false,
    this.insights = const [],
    this.anomalies = const [],
    this.error,
  });

  InsightsState copyWith({
    bool? isLoading,
    List<InsightItem>? insights,
    List<AnomalyItem>? anomalies,
    String? error,
  }) {
    return InsightsState(
      isLoading: isLoading ?? this.isLoading,
      insights: insights ?? this.insights,
      anomalies: anomalies ?? this.anomalies,
      error: error,
    );
  }
}

class InsightsNotifier extends Notifier<InsightsState> {
  late final InsightsRemoteDataSource _dataSource;

  @override
  InsightsState build() {
    _dataSource = InsightsRemoteDataSource(ApiClient());
    Future.microtask(() => fetchAll());
    return const InsightsState(isLoading: true);
  }

  Future<void> fetchAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await Future.wait([
        _dataSource.getInsights(),
        _dataSource.getAnomalies(),
      ]);
      state = state.copyWith(
        isLoading: false,
        insights: results[0] as List<InsightItem>,
        anomalies: results[1] as List<AnomalyItem>,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final insightsProvider =
    NotifierProvider<InsightsNotifier, InsightsState>(InsightsNotifier.new);
