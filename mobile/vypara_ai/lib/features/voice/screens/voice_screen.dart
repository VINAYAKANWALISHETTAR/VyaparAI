import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
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
  bool? _isLiked;

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
    final tr = ref.watch(appTranslationsProvider);
    final voiceState = ref.watch(voiceProvider);
    final isListening = voiceState.status == VoiceStatus.listening;
    final isProcessing = voiceState.status == VoiceStatus.processing;
    final hasResponse = voiceState.status == VoiceStatus.responded;
    final hasError = voiceState.status == VoiceStatus.error;
    final permissionDenied = voiceState.status == VoiceStatus.permissionDenied;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: hasResponse
            ? _buildResponseMode(voiceState, tr)
            : permissionDenied
                ? _buildPermissionDenied(tr)
                : _buildListeningMode(
                    voiceState,
                    isListening,
                    isProcessing,
                    hasError,
                    tr,
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
    String Function(String) tr,
  ) {
    final suggestedPhrases = [
      tr('phrase_1'),
      tr('phrase_2'),
      tr('phrase_3'),
      tr('phrase_4'),
      tr('phrase_5'),
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
      child: Column(
        children: [
        // Bot Greeting Banner
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEFF6FF), Color(0xFFF5F3FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr('bot_greeting_title'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      tr('bot_greeting_subtitle'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  voiceState.isSpeaking
                      ? Icons.volume_up_rounded
                      : Icons.volume_mute_rounded,
                  color: AppColors.primary,
                ),
                tooltip: 'Listen to Bot Greeting',
                onPressed: () {
                  if (voiceState.isSpeaking) {
                    ref.read(voiceProvider.notifier).stopSpeaking();
                  } else {
                    ref.read(voiceProvider.notifier).speakGreeting();
                  }
                },
              ),
            ],
          ),
        ),

        // Wake-Word Activation Standby Card
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: voiceState.isWakeWordListening
                ? const Color(0xFFECFDF5)
                : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: voiceState.isWakeWordListening
                  ? const Color(0xFFA7F3D0)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Icon(
                voiceState.isWakeWordListening
                    ? Icons.hearing_rounded
                    : Icons.hearing_disabled_rounded,
                size: 20,
                color: voiceState.isWakeWordListening
                    ? const Color(0xFF059669)
                    : const Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voiceState.isWakeWordListening
                          ? tr('wake_word_active')
                          : tr('wake_word_standby'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: voiceState.isWakeWordListening
                            ? const Color(0xFF065F46)
                            : const Color(0xFF334155),
                      ),
                    ),
                    Text(
                      tr('wake_word_desc'),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: voiceState.isWakeWordListening,
                activeTrackColor: const Color(0xFF10B981),
                onChanged: (val) {
                  ref.read(voiceProvider.notifier).toggleWakeWordMode(val);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),
        Text(
          isListening
              ? tr('listening')
              : isProcessing
                  ? tr('analyzing_data')
                  : hasError
                      ? tr('try_again')
                      : tr('tap_mic_to_speak'),
          style: const TextStyle(
            fontSize: 20,
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
                fontWeight: FontWeight.w600,
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

        const SizedBox(height: 18),

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
                        alpha: isListening ? 0.08 : 0.04,
                      ),
                    ),
                  ),
                  Container(
                    width: 145 * scale,
                    height: 145 * scale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(
                        alpha: isListening ? 0.16 : 0.08,
                      ),
                    ),
                  ),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isProcessing
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFF2155F5), Color(0xFF6C3EF0)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      color: isProcessing ? AppColors.textTertiary : null,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2155F5).withValues(alpha: 0.35),
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
                            isListening ? Icons.stop_rounded : Icons.mic_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                  ),
                ],
              );
            },
          ),
        ),

        const SizedBox(height: 18),

        // Text input alternative
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(
                    hintText: tr('type_question'),
                    hintStyle: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 14,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      borderSide: const BorderSide(color: AppColors.primary),
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
              Text(
                tr('you_can_say'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 10),
              ...suggestedPhrases.map((phrase) {
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '"$phrase"',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
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
    ),
  );
  }

  // ─── Response Mode (AI Answer Card - Screen 4) ────────────────────────────

  // ─── Response Mode (AI Answer Card - Screen 4) ────────────────────────────

  Widget _buildResponseMode(VoiceState voiceState, String Function(String) tr) {
    final responseText = voiceState.response ?? '';
    final hasFinancialBreakdown = responseText.toLowerCase().contains('profit') ||
        responseText.toLowerCase().contains('revenue') ||
        responseText.toLowerCase().contains('expense');

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

          // AI Response Card (Screen 4 Layout)
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF4FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          tr('voice_answer'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
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
                              voiceState.isSpeaking ? tr('speaking') : tr('listen'),
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
                const SizedBox(height: 12),
                Text(
                  responseText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                    height: 1.5,
                  ),
                ),

                // Mini Visual Financial Breakdown if relevant
                if (hasFinancialBreakdown) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniMetric(tr('today_revenue'), const Color(0xFF10B981)),
                        Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                        _buildMiniMetric(tr('today_expense'), const Color(0xFFEF4444)),
                        Container(width: 1, height: 30, color: const Color(0xFFE2E8F0)),
                        _buildMiniMetric(tr('today_profit'), const Color(0xFF2155F5)),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 6),

                // Feedback section (Thumbs Up / Down)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('was_helpful'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            _isLiked == true ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined,
                            size: 18,
                            color: _isLiked == true ? AppColors.primary : const Color(0xFF94A3B8),
                          ),
                          onPressed: () => setState(() => _isLiked = true),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: Icon(
                            _isLiked == false ? Icons.thumb_down_alt : Icons.thumb_down_alt_outlined,
                            size: 18,
                            color: _isLiked == false ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                          ),
                          onPressed: () => setState(() => _isLiked = false),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          ...voiceState.actionButtons.map((pill) {
            final rawLabel = pill['label'] ?? '';
            final route = pill['route'] ?? '';
            String displayLabel = rawLabel;
            if (rawLabel.contains('Detail') || rawLabel.contains('Transaction')) {
              displayLabel = tr('view_details');
            } else if (rawLabel.contains('Report')) {
              displayLabel = tr('show_reports');
            } else if (rawLabel.contains('Reminder')) {
              displayLabel = tr('set_reminder');
            } else if (rawLabel.contains('Cash')) {
              displayLabel = tr('check_cash_flow');
            } else if (rawLabel.contains('Receivable')) {
              displayLabel = tr('view_all_receivables');
            }

            IconData iconData = Icons.arrow_forward_ios_rounded;
            if (rawLabel.contains('Detail') || rawLabel.contains('Transaction')) {
              iconData = Icons.receipt_long_outlined;
            } else if (rawLabel.contains('Report')) {
              iconData = Icons.bar_chart_outlined;
            } else if (rawLabel.contains('Reminder')) {
              iconData = Icons.alarm_outlined;
            } else if (rawLabel.contains('Cash')) {
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
                    displayLabel,
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
              onPressed: () {
                setState(() => _isLiked = null);
                ref.read(voiceProvider.notifier).reset();
              },
              icon: const Icon(Icons.mic, size: 18),
              label: Text(tr('ask_another')),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  // ─── Permission Denied ─────────────────────────────────────────────────────

  Widget _buildPermissionDenied(String Function(String) tr) {
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
            Text(
              tr('mic_permission_required'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr('mic_permission_desc'),
              textAlign: TextAlign.center,
              style: const TextStyle(
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
              label: Text(tr('try_again')),
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
              child: Text(tr('go_back')),
            ),
          ],
        ),
      ),
    );
  }
}
