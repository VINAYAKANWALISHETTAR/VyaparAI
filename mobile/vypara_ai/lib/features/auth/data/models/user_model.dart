import 'package:vypara_ai/features/auth/data/models/login_response.dart';

class UserModel {
  final String id;
  final String name;
  final String email;

  const UserModel({required this.id, required this.name, required this.email});

  factory UserModel.fromLogin(LoginResponse login) {
    return UserModel(id: login.accessToken, name: '', email: '');
  }
}
