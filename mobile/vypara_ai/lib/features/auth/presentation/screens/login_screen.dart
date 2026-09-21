import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/features/auth/presentation/providers/auth_provider.dart';
import 'package:vypara_ai/features/auth/presentation/widgets/login_form.dart';


class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/app/home');
      }
    });

    final screen = Scaffold(
      backgroundColor: const Color(0xFFF6F9FE),
      body: Stack(
        children: [
          // Background ambient waves, upward trend chart, and corner quotes
          Positioned.fill(
            child: CustomPaint(
              painter: _LoginArtPainter(),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),

                      // Official VyaparAI Logo
                      Center(
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x332563EB),
                                blurRadius: 22,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.asset(
                              'assets/images/VyaparAI_logo.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Brand Wordmark (Vyapar in dark navy, AI in gradient)
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              'Vyapar',
                              style: TextStyle(
                                color: Color(0xFF0F172A),
                                fontSize: 29,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.8,
                              ),
                            ),
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: const Text(
                                'AI',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 29,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Tagline
                      const Center(
                        child: Text(
                          'Your Business Partner',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Heading: Welcome back
                      const Center(
                        child: Text(
                          'Welcome back',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Center(
                        child: Text(
                          'Sign in to manage your business with clarity.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13.5,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Auth Error Message Banner
                      if (auth.status == AuthStatus.error)
                        Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: const Color(0xFFF87171).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFDC2626),
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  auth.error ?? 'Invalid email or password',
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Elevated White Form Card
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0).withValues(alpha: 0.9),
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D0F172A),
                              blurRadius: 28,
                              offset: Offset(0, 12),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 22,
                        ),
                        child: LoginForm(
                          isLoading: auth.status == AuthStatus.loading,
                          onSubmit: (email, password) async {
                            await ref
                                .read(authProvider.notifier)
                                .login(email, password);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (kIsWeb) {
      return Container(
        color: const Color(0xFFEEF2FF),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: screen,
          ),
        ),
      );
    }

    return screen;
  }
}

/// Custom painter for background waves, upward chart graphic, and handwritten quotes
class _LoginArtPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Soft ambient gradient wave at top-left
    final wavePaint1 = Paint()
      ..color = const Color(0x123B82F6)
      ..style = PaintingStyle.fill;

    final pathTop = Path();
    pathTop.moveTo(0, 0);
    pathTop.lineTo(size.width * 0.45, 0);
    pathTop.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.16,
      0,
      size.height * 0.22,
    );
    pathTop.close();
    canvas.drawPath(pathTop, wavePaint1);

    // 2. Soft ambient waves at bottom
    final wavePaint2 = Paint()
      ..color = const Color(0x186366F1)
      ..style = PaintingStyle.fill;

    final pathBottom = Path();
    pathBottom.moveTo(0, size.height);
    pathBottom.lineTo(size.width, size.height);
    pathBottom.lineTo(size.width, size.height * 0.88);
    pathBottom.quadraticBezierTo(
      size.width * 0.65,
      size.height * 0.84,
      size.width * 0.45,
      size.height * 0.90,
    );
    pathBottom.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.96,
      0,
      size.height * 0.86,
    );
    pathBottom.close();
    canvas.drawPath(pathBottom, wavePaint2);

    // 3. Upward Trend Chart Illustration on Right Side
    _drawUpwardChart(canvas, size);

    // 4. Stylized Handwritten Annotations
    _drawQuote(
      canvas,
      text: 'Business\nSimplified\nwith AI',
      position: Offset(size.width * 0.08, size.height * 0.08),
      angle: -0.12,
    );

    _drawQuote(
      canvas,
      text: 'Grow\nManage\nAutomate',
      position: Offset(size.width * 0.78, size.height * 0.07),
      angle: 0.12,
    );

    _drawQuote(
      canvas,
      text: 'Focus on\nBusiness\nWe handle\nthe rest',
      position: Offset(size.width * 0.04, size.height * 0.23),
      angle: -0.10,
    );

    _drawQuote(
      canvas,
      text: 'Empowering\nIndian Businesses',
      position: Offset(size.width * 0.06, size.height * 0.92),
      angle: -0.08,
    );

    _drawQuote(
      canvas,
      text: 'A Smarter\nTomorrow',
      position: Offset(size.width * 0.76, size.height * 0.91),
      angle: 0.08,
    );
  }

  void _drawUpwardChart(Canvas canvas, Size size) {
    // 4 vertical bars on the mid-right side
    final barPaint = Paint()
      ..color = const Color(0x2860A5FA)
      ..style = PaintingStyle.fill;

    final baseX = size.width * 0.84;
    final baseY = size.height * 0.35;
    final barWidth = 10.0;
    final gap = 6.0;

    final heights = [18.0, 34.0, 58.0, 84.0];
    for (int i = 0; i < heights.length; i++) {
      final h = heights[i];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(baseX + (i * (barWidth + gap)), baseY - h, barWidth, h),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, barPaint);
    }

    // Upward soaring arrow sweeping above the bars
    final arrowPaint = Paint()
      ..color = const Color(0x35818CF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final arrowPath = Path();
    arrowPath.moveTo(size.width * 0.79, baseY + 6);
    arrowPath.quadraticBezierTo(
      size.width * 0.86,
      baseY - 40,
      size.width * 0.96,
      baseY - 96,
    );
    canvas.drawPath(arrowPath, arrowPaint);

    // Arrowhead
    final headPath = Path();
    headPath.moveTo(size.width * 0.96, baseY - 96);
    headPath.lineTo(size.width * 0.92, baseY - 93);
    headPath.moveTo(size.width * 0.96, baseY - 96);
    headPath.lineTo(size.width * 0.95, baseY - 84);
    canvas.drawPath(headPath, arrowPaint);
  }

  void _drawQuote(
    Canvas canvas, {
    required String text,
    required Offset position,
    required double angle,
  }) {
    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(angle);

    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Color(0x8C6366F1),
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        height: 1.25,
        fontFamily: 'cursive',
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset.zero);

    // Subtle curved underline accent
    final underlinePaint = Paint()
      ..color = const Color(0x606366F1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final underlinePath = Path();
    final y = textPainter.height + 3;
    underlinePath.moveTo(0, y);
    underlinePath.quadraticBezierTo(
      textPainter.width * 0.5,
      y + 2.5,
      textPainter.width * 0.85,
      y - 1,
    );
    canvas.drawPath(underlinePath, underlinePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
