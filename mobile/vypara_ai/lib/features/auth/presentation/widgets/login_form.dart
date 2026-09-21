import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/core/localization/app_translations.dart';
import 'package:vypara_ai/core/utils/validators.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({
    super.key,
    required this.onSubmit,
    required this.isLoading,
  });

  final Future<void> Function(String email, String password) onSubmit;
  final bool isLoading;

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit(
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  void _showSocialAuthNotice(String provider) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1E293B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF60A5FA), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$provider sign-in is coming soon. Please sign in with your email and password.',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(appTranslationsProvider);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simple, clean Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: tr('email'),
              labelStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              hintText: 'you@example.com',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.mail_outline_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
            ),
            validator: (v) => Validators.email(v, tr: tr),
          ),
          const SizedBox(height: 16),

          // Simple, clean Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: tr('password'),
              labelStyle: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              hintText: '••••••••',
              hintStyle: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
            ),
            validator: (v) => Validators.notEmpty(v, fieldName: tr('password'), tr: tr),
          ),
          const SizedBox(height: 14),

          // Remember Me & Forgot Password Row
          Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _rememberMe = !_rememberMe;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _rememberMe
                              ? const Color(0xFF2563EB)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _rememberMe
                                ? const Color(0xFF2563EB)
                                : const Color(0xFFCBD5E1),
                            width: 1.6,
                          ),
                        ),
                        child: _rememberMe
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tr('remember_me'),
                        style: const TextStyle(
                          color: Color(0xFF475569),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/forgot-password'),
                child: Text(
                  tr('forgot_password'),
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Sign In Button
          Container(
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0080FF), Color(0xFF7C3AED)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x332563EB),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : _submit,
                borderRadius: BorderRadius.circular(25),
                child: Center(
                  child: widget.isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.2,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              tr('signing_in'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tr('sign_in'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 22),

          // OR CONTINUE WITH Divider
          Row(
            children: [
              const Expanded(
                child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  tr('or_continue_with'),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const Expanded(
                child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Social Buttons (Google and Apple)
          Row(
            children: [
              // Google Button
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showSocialAuthNotice('Google'),
                      borderRadius: BorderRadius.circular(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGoogleIcon(),
                          const SizedBox(width: 8),
                          const Text(
                            'Google',
                            style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Apple Button
              Expanded(
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showSocialAuthNotice('Apple'),
                      borderRadius: BorderRadius.circular(14),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.apple,
                            color: Colors.black,
                            size: 21,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Apple',
                            style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sign Up Redirect
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tr('dont_have_account'),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/register'),
                child: Text(
                  tr('sign_up'),
                  style: const TextStyle(
                    color: Color(0xFF2563EB),
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return const SizedBox(
      width: 19,
      height: 19,
      child: CustomPaint(
        painter: _GoogleGIconPainter(),
      ),
    );
  }
}

class _GoogleGIconPainter extends CustomPainter {
  const _GoogleGIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Scale 24x24 standard Google G viewBox to widget size
    final scale = size.width / 24.0;
    canvas.scale(scale, scale);

    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill;
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill;
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill;

    // Blue (horizontal crossbar and right arc)
    final bluePath = Path()
      ..moveTo(23.75, 12.27)
      ..cubicTo(23.75, 11.48, 23.68, 10.73, 23.55, 10.01)
      ..lineTo(12.0, 10.01)
      ..lineTo(12.0, 14.83)
      ..lineTo(18.59, 14.83)
      ..cubicTo(18.31, 16.34, 17.46, 17.62, 16.18, 18.47)
      ..lineTo(16.18, 21.52)
      ..lineTo(20.07, 21.52)
      ..cubicTo(22.35, 19.42, 23.75, 16.29, 23.75, 12.27)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // Green (bottom arc)
    final greenPath = Path()
      ..moveTo(12.0, 24.0)
      ..cubicTo(15.24, 24.0, 17.96, 22.93, 19.94, 21.1)
      ..lineTo(16.05, 18.05)
      ..cubicTo(14.97, 18.77, 13.6, 19.2, 12.0, 19.2)
      ..cubicTo(8.88, 19.2, 6.23, 17.1, 5.28, 14.27)
      ..lineTo(1.26, 14.27)
      ..lineTo(1.26, 17.38)
      ..cubicTo(3.26, 21.36, 7.33, 24.0, 12.0, 24.0)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Yellow (left lower arc)
    final yellowPath = Path()
      ..moveTo(5.28, 14.27)
      ..cubicTo(5.03, 13.55, 4.9, 12.79, 4.9, 12.0)
      ..cubicTo(4.9, 11.21, 5.03, 10.45, 5.28, 9.73)
      ..lineTo(5.28, 6.62)
      ..lineTo(1.26, 6.62)
      ..cubicTo(0.45, 8.24, 0.0, 10.06, 0.0, 12.0)
      ..cubicTo(0.0, 13.94, 0.45, 15.76, 1.26, 17.38)
      ..lineTo(5.28, 14.27)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // Red (top arc)
    final redPath = Path()
      ..moveTo(12.0, 4.8)
      ..cubicTo(13.76, 4.8, 15.34, 5.4, 16.58, 6.59)
      ..lineTo(20.02, 3.15)
      ..cubicTo(17.95, 1.22, 15.23, 0.0, 12.0, 0.0)
      ..cubicTo(7.33, 0.0, 3.26, 2.64, 1.26, 6.62)
      ..lineTo(5.28, 9.73)
      ..cubicTo(6.23, 6.9, 8.88, 4.8, 12.0, 4.8)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
