import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text('Reset password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('Password reset will be available when the backend reset-password endpoint is added.'),
        ]),
      ),
    );
  }
}
