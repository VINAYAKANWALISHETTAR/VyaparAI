import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => context.push('/app/notifications'),
      icon: const Icon(Icons.notifications_none_rounded),
    );
  }
}
