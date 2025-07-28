// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import 'package:soluva/theme/app_colors.dart';
import '../api_services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSignIn = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(32),
                color: AppColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'SoluVa',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => isSignIn = true),
                          child: Column(
                            children: [
                              Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: isSignIn ? Colors.black : Colors.grey,
                                ),
                              ),
                              if (isSignIn)
                                Container(
                                  height: 3,
                                  width: 60,
                                  color: AppColors.primary,
                                  margin: const EdgeInsets.only(top: 4),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () => setState(() => isSignIn = false),
                          child: Column(
                            children: [
                              Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: !isSignIn ? Colors.black : Colors.grey,
                                ),
                              ),
                              if (!isSignIn)
                                Container(
                                  height: 3,
                                  width: 60,
                                  color: Colors.deepPurple,
                                  margin: const EdgeInsets.only(top: 4),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Let's get started by filling out the form below.",
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                    ),
                    if (!isSignIn) const SizedBox(height: 16),
                    if (!isSignIn)
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                        ),
                      ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        final email = emailController.text.trim();
                        final password = passwordController.text;

                        if (isSignIn) {
                          await AuthService.login(
                            email: email,
                            password: password,
                          );
                          // Podés agregar navegación o feedback aquí
                        } else {
                          final confirmPassword =
                              confirmPasswordController.text;
                          if (password != confirmPassword) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Passwords do not match'),
                              ),
                            );
                            return;
                          }

                          await AuthService.register(
                            email: email,
                            password: password,
                          );
                          // Podés agregar navegación o feedback aquí
                        }

                        //TODO
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(isSignIn ? 'Sign In' : 'Create Account'),
                    ),
                    if (isSignIn)
                      TextButton(
                        onPressed: () {},
                        child: const Text('Forgot Password'),
                      ),
                    const SizedBox(height: 16),
                    const Center(child: Text('Or sign up with')),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.g_mobiledata_rounded),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
