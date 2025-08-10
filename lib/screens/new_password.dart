import 'package:flutter/material.dart';

import '../service/auth_service.dart';
import 'home_page.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String name;
  final String phone;
  final String dob;
  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.name,
    required this.phone,
    required this.dob,
  });

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool termsAgreed = false;
  String? errorMessage;
  bool isLoading = false;
  final authService = AuthService();

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'SkillCon',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Set Your Password',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 20),

              // New Password label and input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'New Password',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Confirm Password label and input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Confirm Password',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              Row(
                children: [
                  Checkbox(
                    value: termsAgreed,
                    onChanged: (v) => setState(() => termsAgreed = v ?? false),
                  ),
                  const Expanded(
                    child: Text(
                      'I agree to the Terms of Service and Privacy Policy.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),

              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: () async {
                              if (passwordController.text !=
                                  confirmPasswordController.text) {
                                setState(
                                  () => errorMessage = 'Passwords do not match',
                                );
                                return;
                              }
                              if (!termsAgreed) {
                                setState(
                                  () => errorMessage =
                                      'Please agree to the terms',
                                );
                                return;
                              }

                              setState(() {
                                errorMessage = null;
                                isLoading = true;
                              });

                              try {
                                // Register the user with additional details
                                await authService.registerUserWithDetails(
                                  email: widget.email,
                                  password: passwordController.text,
                                  name: widget.name,
                                  phone: widget.phone,
                                  dob: widget.dob,
                                );

                                // Automatically sign in the user after registration
                                await authService.login(
                                  widget.email,
                                  passwordController.text,
                                );

                                if (!mounted) return;

                                // Navigate to HomeScreen and clear the stack
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => HomeScreen(),
                                  ),
                                  (route) => false,
                                );
                              } catch (e) {
                                setState(() {
                                  errorMessage = e.toString();
                                });
                              } finally {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Continue'),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
