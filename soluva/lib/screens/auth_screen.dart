import 'package:flutter/material.dart';
import 'package:soluva/screens/home_screen.dart';
import 'package:soluva/services/api_services/api_service.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:soluva/widgets/header_widget.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSignIn = false; // Por defecto mostrar registro

  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
return Scaffold(
      appBar: const HeaderWidget(),
      backgroundColor: AppColors.text,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Card de registro o login
              Container(
                width: size.width < 500 ? size.width * 0.95 : 400,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      isSignIn ? 'Iniciar sesión' : '¡Bienvenido!',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSignIn
                          ? 'Ingresa tus datos para acceder.'
                          : 'Regístrate para estar más cerca de la solución.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (!isSignIn) ...[
                      _CustomTextField(
                        controller: nameController,
                        hint: 'Nombre',
                      ),
                      const SizedBox(height: 16),
                      _CustomTextField(
                        controller: lastNameController,
                        hint: 'Apellido',
                      ),
                      const SizedBox(height: 16),
                    ],
                    _CustomTextField(
                      controller: emailController,
                      hint: 'Email',
                    ),
                    const SizedBox(height: 16),
                    _CustomTextField(
                      controller: passwordController,
                      hint: 'Contraseña',
                      obscure: true,
                    ),
                    if (!isSignIn) ...[
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('• Al menos 8 caracteres', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          Text('• Una letra mayúscula', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          Text('• Un número', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          Text('• Un símbolo (por ejemplo: ! @ # \$ &)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSignIn ? _handleLogin : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          isSignIn ? 'Iniciar sesión' : 'Crear cuenta',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    if (!isSignIn) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: Image.asset(
                            'assets/images/google_icon.png',
                            height: 24,
                          ),
                          label: const Text(
                            'Registrarse con Google',
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.secondary),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isSignIn = !isSignIn;
                        });
                      },
                      child: Text(
                        isSignIn
                            ? '¿No tenés cuenta?\nRegistrate'
                            : 'Si ya tenés cuenta\nIniciar sesión',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    final name = nameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    // Validaciones aquí si quieres

    await ApiService.register(
      email: email,
      password: password,
      name: name,
      lastName: lastName,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    // Aquí puedes agregar validaciones
    await ApiService.login(
      email: email,
      password: password,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;

  const _CustomTextField({
    required this.controller,
    required this.hint,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: AppColors.secondary, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: AppColors.secondary, width: 2),
        ),
      ),
      style: const TextStyle(fontSize: 16),
    );
  }
}
