import 'package:flutter/material.dart';
import 'package:vypara_ai/app/router.dart';
import 'package:vypara_ai/app/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VyparaAI',
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
