import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<String?> getAccessToken() async => _storage.read(key: _accessTokenKey);
  Future<void> setAccessToken(String token) async => _storage.write(key: _accessTokenKey, value: token);
  Future<String?> getRefreshToken() async => _storage.read(key: _refreshTokenKey);
  Future<void> setRefreshToken(String token) async => _storage.write(key: _refreshTokenKey, value: token);
  Future<void> deleteAccessToken() async => _storage.delete(key: _accessTokenKey);
  Future<void> deleteRefreshToken() async => _storage.delete(key: _refreshTokenKey);
  Future<void> clearAll() async => _storage.deleteAll();
}
