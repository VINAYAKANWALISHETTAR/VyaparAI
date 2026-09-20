import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/core/widgets/app_bottom_nav.dart';
import 'package:vypara_ai/core/widgets/app_header.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return Scaffold(
      appBar: const AppHeader(),
      body: SafeArea(top: false, child: child),
      bottomNavigationBar: AppBottomNav(location: location),
    );
  }
}
