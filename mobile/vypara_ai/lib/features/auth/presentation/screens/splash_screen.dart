import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/features/auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Check user session
    await ref.read(authProvider.notifier).checkSession();

    _navigationTimer = Timer(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.authenticated) {
        context.go('/app/home');
      } else {
        context.go('/login');
      }
    });
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background subtle waves
          Positioned.fill(
            child: CustomPaint(
              painter: _WavePainter(),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Branded Logo 'V'
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C3EF0), Color(0xFF2155F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x402155F5),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'V',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'sans-serif',
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                const Text(
                  'VyparaAI',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF101828),
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // Subtitles (combining Screen 1 & Screen 2)
                const Text(
                  'Accounts · Insights · Growth',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 28),

                // Animated 3-dot indicator (Screen 2: Logo Animation)
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        final progress = (_controller.value - (index * 0.25)) % 1.0;
                        final opacity = (progress < 0.5 ? progress * 2 : (1.0 - progress) * 2).clamp(0.2, 1.0);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha((opacity * 255).toInt()),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    );
                  },
                ),

                const Spacer(flex: 2),

                // Bottom Tagline
                const Padding(
                  padding: EdgeInsets.only(bottom: 36),
                  child: Text(
                    'Smarter Business\nBrighter Tomorrow',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x0D2155F5)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = const Color(0x086C3EF0)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.65);
    path.quadraticBezierTo(
        size.width * 0.25, size.height * 0.55, size.width * 0.5, size.height * 0.65);
    path.quadraticBezierTo(
        size.width * 0.75, size.height * 0.75, size.width, size.height * 0.65);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    final path2 = Path();
    path2.moveTo(0, size.height * 0.7);
    path2.quadraticBezierTo(
        size.width * 0.3, size.height * 0.8, size.width * 0.6, size.height * 0.7);
    path2.quadraticBezierTo(
        size.width * 0.8, size.height * 0.65, size.width, size.height * 0.75);
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
