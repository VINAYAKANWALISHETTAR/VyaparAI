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
    final request = LoginRequest(email: email, password: password);
    final response = await remoteDataSource.login(request);
    return User(
      id: response.accessToken,
      name: email,
      email: email,
    );
  }

  @override
  Future<User> register(String name, String email, String password) async {
    await remoteDataSource.register(
      RegisterRequest(name: name, email: email, password: password),
    );
    return login(email, password);
  }
}
