import 'package:flutter/material.dart';
import 'package:soluva/screens/home_screen.dart';
import 'package:soluva/services/api_services/api_service.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:soluva/widgets/header_widget.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthScreen extends StatefulWidget {
  final Widget? redirectTo;

  const AuthScreen({super.key, this.redirectTo});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isSignIn = false; // Por defecto mostrar registro
  bool _showBackgroundImage = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Cargar la imagen de fondo después de renderizar el contenido
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showBackgroundImage = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final fondoPath =
        dotenv.env['default_cover_webp'] ?? 'assets/images/fondo-inicio.webp';

    return Scaffold(
      appBar: const HeaderWidget(),
      backgroundColor: AppColors.text,
      body: Stack(
        children: [
          // Fondo liso primero
          Container(color: AppColors.text),
          // Imagen de fondo después
          if (_showBackgroundImage)
            Positioned.fill(child: Image.asset(fondoPath, fit: BoxFit.cover)),
          Center(
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
                            onSubmitted: (_) => _handleRegister(),
                          ),
                          const SizedBox(height: 16),
                          _CustomTextField(
                            controller: lastNameController,
                            hint: 'Apellido',
                            onSubmitted: (_) => _handleRegister(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _CustomTextField(
                          controller: emailController,
                          hint: 'Email',
                          onSubmitted: (_) => isSignIn ? _handleLogin() : _handleRegister(),
                        ),
                        const SizedBox(height: 16),
                        _CustomTextField(
                          controller: passwordController,
                          hint: 'Contraseña',
                          obscure: true,
                          onSubmitted: (_) => isSignIn ? _handleLogin() : _handleRegister(),
                        ),
                        if (!isSignIn) ...[
                          const SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                '• Al menos 8 caracteres',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '• Una letra mayúscula',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '• Un número',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '• Un símbolo (por ejemplo: ! @ # \$ &)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isSignIn
                                ? _handleLogin
                                : _handleRegister,
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
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _handleGoogleLogin,
                            icon: Icon(
                              Icons.g_mobiledata,
                              color: AppColors.secondary,
                              size: 28,
                            ),
                            label: Text(
                              isSignIn
                                  ? 'Iniciar sesión con Google'
                                  : 'Crear cuenta con Google',
                              style: TextStyle(
                                color: AppColors.secondary,
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
                        const SizedBox(height: 12),
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
        ],
      ),
    );
  }

  Future<void> _handleRegister() async {
    final name = nameController.text.trim();
    final lastName = lastNameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;

    final data = await ApiService.register(
      email: email,
      password: password,
      name: name,
      lastName: lastName,
    );
    if (data != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => widget.redirectTo ?? const HomePage(),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales invalidas. Inténtalo nuevamente.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final data = await ApiService.login(email: email, password: password);
    if (data != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => widget.redirectTo ?? const HomePage(),
        ),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Credenciales incorrectas. Inténtalo nuevamente.'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    // Mostrar loading mientras se procesa el login
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = await ApiService.loginWithGoogle();

      if (mounted) {
        Navigator.pop(context); // Cerrar loading

        if (data != null) {
          // Login exitoso
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => widget.redirectTo ?? const HomePage(),
            ),
          );
        } else {
          // Login fallido o cancelado
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo iniciar sesión con Google.'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar sesión: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final void Function(String)? onSubmitted;

  const _CustomTextField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 18,
        ),
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
