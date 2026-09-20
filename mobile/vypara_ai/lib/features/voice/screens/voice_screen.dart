import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/features/ai_assistant/providers/ai_chat_provider.dart';

class VoiceScreenPlaceholder extends ConsumerStatefulWidget {
  const VoiceScreenPlaceholder({super.key});

  @override
  ConsumerState<VoiceScreenPlaceholder> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreenPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  String _selectedLanguage = 'EN';
  bool _isListening = true;
  String _recognizedText = '';
  String? _voiceResponse;
  List<Map<String, String>> _actionPills = [];

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
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handlePhraseTap(String phrase) async {
    setState(() {
      _isListening = false;
      _recognizedText = phrase;
      _voiceResponse = null;
    });

    final res = await ref.read(aiChatProvider.notifier).repository.sendChatMessage(phrase);
    final answer = res['answer']?.toString() ?? 'Here is the summary for your business.';

    final actions = <Map<String, String>>[];
    if (res['action_buttons'] is List) {
      for (final b in (res['action_buttons'] as List)) {
        actions.add({
          'label': b['label']?.toString() ?? '',
          'route': b['route']?.toString() ?? '',
        });
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

    if (mounted) {
      setState(() {
        _voiceResponse = answer;
        _actionPills = actions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
        actions: [
          // Language selector dropdown pill matching Screen 4
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF1E293B)),
                    isDense: true,
                    items: const [
                      DropdownMenuItem(value: 'EN', child: Text('EN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                      DropdownMenuItem(value: 'HI', child: Text('HI', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                      DropdownMenuItem(value: 'KN', child: Text('KN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedLanguage = val);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isListening
            ? _buildListeningMode()
            : _buildResponseMode(),
      ),
    );
  }

  // Screen 4: Listening Mode with pulsing waves
  Widget _buildListeningMode() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Text(
          'Listening...',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const Spacer(),

        // Pulsing glowing microphone circle
        Center(
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 200 * _pulseAnim.value,
                    height: 200 * _pulseAnim.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.08),
                    ),
                  ),
                  Container(
                    width: 150 * _pulseAnim.value,
                    height: 150 * _pulseAnim.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withValues(alpha: 0.15),
                    ),
                  ),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x662155F5),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mic, size: 48, color: Colors.white),
                  ),
                ],
              );
            },
          ),
        ),
        const Spacer(),

        // "You can say..." suggestions matching Screen 4
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Text(
                'You can say...',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),
              ..._suggestedPhrases.map((phrase) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () => _handlePhraseTap(phrase),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Center(
                        child: Text(
                          '"$phrase"',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
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

  // Screen 5: AI Response Mode with card and action buttons
  Widget _buildResponseMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Speech Bubble with AI avatar
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _recognizedText.isNotEmpty
                      ? 'Query: "$_recognizedText"'
                      : "Here's your summary",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Response summary card matching Screen 5
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _voiceResponse ?? 'Loading response...',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.volume_up_outlined, color: Color(0xFF94A3B8), size: 22),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action navigation buttons matching Screen 5
          ..._actionPills.map((pill) {
            IconData iconData;
            final label = pill['label'] ?? '';
            if (label.contains('Details')) {
              iconData = Icons.receipt_long_outlined;
            } else if (label.contains('Report')) {
              iconData = Icons.bar_chart_outlined;
            } else if (label.contains('Reminder')) {
              iconData = Icons.alarm_outlined;
            } else {
              iconData = Icons.account_balance_wallet_outlined;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final route = pill['route'];
                    if (route != null && route.isNotEmpty) {
                      context.push(route);
                    }
                  },
                  icon: Icon(iconData, size: 20, color: AppColors.primary),
                  label: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    elevation: 0,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 20),
          // Ask another question button
          Center(
            child: TextButton.icon(
              onPressed: () => setState(() => _isListening = true),
              icon: const Icon(Icons.mic, size: 18),
              label: const Text('Ask Another Question'),
            ),
          ),
        ],
      ),
    );
  }
}
