import 'package:go_router/go_router.dart';
import 'package:vypara_ai/features/auth/presentation/screens/splash_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreenPlaceholder()),
  ],
);
