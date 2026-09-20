import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/errors/app_exception.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/core/storage/storage_service.dart';
import 'package:vypara_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:vypara_ai/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:vypara_ai/features/auth/domain/entities/user.dart';
import 'package:vypara_ai/features/auth/domain/repositories/auth_repository.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState {
  final AuthStatus status;
  final String? error;
  final User? user;

  const AuthState({
    this.status = AuthStatus.initial,
    this.error,
    this.user,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? error,
    User? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      error: error,
      user: user ?? this.user,
    );
  }
}

class AuthProvider extends Notifier<AuthState> {
  late final AuthRepository repository;
  late final StorageService storage;

  @override
  AuthState build() {
    repository = AuthRepositoryImpl(
      AuthRemoteDataSource(ApiClient()),
    );
    storage = StorageService();
    return const AuthState();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await repository.login(email, password);
      await storage.setAccessToken(user.id);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on AppException catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.message);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: 'Login failed');
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await repository.register(name, email, password);
      await storage.setAccessToken(user.id);
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } on AppException catch (e) {
      state = state.copyWith(status: AuthStatus.error, error: e.message);
    } catch (_) {
      state = state.copyWith(status: AuthStatus.error, error: 'Registration failed');
    }
  }

  Future<void> logout() async {
    await storage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> checkSession() async {
    final token = await storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      state = state.copyWith(status: AuthStatus.authenticated);
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

final authProvider = NotifierProvider<AuthProvider, AuthState>(AuthProvider.new);
