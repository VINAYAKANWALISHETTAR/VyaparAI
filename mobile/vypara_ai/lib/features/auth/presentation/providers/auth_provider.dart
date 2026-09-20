import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/constants/api_endpoints.dart';
import 'package:vypara_ai/core/errors/app_exception.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/core/storage/storage_service.dart';
import 'package:vypara_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:vypara_ai/features/auth/data/models/user_profile_model.dart';
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
  late final ApiClient _apiClient;

  @override
  AuthState build() {
    repository = AuthRepositoryImpl(
      AuthRemoteDataSource(ApiClient()),
    );
    storage = StorageService();
    _apiClient = ApiClient();
    return const AuthState();
  }

  /// Fetches the current user's profile from /users/me.
  /// Returns null if the request fails (e.g., expired token).
  Future<UserProfileModel?> _fetchProfile() async {
    try {
      final response = await _apiClient.dio.get(ApiEndpoints.me);
      return UserProfileModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, error: null);
    try {
      final user = await repository.login(email, password);
      // user.id here is the access_token returned by the login endpoint
      await storage.setAccessToken(user.id);

      // Fetch real profile name from /users/me
      final profile = await _fetchProfile();
      final resolvedUser = profile != null
          ? User(
              id: user.id,
              name: profile.name,
              email: profile.email,
            )
          : user;

      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: resolvedUser,
      );
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
      state = state.copyWith(
          status: AuthStatus.error, error: 'Registration failed');
    }
  }

  Future<void> logout() async {
    await storage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Loads the user profile independently; useful for refreshing profile data.
  Future<void> loadProfile() async {
    final profile = await _fetchProfile();
    if (profile != null) {
      final updatedUser = User(
        id: state.user?.id ?? '',
        name: profile.name,
        email: profile.email,
      );
      state = state.copyWith(user: updatedUser);
    }
  }

  Future<void> checkSession() async {
    final token = await storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      // Restore authenticated state first so the token interceptor can attach it
      state = state.copyWith(status: AuthStatus.authenticated);

      // Then try to hydrate the user profile
      final profile = await _fetchProfile();
      if (profile != null) {
        final user = User(
          id: token,
          name: profile.name,
          email: profile.email,
        );
        state = state.copyWith(user: user);
      }
    } else {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }
}

final authProvider =
    NotifierProvider<AuthProvider, AuthState>(AuthProvider.new);
