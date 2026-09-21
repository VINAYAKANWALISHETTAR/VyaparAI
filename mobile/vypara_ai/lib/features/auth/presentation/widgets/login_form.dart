import 'package:flutter/material.dart';
import 'package:vypara_ai/core/utils/validators.dart';
import 'package:vypara_ai/core/widgets/app_button.dart';
import 'package:vypara_ai/core/widgets/app_text_field.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key, required this.onSubmit, required this.isLoading});

  final Future<void> Function(String email, String password) onSubmit;
  final bool isLoading;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit(_emailController.text.trim(), _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          AppTextField(
            controller: _emailController,
            labelText: 'Email',
            hintText: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _passwordController,
            labelText: 'Password',
            hintText: 'Enter your password',
            obscureText: true,
            validator: (v) => Validators.notEmpty(v, fieldName: 'Password'),
          ),
          const SizedBox(height: 24),
          AppButton(text: 'Sign in', isLoading: widget.isLoading, onPressed: _submit),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: widget.isLoading
                ? null
                : () async {
                    _emailController.text = 'walishettar123@gmail.com';
                    _passwordController.text = 'password123';
                    await widget.onSubmit('walishettar123@gmail.com', 'password123');
                  },
            icon: const Icon(Icons.flash_on_rounded, color: Color(0xFF2563EB), size: 18),
            label: const Text(
              'Quick Login as Vinayaka',
              style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFBFDBFE)),
              backgroundColor: const Color(0xFFEFF6FF),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}
