import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vypara_ai/core/constants/api_endpoints.dart';
import 'package:vypara_ai/core/network/api_client.dart';
import 'package:vypara_ai/core/providers/language_provider.dart';
import 'package:vypara_ai/core/services/notification_service.dart';
import 'package:vypara_ai/features/home/providers/home_provider.dart';
import 'package:vypara_ai/features/transactions/providers/transactions_provider.dart';

enum VoiceStatus {
  idle,
  requestingPermission,
  permissionDenied,
  listening,
  processing,
  responded,
  error,
}

class VoiceState {
  final VoiceStatus status;
  final String transcript;
  final String? response;
  final List<Map<String, String>> actionButtons;
  final String? error;
  final bool isSpeaking;
  final bool isWakeWordListening;

  const VoiceState({
    this.status = VoiceStatus.idle,
    this.transcript = '',
    this.response,
    this.actionButtons = const [],
    this.error,
    this.isSpeaking = false,
    this.isWakeWordListening = false,
  });

  VoiceState copyWith({
    VoiceStatus? status,
    String? transcript,
    String? response,
    List<Map<String, String>>? actionButtons,
    String? error,
    bool? isSpeaking,
    bool? isWakeWordListening,
  }) {
    return VoiceState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      response: response ?? this.response,
      actionButtons: actionButtons ?? this.actionButtons,
      error: error,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isWakeWordListening: isWakeWordListening ?? this.isWakeWordListening,
    );
  }
}

class VoiceProvider extends Notifier<VoiceState> {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _speechAvailable = false;
  bool _ttsInitialized = false;

  static const List<String> _wakeWords = [
    'hey vyapar',
    'vyapar',
    'vyaparai',
    'vyapar ai',
    'vyapar bot',
    'ವ್ಯಾಪಾರ್',
    'ಹೇ ವ್ಯಾಪಾರ್',
    'ವ್ಯಾಪಾರ',
    'ವ್ಯಾಪಾರ್ ಬಾಟ್',
    'व्यापार',
    'हे व्यापार',
    'व्यापार बॉट',
  ];

  @override
  VoiceState build() {
    _initTts();
    return const VoiceState();
  }

