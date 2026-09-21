import 'package:flutter/material.dart';

class VyaparAiRibbonLogo extends StatelessWidget {
  const VyaparAiRibbonLogo({
    super.key,
    this.size = 36.0,
    this.fontSize = 20.0,
    this.showTagline = false,
  });

  final double size;
  final double fontSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ribbon "V" Symbol with Sparkle
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RibbonLogoPainter(),
          ),
        ),
        const SizedBox(width: 8),
        // Wordmark
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Vyapar',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: const Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
                  child: Text(
                    'AI',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                // Tiny sparkle near AI
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: const Icon(
                    Icons.auto_awesome,
                    size: 10,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
            if (showTagline) ...[
              const SizedBox(height: 2),
              const Text(
                'Your Business Partner',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _RibbonLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Left Ribbon Strip (Cyan -> Blue)
    final leftPath = Path()
      ..moveTo(w * 0.15, h * 0.12)
      ..lineTo(w * 0.40, h * 0.12)
      ..lineTo(w * 0.58, h * 0.72)
      ..lineTo(w * 0.35, h * 0.88)
      ..close();

    final leftPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF00D2FF), Color(0xFF2563EB)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(leftPath, leftPaint);

    // Right Overlapping Ribbon Strip (Electric Blue -> Purple/Violet)
    final rightPath = Path()
      ..moveTo(w * 0.35, h * 0.88)
      ..lineTo(w * 0.55, h * 0.74)
      ..lineTo(w * 0.88, h * 0.12)
      ..lineTo(w * 0.65, h * 0.12)
      ..close();

    final rightPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Shadow under the overlapping ribbon
    final shadowPaint = Paint()
      ..color = const Color(0x33000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawPath(rightPath, shadowPaint);

    canvas.drawPath(rightPath, rightPaint);

    // Sparkle accent at top right
    final sparklePaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..style = PaintingStyle.fill;

    final spX = w * 0.92;
    final spY = h * 0.10;
    final spR = w * 0.08;

    final sparklePath = Path()
      ..moveTo(spX, spY - spR)
      ..quadraticBezierTo(spX, spY, spX + spR, spY)
      ..quadraticBezierTo(spX, spY, spX, spY + spR)
      ..quadraticBezierTo(spX, spY, spX - spR, spY)
      ..quadraticBezierTo(spX, spY, spX, spY - spR)
      ..close();

    canvas.drawPath(sparklePath, sparklePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
