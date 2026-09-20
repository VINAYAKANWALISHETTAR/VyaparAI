import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/features/home/data/datasources/home_remote_datasource.dart';
import 'package:vypara_ai/features/home/data/models/dashboard_summary_model.dart';
import 'package:vypara_ai/features/home/data/repositories/home_repository_impl.dart';
import 'package:vypara_ai/features/home/repositories/home_repository.dart';

class HomeState {
  final bool isLoading;
  final DashboardSummaryModel? summary;
  final String? error;

  const HomeState({
    this.isLoading = false,
    this.summary,
    this.error,
  });

  HomeState copyWith({
    bool? isLoading,
    DashboardSummaryModel? summary,
    String? error,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      summary: summary ?? this.summary,
      error: error,
    );
  }
}

class HomeProvider extends Notifier<HomeState> {
  late final HomeRepository repository;

  @override
  HomeState build() {
    repository = HomeRepositoryImpl(HomeRemoteDataSource(ApiClient()));
    Future.microtask(() => loadDashboard());
    return const HomeState(isLoading: true);
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final summary = await repository.getDashboardSummary();
      state = state.copyWith(isLoading: false, summary: summary);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load dashboard');
    }
  }
}

final homeProvider = NotifierProvider<HomeProvider, HomeState>(HomeProvider.new);
