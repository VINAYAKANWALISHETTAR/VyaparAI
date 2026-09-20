import 'package:flutter/material.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background waves
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
                
                // Logo 'V'
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C3EF0), Color(0xFF2155F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x4C2155F5), // 0.3 opacity
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'V',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
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
                
                // Subtitle
                const Text(
                  'Your AI Business Partner',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF667085),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Bottom Text
                const Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Text(
                    'Smarter Business\nBrighter Tomorrow',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
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
      ..color = const Color(0x0D2155F5) // 0.05 opacity
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = const Color(0x086C3EF0) // 0.03 opacity
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
