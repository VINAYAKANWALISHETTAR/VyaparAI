import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/features/auth/presentation/providers/auth_provider.dart';

class RegisterScreen extends ConsumerWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.status == AuthStatus.authenticated) context.go('/app/home');
    });
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 48),
              const Text('Create your account', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Start seeing your business clearly.'),
              const SizedBox(height: 32),
              if (auth.status == AuthStatus.error)
                Text(auth.error ?? 'Registration failed', style: const TextStyle(color: Color(0xFFD92D20))),
              ElevatedButton(
                onPressed: auth.status == AuthStatus.loading ? null : () {},
                child: const Text('Create account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
