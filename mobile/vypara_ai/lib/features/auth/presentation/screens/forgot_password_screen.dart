import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vypara_ai/app/theme/app_colors.dart';
import 'package:vypara_ai/app/theme/app_radius.dart';
import 'package:vypara_ai/core/utils/validators.dart';
import 'package:vypara_ai/core/widgets/app_button.dart';
import 'package:vypara_ai/core/widgets/app_text_field.dart';
import 'package:vypara_ai/features/auth/presentation/providers/auth_provider.dart';
import 'package:vypara_ai/features/auth/presentation/widgets/auth_header.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _isResetMode = false;
  bool _isCompleted = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim().toLowerCase();
      final res = await ref.read(authProvider.notifier).forgotPassword(email);

      if (!mounted) return;

      final token = res['reset_token'] as String?;
      if (token != null && token.isNotEmpty) {
        _tokenController.text = token;
      }

      setState(() {
        _isLoading = false;
        _isResetMode = true;
        _successMessage = res['message'] as String? ??
            'Password reset instructions sent. Enter your new password.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to generate reset request. Please check your network.';
      });
    }
  }

  Future<void> _submitReset() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await ref.read(authProvider.notifier).resetPassword(
            _tokenController.text.trim(),
            _newPasswordController.text,
          );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isCompleted = true;
        _successMessage = res['message'] as String? ??
            'Password has been successfully reset.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Password reset failed. Invalid or expired token.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = Scaffold(
      backgroundColor: const Color(0xFFF6F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF0F172A),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    title: 'Reset password',
                    subtitle:
                        'Enter your registered email address to recover your account.',
                  ),
                  const SizedBox(height: 28),

                  // Error message banner
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
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
                              _errorMessage!,
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

                  // Success message banner
                  if (_successMessage != null && !_isCompleted)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: const Color(0xFF86EFAC).withValues(alpha: 0.6),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Color(0xFF16A34A),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _successMessage!,
                              style: const TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Completed State
                  if (_isCompleted)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A0F172A),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF16A34A),
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Password Reset Successful',
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You can now sign in with your new password.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            text: 'Sign in with new password',
                            onPressed: () => context.go('/login'),
                          ),
                        ],
                      ),
                    )
                  // Reset Password Mode (Stage 2)
                  else if (_isResetMode)
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A0F172A),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _resetFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              controller: _tokenController,
                              labelText: 'Reset Token',
                              hintText: 'Security token',
                              validator: (v) => Validators.notEmpty(v,
                                  fieldName: 'Reset Token'),
                            ),
                            const SizedBox(height: 14),
                            AppTextField(
                              controller: _newPasswordController,
                              labelText: 'New Password',
                              hintText: 'Enter at least 6 characters',
                              obscureText: true,
                              validator: (v) => Validators.notEmpty(v,
                                  fieldName: 'New Password'),
                            ),
                            const SizedBox(height: 24),
                            AppButton(
                              text: 'Confirm New Password',
                              isLoading: _isLoading,
                              onPressed: _submitReset,
                            ),
                          ],
                        ),
                      ),
                    )
                  // Email Request Mode (Stage 1)
                  else
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0A0F172A),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _emailFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppTextField(
                              controller: _emailController,
                              labelText: 'Registered Email',
                              hintText: 'walishettar123@gmail.com',
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 24),
                            AppButton(
                              text: 'Send Reset Instructions',
                              isLoading: _isLoading,
                              onPressed: _submitEmail,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'Back to sign in',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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
