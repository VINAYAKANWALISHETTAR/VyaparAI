import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/core/widgets/app_loader.dart';
import 'package:vypara_ai/features/auth/presentation/providers/auth_provider.dart';

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() => ref.read(authProvider.notifier).checkSession());
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(authProvider).status;
    if (status == AuthStatus.initial || status == AuthStatus.loading) {
      return const Scaffold(body: AppLoader(message: 'Checking your session...'));
    }
    if (status != AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return const SizedBox.shrink();
    }
    return widget.child;
  }
}
