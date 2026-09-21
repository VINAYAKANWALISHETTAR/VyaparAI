import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/core/providers/language_provider.dart';
import 'package:vypara_ai/features/ai_assistant/data/datasources/ai_remote_datasource.dart';
import 'package:vypara_ai/features/ai_assistant/data/models/chat_message_model.dart';
import 'package:vypara_ai/features/ai_assistant/data/repositories/ai_repository_impl.dart';
import 'package:vypara_ai/features/ai_assistant/repositories/ai_repository.dart';

class AiChatState {
  final bool isSending;
  final List<ChatMessageModel> messages;
  final String? error;

  const AiChatState({
    this.isSending = false,
    this.messages = const [],
    this.error,
  });

  AiChatState copyWith({
    bool? isSending,
    List<ChatMessageModel>? messages,
    String? error,
  }) {
    return AiChatState(
      isSending: isSending ?? this.isSending,
      messages: messages ?? this.messages,
      error: error,
    );
  }
}

class AiChatProvider extends Notifier<AiChatState> {
  late final AiRepository repository;

  @override
  AiChatState build() {
    repository = AiRepositoryImpl(
      AiRemoteDataSource(ApiClient()),
    );
    final lang = ref.watch(languageProvider);

    // Initial welcome message localized to the user's selected language
    final welcomeText = AppTranslations.get('ai_welcome_text', lang.code);
    final suggest1 = AppTranslations.get('ai_suggest_1', lang.code);
    final suggest2 = AppTranslations.get('ai_suggest_2', lang.code);
    final suggest3 = AppTranslations.get('ai_suggest_3', lang.code);

    return AiChatState(
      messages: [
        ChatMessageModel(
          id: 'welcome_1',
          text: welcomeText,
          isUser: false,
          timestamp: DateTime.now(),
          actionButtons: [
            ChatActionButton(label: suggest1, query: suggest1),
            ChatActionButton(label: suggest2, query: suggest2),
            ChatActionButton(label: suggest3, query: suggest3),
          ],
        ),
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    final lang = ref.read(languageProvider);

    final userMsg = ChatMessageModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: query,
      isUser: true,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      isSending: true,
      messages: [...state.messages, userMsg],
      error: null,
    );

    try {
      final res = await repository.sendChatMessage(query, language: lang.langCode);
      final answer = res['answer']?.toString() ?? 'I could not process your query.';
      List<ChatActionButton> buttons = [];
      if (res['action_buttons'] is List) {
        buttons = (res['action_buttons'] as List)
            .map((b) => ChatActionButton.fromJson(b as Map<String, dynamic>))
            .toList();
      }

      final aiMsg = ChatMessageModel(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        text: answer,
        isUser: false,
        timestamp: DateTime.now(),
        actionButtons: buttons,
        data: res['data'] as Map<String, dynamic>?,
      );

      state = state.copyWith(
        isSending: false,
        messages: [...state.messages, aiMsg],
      );
    } catch (e) {
      final errorMsgText = AppTranslations.get('ai_server_error', lang.code);
      final errorMsg = ChatMessageModel(
        id: 'ai_err_${DateTime.now().millisecondsSinceEpoch}',
        text: errorMsgText,
        isUser: false,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        isSending: false,
        messages: [...state.messages, errorMsg],
        error: e.toString(),
      );
    }
  }
}

final aiChatProvider =
    NotifierProvider<AiChatProvider, AiChatState>(AiChatProvider.new);