  void _initTts() {
    if (_ttsInitialized) return;
    _ttsInitialized = true;
    _tts.setStartHandler(() {
      state = state.copyWith(isSpeaking: true);
    });
    _tts.setCompletionHandler(() {
      state = state.copyWith(isSpeaking: false);
      if (state.isWakeWordListening && state.status != VoiceStatus.listening) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (state.isWakeWordListening && state.status != VoiceStatus.processing) {
            startListening();
          }
        });
      }
    });
    _tts.setErrorHandler((_) {
      state = state.copyWith(isSpeaking: false);
    });
    final lang = ref.read(languageProvider);
    _tts.setLanguage(lang.speechLocale.replaceAll('_', '-')).catchError((_) {});
    _tts.setSpeechRate(0.5).catchError((_) {});
    _tts.setPitch(1.0).catchError((_) {});
  }

  Future<void> speakGreeting() async {
    final lang = ref.read(languageProvider);
    String greeting;
    if (lang.code.toUpperCase() == 'KN') {
      greeting = "ನಮಸ್ಕಾರ! ಇಂದು ನಿಮಗೆ ಹೇಗೆ ಸಹಾಯ ಮಾಡಲಿ?";
    } else if (lang.code.toUpperCase() == 'HI') {
      greeting = "नमस्ते! आज मैं आपकी कैसे मदद कर सकता हूँ?";
    } else {
      greeting = "Hello! How can I help your business today?";
    }
    _initTts();
    await _tts.stop();
    await _tts.setLanguage(lang.speechLocale.replaceAll('_', '-')).catchError((_) {});
    await _tts.speak(greeting);

    // Show wake up alert
    NotificationService().showVoiceWakeupAlert(
      query: 'Voice Wakeup',
      responseText: greeting,
      language: lang.code,
    );
  }

  Future<void> speakCurrentResponse() async {
    final text = state.response;
    if (text == null || text.isEmpty) return;
    final lang = ref.read(languageProvider);
    _initTts();
    await _tts.stop();
    await _tts.setLanguage(lang.speechLocale.replaceAll('_', '-')).catchError((_) {});
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() async {
    await _tts.stop();
    state = state.copyWith(isSpeaking: false);
  }

  Future<void> toggleWakeWordMode(bool enable) async {
    state = state.copyWith(isWakeWordListening: enable, error: null);
    if (enable) {
      await startListening();
    } else {
      await stopListening();
    }
  }

  Future<void> startListening() async {
    await stopSpeaking();
    state = state.copyWith(status: VoiceStatus.requestingPermission, error: null);

    if (!_speechAvailable) {
      _speechAvailable = await _speech.initialize(
        onStatus: _onStatus,
        onError: (e) {
          final errorMsg = e.errorMsg.toLowerCase();
          final isTransient = errorMsg.contains('timeout') ||
              errorMsg.contains('no_match') ||
              errorMsg.contains('busy') ||
              errorMsg.contains('client');

          if (state.isWakeWordListening && isTransient) {
            // Non-fatal silence/timeout in wake-word standby mode: auto-restart loop
            Future.delayed(const Duration(milliseconds: 350), () {
              if (state.isWakeWordListening && state.status != VoiceStatus.processing) {
                startListening();
              }
            });
            return;
          }

          state = state.copyWith(
            status: VoiceStatus.error,
            error: 'Microphone: ${e.errorMsg}',
          );
        },
      );
    }

    if (!_speechAvailable) {
      state = state.copyWith(
        status: VoiceStatus.permissionDenied,
        error: 'Microphone permission denied. Please enable it in Settings.',
      );
      return;
    }

    final lang = ref.read(languageProvider);
    state = state.copyWith(status: VoiceStatus.listening, transcript: '');
    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords;
        state = state.copyWith(transcript: words);
        
        // Check for wake word trigger
        final lower = words.toLowerCase().trim();
        for (final wake in _wakeWords) {
          if (lower.startsWith(wake) || lower.contains(wake)) {
            final queryPart = lower.replaceAll(wake, '').trim();
            if (queryPart.isEmpty && result.finalResult) {
              speakGreeting();
              return;
            } else if (queryPart.isNotEmpty && result.finalResult) {
              _processQuery(queryPart);
              return;
            }
          }
        }

        if (result.finalResult) {
          _processQuery(words);
        }
      },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 25),
        pauseFor: const Duration(seconds: 4),
        localeId: lang.speechLocale,
      ),
    );
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      final transcript = state.transcript;
      if (transcript.isNotEmpty && state.status == VoiceStatus.listening) {
        _processQuery(transcript);
      } else if (state.isWakeWordListening) {
        // Continuous wake-word loop: seamlessly restart listening in standby
        Future.delayed(const Duration(milliseconds: 350), () {
          if (state.isWakeWordListening && state.status != VoiceStatus.processing) {
            startListening();
          }
        });
      } else if (state.status == VoiceStatus.listening) {
        state = state.copyWith(status: VoiceStatus.idle);
      }
    }
  }

  Future<void> stopListening() async {
    await _speech.stop();
  }

  Future<void> sendTextQuery(String text) async {
    if (text.trim().isEmpty) return;
    await stopSpeaking();
    state = state.copyWith(status: VoiceStatus.processing, transcript: text);
    await _processQuery(text);
  }

  Future<void> _processQuery(String text) async {
    if (text.trim().isEmpty) return;
    await _speech.stop();
    state = state.copyWith(status: VoiceStatus.processing, transcript: text);

    try {
      final client = ApiClient();
      final lang = ref.read(languageProvider);
      final response = await client.dio.post(
        ApiEndpoints.voiceQuery,
        data: {
          'text': text,
          'language': lang.code,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final answer = data['answer']?.toString() ??
          data['response']?.toString() ??
          'No response from VyparaAI.';
      final intent = data['intent']?.toString();

      final List<Map<String, String>> actions = [];
      if (data['action_buttons'] is List) {
        for (final b in (data['action_buttons'] as List)) {
          if (b is Map) {
            actions.add({
              'label': b['label']?.toString() ?? '',
              'route': b['route']?.toString() ?? '',
            });
          }
        }
      }
      if (actions.isEmpty) {
        actions.addAll([
          {'label': 'View Details', 'route': '/app/transactions'},
          {'label': 'Show Reports', 'route': '/app/reports'},
          {'label': 'Set Reminder', 'route': '/app/reminders'},
          {'label': 'Check Cash Flow', 'route': '/app/cash-flow'},
        ]);
      }

      state = state.copyWith(
        status: VoiceStatus.responded,
        response: answer,
        actionButtons: actions,
        error: null,
      );

      // If a transaction was created by voice, refresh transactions and home providers
      if (intent == 'record_transaction') {
        ref.read(transactionsProvider.notifier).loadTransactions();
        ref.read(homeProvider.notifier).loadDashboard();
      }

      // Auto speak aloud the assistant response in the selected language
      speakCurrentResponse();

      // Send real-time high-priority heads-up notification (wakes up lock screen / closed phone)
      NotificationService().showVoiceWakeupAlert(
        query: text,
        responseText: answer,
        language: lang.code,
      );
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? e.response!.data['detail']?.toString()
          : null;
      state = state.copyWith(
        status: VoiceStatus.error,
        error: detail ?? 'Could not connect to VyparaAI. Please try again.',
      );
    } catch (_) {
      state = state.copyWith(
        status: VoiceStatus.error,
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  void reset() {
    _speech.stop();
    stopSpeaking();
    state = const VoiceState();
  }
}

final voiceProvider =
    NotifierProvider<VoiceProvider, VoiceState>(VoiceProvider.new);

