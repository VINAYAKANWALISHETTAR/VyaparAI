import 'package:flutter/material.dart';

class VyaparAiRibbonLogo extends StatelessWidget {
  const VyaparAiRibbonLogo({
    super.key,
    this.size = 38.0,
    this.fontSize = 20.0,
    this.showWordmark = true,
    this.showTagline = false,
  });

  final double size;
  final double fontSize;
  final bool showWordmark;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final logoWidget = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/images/VyaparAI_logo.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
              ),
              borderRadius: BorderRadius.circular(size * 0.22),
            ),
            child: const Center(
              child: Text(
                'V',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          );
        },
      ),
    );

    if (!showWordmark) {
      return logoWidget;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        logoWidget,
        const SizedBox(width: 10),
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
                    fontWeight: FontWeight.w900,
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
