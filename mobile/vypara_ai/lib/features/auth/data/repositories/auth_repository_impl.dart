import 'package:vypara_ai/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:vypara_ai/features/auth/data/models/login_request.dart';
import 'package:vypara_ai/features/auth/data/models/register_request.dart';
import 'package:vypara_ai/features/auth/domain/entities/user.dart';
import 'package:vypara_ai/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<User> login(String email, String password) async {
    final request = LoginRequest(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final response = await remoteDataSource.login(request);
    return User(
      id: response.accessToken,
      name: (response.user != null && response.user!.name.isNotEmpty)
          ? response.user!.name
          : email.trim().toLowerCase(),
      email: (response.user != null && response.user!.email.isNotEmpty)
          ? response.user!.email
          : email.trim().toLowerCase(),
    );
  }

  @override
  Future<User> register(String name, String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final response = await remoteDataSource.register(
      RegisterRequest(
        name: name.trim(),
        email: normalizedEmail,
        password: password,
      ),
    );
    return User(
      id: response.accessToken,
      name: (response.user != null && response.user!.name.isNotEmpty)
          ? response.user!.name
          : name.trim(),
      email: (response.user != null && response.user!.email.isNotEmpty)
          ? response.user!.email
          : normalizedEmail,
    );
  }

  @override
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return remoteDataSource.forgotPassword(email.trim().toLowerCase());
  }

  @override
  Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    return remoteDataSource.resetPassword(token.trim(), newPassword);
  }
}
