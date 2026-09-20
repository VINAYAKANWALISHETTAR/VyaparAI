import 'package:flutter/material.dart';
import 'package:vypara_ai/core/utils/validators.dart';
import 'package:vypara_ai/core/widgets/app_button.dart';
import 'package:vypara_ai/core/widgets/app_text_field.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key, required this.onSubmit, required this.isLoading});

  final Future<void> Function(String name, String email, String password) onSubmit;
  final bool isLoading;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSubmit(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          AppTextField(
            controller: _nameController,
            labelText: 'Full name',
            hintText: 'Enter your name',
            validator: (v) => Validators.notEmpty(v, fieldName: 'Full name'),
          ),
          const SizedBox(height: 12),
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
            hintText: 'At least 8 chars (1 uppercase, 1 number)',
            obscureText: true,
            validator: Validators.password,
          ),
          const SizedBox(height: 24),
          AppButton(text: 'Create account', isLoading: widget.isLoading, onPressed: _submit),
        ],
      ),
    );
  }
}
