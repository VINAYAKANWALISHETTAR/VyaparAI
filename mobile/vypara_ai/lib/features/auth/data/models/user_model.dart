import 'package:vypara_ai/features/auth/data/models/login_response.dart';

class UserModel {
  final String id;
  final String name;
  final String email;

  const UserModel({required this.id, required this.name, required this.email});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  factory UserModel.fromLogin(LoginResponse login) {
    return UserModel(
      id: login.accessToken,
      name: '',
      email: '',
    );
  }
}
