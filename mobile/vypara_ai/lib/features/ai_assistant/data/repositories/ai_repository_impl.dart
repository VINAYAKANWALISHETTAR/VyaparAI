import 'package:vypara_ai/features/ai_assistant/data/datasources/ai_remote_datasource.dart';
import 'package:vypara_ai/features/ai_assistant/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  final AiRemoteDataSource _dataSource;

  AiRepositoryImpl(this._dataSource);

  @override
  Future<Map<String, dynamic>> sendChatMessage(String message, {String? language}) {
    return _dataSource.sendChatMessage(message, language: language);
  }

  @override
  Future<Map<String, dynamic>> sendVoiceQuery({required String text, String? language}) {
    return _dataSource.sendVoiceQuery(text: text, language: language);
  }
}
