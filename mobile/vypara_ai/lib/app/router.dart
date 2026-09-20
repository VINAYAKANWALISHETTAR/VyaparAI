import 'package:go_router/go_router.dart';
import 'package:vypara_ai/features/auth/presentation/screens/splash_screen.dart';
import 'package:vypara_ai/features/auth/presentation/screens/login_screen.dart';
import 'package:vypara_ai/features/auth/presentation/screens/register_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
  ],
);
