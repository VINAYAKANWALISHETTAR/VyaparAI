abstract class AiRepository {
  Future<Map<String, dynamic>> sendChatMessage(String message);
  Future<Map<String, dynamic>> sendVoiceQuery({required String text, String? language});
}
