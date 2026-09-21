import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
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

    final scaffold = Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      appBar: const AppHeader(),
      drawer: const AppDrawer(),
      body: SafeArea(top: false, child: child),
      bottomNavigationBar: AppBottomNav(location: location),
    );

    return AuthGate(
      child: kIsWeb
          ? Container(
              color: const Color(0xFFEEF2FF),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: scaffold,
                ),
              ),
            )
          : scaffold,
    );
  }
}
