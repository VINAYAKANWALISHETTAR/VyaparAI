class ApiEndpoints {
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String logout = '/auth/logout';

  // User endpoints
  static const String me = '/users/me';
  static const String updateProfile = '/users/me';

  // AI endpoints
  static const String chat = '/ai/chat';
  static const String workflows = '/ai/workflows';

  // History endpoints
  static const String history = '/history';
}
