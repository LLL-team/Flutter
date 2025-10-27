import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soluva/screens/auth_screen.dart';
import 'package:soluva/screens/search_workers_screen.dart';
import 'package:soluva/screens/worker_application_screen.dart';
import 'package:soluva/screens/workers_list_screen.dart';
import 'package:soluva/widgets/header_widget.dart';
import 'package:soluva/theme/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final fondoPath =
        dotenv.env['default_cover_webp'] ?? 'assets/images/fondo-inicio.webp';
    final offerServiceBtn =
        dotenv.env['offer_service_button'] ??
        'assets/images/boton_ofrecer_servicio.webp';
    final searchServiceBtn =
        dotenv.env['search_service_button'] ??
        'assets/images/boton_buscar_servicio.webp';

    return Scaffold(
      appBar: const HeaderWidget(),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Fondo liso primero
          Container(color: AppColors.background),
          // Imagen de fondo encima
          Positioned.fill(child: Image.asset(fondoPath, fit: BoxFit.cover)),
          ListView(
            padding: const EdgeInsets.all(0),
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _MainImageButton(
                    image: offerServiceBtn,
                    onTap: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final token = prefs.getString('auth_token');

                      if (token != null && token.isNotEmpty) {
                        // Usuario logueado → ir a pantalla de aplicación
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkerApplicationScreen(),
                          ),
                        );
                      } else {
                        // Usuario NO logueado → ir a AuthScreen con redirección
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuthScreen(
                              redirectTo: WorkerApplicationScreen(),
                            ),
                          ),
                        );
                      }
                    },
                  ),

                  _MainImageButton(
                    image: searchServiceBtn,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SearchWorkersScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Cómo funciona?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _StepItem(number: 1, text: 'Registrate o inicia sesión.'),
                      _StepItem(
                        number: 2,
                        text: 'Elige una categoría y servicio.',
                      ),
                      _StepItem(
                        number: 3,
                        text: 'Contacta y contrata al profesional.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 32,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _CategoryCard(
                      label: 'AUTOMÓVIL',
                      icon: Icons.directions_car,
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const WorkersByCategoryScreen(category: 'Auto'),
                          ),
                        );
                      },
                    ),
                    _CategoryCard(
                      label: 'PLOMERÍA',
                      icon: Icons.plumbing,
                      color: AppColors.secondary,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'plomer\u00eda',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryCard(
                      label: 'JARDINERÍA',
                      icon: Icons.grass,
                      color: Colors.green,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'Jard\u00edn',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryCard(
                      label: 'ELECTRICIDAD',
                      icon: Icons.electrical_services,
                      color: Colors.yellow.shade700,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'electricidad',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryCard(
                      label: 'LIMPIEZA',
                      icon: Icons.cleaning_services,
                      color: Colors.blueGrey,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'limpieza',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ],
      ),
    );
  }
}

class _MainImageButton extends StatelessWidget {
  final String image;
  final VoidCallback onTap;

  const _MainImageButton({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          32,
        ), // opcional, para bordes redondeados
        child: Image.asset(image, width: 160, height: 170, fit: BoxFit.cover),
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final int number;
  final String text;

  const _StepItem({required this.number, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number.',
            style: const TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: AppColors.text, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
