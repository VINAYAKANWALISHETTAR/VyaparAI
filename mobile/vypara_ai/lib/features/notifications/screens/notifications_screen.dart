import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
import 'package:vypara_ai/features/notifications/data/models/notification_model.dart';
import 'package:vypara_ai/features/notifications/providers/notifications_provider.dart';

class NotificationsScreenPlaceholder extends ConsumerStatefulWidget {
  const NotificationsScreenPlaceholder({super.key});

  @override
  ConsumerState<NotificationsScreenPlaceholder> createState() =>
      _NotificationsScreenPlaceholderState();
}

class _NotificationsScreenPlaceholderState
    extends ConsumerState<NotificationsScreenPlaceholder> {
  int _selectedTabIndex = 0; // 0: All, 1: Unread

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Recent';
    final now = DateTime.now();
    final diff = now.difference(dt);
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hour:$min $ampm';

    if (diff.inDays == 0 && dt.day == now.day) {
      return 'Today, $timeStr';
    } else if (diff.inDays == 1 || (diff.inDays == 0 && dt.day != now.day)) {
      return 'Yesterday, $timeStr';
    } else {
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]}, $timeStr';
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'transaction_created':
      case 'transaction':
        return Icons.receipt_long_rounded;
      case 'reminder_created':
      case 'payment_reminder':
      case 'reminder':
        return Icons.alarm_rounded;
      case 'ocr_invoice_confirmed':
      case 'ocr':
        return Icons.document_scanner_rounded;
      case 'voice':
        return Icons.mic_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'transaction_created':
      case 'transaction':
        return const Color(0xFF10B981);
      case 'reminder_created':
      case 'payment_reminder':
      case 'reminder':
        return const Color(0xFFF59E0B);
      case 'ocr_invoice_confirmed':
      case 'ocr':
        return const Color(0xFF2563EB);
      case 'voice':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _getIconBgColor(String type) {
    switch (type.toLowerCase()) {
      case 'transaction_created':
      case 'transaction':
        return const Color(0xFFDCFCE7);
      case 'reminder_created':
      case 'payment_reminder':
      case 'reminder':
        return const Color(0xFFFEF3C7);
      case 'ocr_invoice_confirmed':
      case 'ocr':
        return const Color(0xFFDBEAFE);
      case 'voice':
        return const Color(0xFFEDE9FE);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(appTranslationsProvider);
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    final notifications = _selectedTabIndex == 1
        ? state.notifications.where((n) => !n.read).toList()
        : state.notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          tr('notifications'),
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (state.unreadCount > 0)
            TextButton.icon(
              onPressed: () => notifier.markAllAsRead(),
              icon: const Icon(Icons.done_all_rounded, size: 18, color: AppColors.primary),
              label: Text(
                tr('mark_all_read'),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildTab(
                  label: tr('all_notifications'),
                  isSelected: _selectedTabIndex == 0,
                  count: state.notifications.length,
                  onTap: () {
                    setState(() => _selectedTabIndex = 0);
                  },
                ),
                const SizedBox(width: 10),
                _buildTab(
                  label: tr('unread_notifications'),
                  isSelected: _selectedTabIndex == 1,
                  count: state.unreadCount,
                  isAlert: state.unreadCount > 0,
                  onTap: () {
                    setState(() => _selectedTabIndex = 1);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.loadNotifications(),
              color: AppColors.primary,
              child: state.isLoading && state.notifications.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : notifications.isEmpty
                      ? _buildEmptyState(tr)
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          itemCount: notifications.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            return _buildNotificationItem(notification, notifier, tr);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required bool isSelected,
    required int count,
    bool isAlert = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isAlert ? const Color(0xFFEF4444) : Colors.white24)
                      : (isAlert ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : (isAlert ? Colors.white : const Color(0xFF334155)),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
    AppNotificationModel n,
    NotificationsNotifier notifier,
    String Function(String, [Map<String, dynamic>?]) tr,
  ) {
    return Dismissible(
      key: Key(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        notifier.deleteNotification(n.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr('notification_deleted')),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: InkWell(
        onTap: () {
          if (!n.read) {
            notifier.markAsRead(n.id);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: n.read ? Colors.white : const Color(0xFFF0F6FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: n.read ? const Color(0xFFE2E8F0) : const Color(0xFFBFDBFE),
              width: n.read ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getIconBgColor(n.type),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getNotificationIcon(n.type),
                  color: _getIconColor(n.type),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: n.read ? FontWeight.w600 : FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!n.read)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 6),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.message,
                      style: TextStyle(
                        fontSize: 13,
                        color: n.read ? const Color(0xFF64748B) : const Color(0xFF334155),
                        fontWeight: n.read ? FontWeight.normal : FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDate(n.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        InkWell(
                          onTap: () => notifier.deleteNotification(n.id),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.close_rounded,
                              size: 16,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String Function(String, [Map<String, dynamic>?]) tr) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 36,
                  color: Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                tr('no_notifications'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr('no_notifications_desc'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
