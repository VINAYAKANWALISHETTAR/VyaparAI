import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/features/auth/presentation/providers/auth_provider.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

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
              const Text('Welcome back', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Sign in to manage your business with clarity.'),
              const SizedBox(height: 32),
              if (auth.status == AuthStatus.error)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: const Color(0xFFFEE9E7), borderRadius: BorderRadius.circular(10)),
                  child: Text(auth.error ?? 'Sign in failed'),
                ),
              ElevatedButton(
                onPressed: auth.status == AuthStatus.loading ? null : () {},
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
