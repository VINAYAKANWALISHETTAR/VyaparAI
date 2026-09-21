import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/features/notifications/providers/notifications_provider.dart';

class NotificationButton extends ConsumerWidget {
  const NotificationButton({super.key, this.hasUnread});

  final bool? hasUnread;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = hasUnread ?? (ref.watch(notificationsProvider).unreadCount > 0);

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => context.push('/app/notifications'),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textPrimary,
            size: 24,
          ),
          if (unread)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
