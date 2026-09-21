abstract class AiRepository {
  Future<Map<String, dynamic>> sendChatMessage(String message, {String? language});
  Future<Map<String, dynamic>> sendVoiceQuery({required String text, String? language});
}
