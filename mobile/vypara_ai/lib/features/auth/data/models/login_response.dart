import 'package:vypara_ai/features/auth/data/models/user_model.dart';

class LoginResponse {
  final String accessToken;
  final String tokenType;
  final UserModel? user;

  const LoginResponse({
    required this.accessToken,
    required this.tokenType,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    UserModel? user;
    if (json['user'] is Map<String, dynamic>) {
      user = UserModel.fromJson(json['user'] as Map<String, dynamic>);
    } else if (json['user'] is Map) {
      user = UserModel.fromJson(Map<String, dynamic>.from(json['user'] as Map));
    }
    return LoginResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: user,
    );
  }
}
