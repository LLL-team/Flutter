import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../screens/profile_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/home_screen.dart';
import '../theme/app_colors.dart';

class HeaderWidget extends StatefulWidget implements PreferredSizeWidget {
  const HeaderWidget({super.key});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();

  @override
  Size get preferredSize => const Size.fromHeight(60);
}

class _HeaderWidgetState extends State<HeaderWidget> {
  bool isAuthenticated = false;
  String? userName;
  final GlobalKey _userMenuKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final name = prefs.getString('user_name');
    setState(() {
      isAuthenticated = token != null;
      userName = name;
    });
  }

  void _showUserMenu() async {
    final RenderBox renderBox =
        _userMenuKey.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        overlay.size.width - offset.dx - size.width,
        0,
      ),
      color: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      items: [
        // PopupMenuItem<String>(
        //   enabled: false,
        //   padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        //   child: Row(
        //     children: [
        //       Text(
        //         userName ?? "Usuario",
        //         style: const TextStyle(
        //           fontWeight: FontWeight.bold,
        //           fontSize: 17,
        //           color: AppColors.text,
        //         ),
        //       ),
        //       const Spacer(),
        //       CircleAvatar(
        //         backgroundColor: AppColors.secondary,
        //         radius: 20,
        //         child: Image.asset(
        //           'assets/icons/user_orange.png', // Usa tu icono naranja aquí
        //           width: 32,
        //           height: 32,
        //           fit: BoxFit.contain,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        // const PopupMenuDivider(),
        PopupMenuItem<String>(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          },
          child: Row(
            children: [
              Image.asset(
                dotenv.env['ICON_USER_BLUE'] ?? 'assets/icons/user_blue.png',
                width: 27,
                height: 31,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              const Text("Mi Perfil", style: TextStyle(color: AppColors.text)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ProfileScreen(initialSelectedMenu: 2),
              ),
            );
          },
          child: Row(
            children: [
              Image.asset(
                dotenv.env['ICON_BRIEFCASE_BLUE'] ??
                    'assets/icons/briefcase_blue.png', // Icono Mis trabajos
                width: 22,
                height: 27,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              const Text(
                "Mis trabajos",
                style: TextStyle(color: AppColors.text),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          onTap: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('auth_token');
            await prefs.remove('user_name');
            if (mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            }
          },
          child: Row(
            children: [
              Image.asset(
                dotenv.env['ICON_LOGOUT_BLUE'] ??
                    'assets/icons/logout_blue.png', // Icono Salir
                width: 21,
                height: 28,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 10),
              const Text("Salir", style: TextStyle(color: AppColors.text)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoPath =
        dotenv.env['header_logo'] ?? 'assets/images/Logo_Header.webp';
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          // Logo con navegación al Home
          GestureDetector(
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
              );
            },
            child: Image.asset(logoPath, height: 36, fit: BoxFit.contain),
          ),
          const Spacer(),
          // Nombre de usuario o ¿Cómo funciona?
          isAuthenticated
              ? GestureDetector(
                  key: _userMenuKey,
                  onTap: _showUserMenu,
                  child: Row(
                    children: [
                      Text(
                        userName ?? "Usuario",
                        style: const TextStyle(
                          color: AppColors.text,
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: AppColors.background,
                        radius: 18,
                        child: Image.asset(
                          dotenv.env['ICON_USER_ORANGE'] ??
                              'assets/icons/user_orange.png',
                          width: 28,
                          height: 28,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
                )
              : Text(
                  '¿Cómo funciona?',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
          const SizedBox(width: 24),
          // Botón Ingresar si no está autenticado
          if (!isAuthenticated)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.buttonText,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                );
              },
              child: const Text(
                'Ingresar',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
