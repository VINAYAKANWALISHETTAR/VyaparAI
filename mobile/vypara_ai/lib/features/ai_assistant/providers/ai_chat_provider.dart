import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/core/network/api_client.dart';
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
    // Initial welcome message matching Screen 12
    return AiChatState(
      messages: [
        ChatMessageModel(
          id: 'welcome_1',
          text: 'Hello! I am VyaparAI, your AI business copilot. You can ask me about your profit, pending customer receivables, cash flow forecast, or expense summaries.',
          isUser: false,
          timestamp: DateTime.now(),
          actionButtons: [
            ChatActionButton(label: 'Who owes me money?', query: 'Who owes me money?'),
            ChatActionButton(label: 'What is my profit today?', query: 'What is my profit today?'),
            ChatActionButton(label: 'How is my business doing?', query: 'How is my business doing?'),
          ],
        ),
      ],
    );
  }

  Future<void> sendMessage(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;

    final userMsg = ChatMessageModel(
      id: 'user_\${DateTime.now().millisecondsSinceEpoch}',
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
      final res = await repository.sendChatMessage(query);
      final answer = res['answer']?.toString() ?? 'I could not process your query.';
      List<ChatActionButton> buttons = [];
      if (res['action_buttons'] is List) {
        buttons = (res['action_buttons'] as List)
            .map((b) => ChatActionButton.fromJson(b as Map<String, dynamic>))
            .toList();
      }

      final aiMsg = ChatMessageModel(
        id: 'ai_\${DateTime.now().millisecondsSinceEpoch}',
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
      final errorMsg = ChatMessageModel(
        id: 'ai_err_\${DateTime.now().millisecondsSinceEpoch}',
        text: 'Sorry, I had trouble reaching the server. Please try again.',
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
