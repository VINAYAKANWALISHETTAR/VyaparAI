import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/features/auth/presentation/providers/auth_provider.dart';

class SettingsScreenPlaceholder extends ConsumerWidget {
  const SettingsScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ),
    );
  }
}
