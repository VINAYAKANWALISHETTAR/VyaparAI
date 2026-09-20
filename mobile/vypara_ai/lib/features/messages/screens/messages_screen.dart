import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
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
  final List<MessageIntegrationItem> _messages = [
    MessageIntegrationItem(
      id: 'm1',
      sender: '+91 98765 43210',
      preview: 'New order for 50 boxes of rice & cooking oil. Total approx ₹14,500.',
      time: '10:20 AM',
      channel: 'whatsapp',
      detectedAmount: 14500,
      customerName: 'Priya Stores',
    ),
    MessageIntegrationItem(
      id: 'm2',
      sender: 'Bank of India (SMS)',
      preview: 'Rs 12,000 credited to A/C *4829 via UPI Ref 629108392 from Sharma Enterprises.',
      time: '09:45 AM',
      channel: 'sms',
      detectedAmount: 12000,
      customerName: 'Sharma Enterprises',
    ),
    MessageIntegrationItem(
      id: 'm3',
      sender: 'Priya Stores (Email)',
      preview: 'Please share the updated tax invoice for the last delivery on 18th Sep.',
      time: '08:30 AM',
      channel: 'email',
    ),
    MessageIntegrationItem(
      id: 'm4',
      sender: '+91 94823 11094',
      preview: 'Paid ₹ 5,000 for invoice #INV-1023 via PhonePe.',
      time: 'Yesterday',
      channel: 'whatsapp',
      detectedAmount: 5000,
      customerName: 'Ramesh Kumar',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF1E293B), size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Message Integration',
          style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Auto-Fetch Channels Status (Matches Screen 10)
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
                    name: 'WhatsApp',
                    sub: 'Fetch business messages & orders',
                    color: const Color(0xFF25D366),
                    isConnected: true,
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 20),
                  _buildChannelRow(
                    icon: Icons.sms_outlined,
                    name: 'SMS',
                    sub: 'Read bank & transaction SMS',
                    color: const Color(0xFF3B82F6),
                    isConnected: true,
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 20),
                  _buildChannelRow(
                    icon: Icons.mail_outline_rounded,
                    name: 'Gmail',
                    sub: 'Fetch invoices & PO emails',
                    color: const Color(0xFFEA4335),
                    isConnected: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Latest Messages Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Latest Messages',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '${_messages.length} fetched',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Message Items List
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
                                'AI Detected: ₹${item.detectedAmount!.toStringAsFixed(0)}',
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
                                          content: Text('Recorded ₹${item.detectedAmount!.toStringAsFixed(0)} from message ✓'),
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
                                    child: const Text(
                                      'Auto-Record',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                )
                              else
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Recorded',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
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
          child: const Text(
            'Connected',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
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
