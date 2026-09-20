import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/features/voice/providers/voice_provider.dart';

class VoiceScreenPlaceholder extends ConsumerStatefulWidget {
  const VoiceScreenPlaceholder({super.key});

  @override
  ConsumerState<VoiceScreenPlaceholder> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreenPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnim;
  final _textController = TextEditingController();

  final List<String> _suggestedPhrases = [
    'What is my profit today?',
    'Show pending payments',
    'How is my business doing?',
    'Remind me to pay supplier tomorrow',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.22).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _textController.dispose();
    // Stop listening if microphone is active
    ref.read(voiceProvider.notifier).stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceProvider);
    final isListening = voiceState.status == VoiceStatus.listening;
    final isProcessing = voiceState.status == VoiceStatus.processing;
    final hasResponse = voiceState.status == VoiceStatus.responded;
    final hasError = voiceState.status == VoiceStatus.error;
    final permissionDenied = voiceState.status == VoiceStatus.permissionDenied;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Voice Assistant',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          if (hasResponse || hasError)
            TextButton(
              onPressed: () => ref.read(voiceProvider.notifier).reset(),
              child: const Text(
                'New Query',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: hasResponse
            ? _buildResponseMode(voiceState)
            : permissionDenied
                ? _buildPermissionDenied()
                : _buildListeningMode(
                    voiceState,
                    isListening,
                    isProcessing,
                    hasError,
                  ),
      ),
    );
  }

  // ─── Listening / Idle / Error / Processing Mode ───────────────────────────

  Widget _buildListeningMode(
    VoiceState voiceState,
    bool isListening,
    bool isProcessing,
    bool hasError,
  ) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text(
          isListening
              ? 'Listening...'
              : isProcessing
                  ? 'Processing...'
                  : hasError
                      ? 'Try Again'
                      : 'Tap mic to speak',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),

        // Live transcript
        if (voiceState.transcript.isNotEmpty && isListening) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '"${voiceState.transcript}"',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        // Error banner
        if (hasError && voiceState.error != null) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorSurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              voiceState.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
              ),
            ),
          ),
        ],

        const Spacer(),

        // Pulsing microphone button
        GestureDetector(
          onTap: isProcessing
              ? null
              : isListening
                  ? () => ref.read(voiceProvider.notifier).stopListening()
                  : () => ref.read(voiceProvider.notifier).startListening(),
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              final scale = isListening ? _pulseAnim.value : 1.0;
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 190 * scale,
                    height: 190 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(
                        alpha: isListening ? 0.07 : 0.04,
                      ),
                    ),
                  ),
                  Container(
                    width: 145 * scale,
                    height: 145 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(
                        alpha: isListening ? 0.14 : 0.08,
                      ),
                    ),
                  ),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isProcessing
                          ? AppColors.textTertiary
                          : AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: isProcessing
                        ? const Padding(
                            padding: EdgeInsets.all(28),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : Icon(
                            isListening ? Icons.stop_rounded : Icons.mic,
                            size: 44,
                            color: Colors.white,
                          ),
                  ),
                ],
              );
            },
          ),
        ),

        const Spacer(),

        // Text input alternative
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: 'Or type your question...',
                    hintStyle: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                      borderSide:
                          const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.pill),
                      borderSide:
                          const BorderSide(color: AppColors.primary),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (val) {
                    if (val.trim().isNotEmpty) {
                      ref
                          .read(voiceProvider.notifier)
                          .sendTextQuery(val.trim());
                      _textController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final text = _textController.text.trim();
                  if (text.isNotEmpty) {
                    ref
                        .read(voiceProvider.notifier)
                        .sendTextQuery(text);
                    _textController.clear();
                  }
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Suggested phrases
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You can say...',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              ..._suggestedPhrases.map((phrase) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => ref
                        .read(voiceProvider.notifier)
                        .sendTextQuery(phrase),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 11,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        '"$phrase"',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ─── Response Mode ─────────────────────────────────────────────────────────

  Widget _buildResponseMode(VoiceState voiceState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Query bubble
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    voiceState.transcript.isNotEmpty
                        ? '"${voiceState.transcript}"'
                        : 'Your query',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // AI Response card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'VyaparaAI says:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        if (voiceState.isSpeaking) {
                          ref.read(voiceProvider.notifier).stopSpeaking();
                        } else {
                          ref
                              .read(voiceProvider.notifier)
                              .speakCurrentResponse();
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: voiceState.isSpeaking
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              voiceState.isSpeaking
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_mute_rounded,
                              size: 16,
                              color: voiceState.isSpeaking
                                  ? AppColors.primary
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              voiceState.isSpeaking ? 'Speaking...' : 'Listen',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: voiceState.isSpeaking
                                    ? AppColors.primary
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  voiceState.response ?? '',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          ...voiceState.actionButtons.map((pill) {
            final label = pill['label'] ?? '';
            final route = pill['route'] ?? '';
            IconData iconData = Icons.arrow_forward_ios_rounded;
            if (label.contains('Detail') || label.contains('Transaction')) {
              iconData = Icons.receipt_long_outlined;
            } else if (label.contains('Report')) {
              iconData = Icons.bar_chart_outlined;
            } else if (label.contains('Reminder')) {
              iconData = Icons.alarm_outlined;
            } else if (label.contains('Cash')) {
              iconData = Icons.account_balance_wallet_outlined;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (route.isNotEmpty) context.push(route);
                  },
                  icon: Icon(iconData, size: 20, color: AppColors.primary),
                  label: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: () => ref.read(voiceProvider.notifier).reset(),
              icon: const Icon(Icons.mic, size: 18),
              label: const Text('Ask Another Question'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Permission Denied ─────────────────────────────────────────────────────

  Widget _buildPermissionDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.mic_off,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Microphone Permission Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'To use voice input, please allow microphone access in your '
              'device settings, then try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(voiceProvider.notifier).startListening(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}
