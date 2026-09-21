import 'package:vypara_ai/core/constants/api_endpoints.dart';
import 'package:vypara_ai/core/network/api_client.dart';

class AiRemoteDataSource {
  final ApiClient apiClient;

  AiRemoteDataSource(this.apiClient);

  Future<Map<String, dynamic>> sendChatMessage(String message, {String? language}) async {
    final res = await apiClient.dio.post(
      ApiEndpoints.copilotChat,
      data: {
        'message': message,
        'language': ?language,
      },
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> sendVoiceQuery({
    required String text,
    String? language,
  }) async {
    final res = await apiClient.dio.post(
      ApiEndpoints.voiceQuery,
      data: {
        'text': text,
        'language': ?language,
      },
    );
    return res.data as Map<String, dynamic>;
  }
}
