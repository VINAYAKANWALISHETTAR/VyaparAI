import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/app_shell.dart';
import 'package:vypara_ai/features/ai_assistant/screens/ai_chat_screen.dart';
import 'package:vypara_ai/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:vypara_ai/features/auth/presentation/screens/login_screen.dart';
import 'package:vypara_ai/features/auth/presentation/screens/register_screen.dart';
import 'package:vypara_ai/features/auth/presentation/screens/splash_screen.dart';
import 'package:vypara_ai/features/cash_flow/screens/cash_flow_screen.dart';
import 'package:vypara_ai/features/customers/screens/customers_screen.dart';
import 'package:vypara_ai/features/home/screens/home_screen.dart';
import 'package:vypara_ai/features/invoices/screens/invoices_screen.dart';
import 'package:vypara_ai/features/notifications/screens/notifications_screen.dart';
import 'package:vypara_ai/features/records/screens/records_screen.dart';
import 'package:vypara_ai/features/reminders/screens/reminders_screen.dart';
import 'package:vypara_ai/features/reports/screens/reports_screen.dart';
import 'package:vypara_ai/features/settings/screens/settings_screen.dart';
import 'package:vypara_ai/features/suppliers/screens/suppliers_screen.dart';
import 'package:vypara_ai/features/transactions/screens/transactions_screen.dart';
import 'package:vypara_ai/features/customers/screens/person_detail_screen.dart';
import 'package:vypara_ai/features/insights/screens/insights_screen.dart';
import 'package:vypara_ai/features/messages/screens/messages_screen.dart';
import 'package:vypara_ai/features/uploads/screens/scan_screen.dart';
import 'package:vypara_ai/features/uploads/screens/upload_screen.dart';
import 'package:vypara_ai/features/voice/screens/voice_screen.dart';

final router = GoRouter(
  initialLocation: '/splash',
  routes: <RouteBase>[
    // Root redirect
    GoRoute(
      path: '/',
      redirect: (context, state) => '/splash',
    ),

    // Authentication and Onboarding
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),

    // Main App Shell with Bottom Navigation
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/app/home',
          builder: (context, state) => const HomeScreenPlaceholder(),
        ),
        GoRoute(
          path: '/app/reports',
          builder: (context, state) => const ReportsScreenPlaceholder(),
        ),
        GoRoute(
          path: '/app/ai',
          builder: (context, state) => const AIScreenPlaceholder(),
        ),
        GoRoute(
          path: '/app/records',
          builder: (context, state) => const RecordsScreenPlaceholder(),
        ),
        GoRoute(
          path: '/app/settings',
          builder: (context, state) => const SettingsScreenPlaceholder(),
        ),
      ],
    ),

    // Standalone Feature Routes
    GoRoute(
      path: '/app/transactions',
      builder: (context, state) => const TransactionsScreenPlaceholder(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) => const TransactionsScreenPlaceholder(),
        ),
      ],
    ),
    GoRoute(
      path: '/app/invoices',
      builder: (context, state) => const InvoicesScreenPlaceholder(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (context, state) => const InvoicesScreenPlaceholder(),
        ),
      ],
    ),
    GoRoute(
      path: '/app/customers',
      builder: (context, state) => const CustomersScreenPlaceholder(),
    ),
    GoRoute(
      path: '/app/suppliers',
      builder: (context, state) => const SuppliersScreenPlaceholder(),
    ),
    GoRoute(
      path: '/app/cash-flow',
      builder: (context, state) => const CashFlowScreenPlaceholder(),
    ),
    GoRoute(
      path: '/app/reminders',
      builder: (context, state) => const RemindersScreenPlaceholder(),
    ),
    GoRoute(
      path: '/app/notifications',
      builder: (context, state) => const NotificationsScreenPlaceholder(),
    ),
    GoRoute(
      path: '/app/upload',
      builder: (context, state) => const UploadScreenPlaceholder(),
    ),
    GoRoute(
      path: '/app/voice',
      builder: (context, state) => const VoiceScreenPlaceholder(),
    ),
    GoRoute(
      path: '/app/scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/app/messages',
      builder: (context, state) => const MessagesScreen(),
    ),
    GoRoute(
      path: '/app/insights',
      builder: (context, state) => const InsightsScreen(),
    ),
    GoRoute(
      path: '/app/parties/:name',
      builder: (context, state) {
        final name = state.pathParameters['name'] ?? 'Party';
        return PersonDetailScreen(name: name);
      },
    ),
  ],
);
