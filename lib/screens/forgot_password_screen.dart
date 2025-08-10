import 'package:flutter/material.dart';

import '../service/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final emailController = TextEditingController();
  final authService = AuthService();

  ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Forgot Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(
              controller: emailController,
              hintText: "Enter your email",
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: "Reset Password",
              onPressed: () async {
                await authService.resetPassword(emailController.text);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
