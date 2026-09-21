import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
import 'package:vypara_ai/features/home/providers/home_provider.dart';
import 'package:vypara_ai/features/transactions/providers/transactions_provider.dart';

class MessageIntegrationItem {
  final String id;
  final String sender;
  final String preview;
  final String time;
  final String channel; // 'whatsapp', 'sms', 'email'
  final double? detectedAmount;
  final String? customerName;
  bool isRecorded;

  MessageIntegrationItem({
    required this.id,
    required this.sender,
    required this.preview,
    required this.time,
    required this.channel,
    this.detectedAmount,
    this.customerName,
    this.isRecorded = false,
  });
}

class MessagesScreen extends ConsumerStatefulWidget {
  const MessagesScreen({super.key});

  @override
  ConsumerState<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends ConsumerState<MessagesScreen> {
  final List<MessageIntegrationItem> _messages = [];


  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(appTranslationsProvider);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          tr('message_integration'),
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto-Fetch Channels Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildChannelRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    name: tr('channel_whatsapp'),
                    sub: tr('channel_whatsapp_sub'),
                    color: const Color(0xFF25D366),
                    isConnected: true,
                    tr: tr,
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 20),
                  _buildChannelRow(
                    icon: Icons.sms_outlined,
                    name: tr('channel_sms'),
                    sub: tr('channel_sms_sub'),
                    color: const Color(0xFF3B82F6),
                    isConnected: true,
                    tr: tr,
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 20),
                  _buildChannelRow(
                    icon: Icons.mail_outline_rounded,
                    name: tr('channel_gmail'),
                    sub: tr('channel_gmail_sub'),
                    color: const Color(0xFFEA4335),
                    isConnected: true,
                    tr: tr,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Latest Messages Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('latest_messages'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '${_messages.length} ${tr('fetched_count')}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_messages.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.mark_chat_unread_outlined, size: 40, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      tr('no_messages_pending'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr('no_messages_desc'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.35),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _messages.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                final item = _messages[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildChannelBadge(item.channel),
                              const SizedBox(width: 8),
                              Text(
                                item.sender,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            item.time,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.preview,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.3),
                      ),
                      if (item.detectedAmount != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${tr('ai_detected')} ₹${item.detectedAmount!.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (!item.isRecorded)
                                InkWell(
                                  onTap: () async {
                                    setState(() => item.isRecorded = true);
                                    await ref.read(transactionsProvider.notifier).addTransaction(
                                      type: 'Income',
                                      amount: item.detectedAmount!,
                                      category: 'Auto-Fetch Payment',
                                      description: item.customerName ?? item.sender,
                                    );
                                    ref.read(homeProvider.notifier).loadDashboard();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('${tr('recorded')} ₹${item.detectedAmount!.toStringAsFixed(0)} ${tr('from_message')} ✓'),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      tr('auto_record'),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                )
                              else
                                Row(
                                  children: [
                                    Icon(Icons.check_circle, size: 14, color: const Color(0xFF10B981)),
                                    const SizedBox(width: 4),
                                    Text(
                                      tr('recorded'),
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelRow({
    required IconData icon,
    required String name,
    required String sub,
    required Color color,
    required bool isConnected,
    required String Function(String) tr,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              Text(
                sub,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            isConnected ? tr('connected') : tr('disconnected'),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isConnected ? const Color(0xFF059669) : const Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelBadge(String channel) {
    IconData icon;
    Color color;
    if (channel == 'whatsapp') {
      icon = Icons.chat_bubble_rounded;
      color = const Color(0xFF25D366);
    } else if (channel == 'sms') {
      icon = Icons.sms_rounded;
      color = const Color(0xFF3B82F6);
    } else {
      icon = Icons.email_rounded;
      color = const Color(0xFFEA4335);
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 14),
    );
  }
}
