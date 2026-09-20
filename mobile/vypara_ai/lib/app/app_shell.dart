import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/core/widgets/app_bottom_nav.dart';
import 'package:vypara_ai/core/widgets/app_header.dart';
import 'package:vypara_ai/features/auth/presentation/widgets/auth_gate.dart';

import 'package:vypara_ai/core/widgets/app_drawer.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return AuthGate(
      child: Scaffold(
        appBar: const AppHeader(),
        drawer: const AppDrawer(),
        body: SafeArea(top: false, child: child),
        bottomNavigationBar: AppBottomNav(location: location),
      ),
    );
  }
}
