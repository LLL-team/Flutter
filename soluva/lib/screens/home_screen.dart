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
                      imagePath: 'icons/servicios/Boton-I.Aire.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'Aire acondicionado',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryCard(
                      imagePath: 'icons/servicios/Boton-I.Albanileria.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'Albañilería',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryCard(
                      imagePath: 'icons/servicios/Boton-I.Auto.png',
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
                      imagePath: 'icons/servicios/Boton-I.Bienestar.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'Bienestar',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryCard(
                      imagePath: 'icons/servicios/Boton-I.Carpinteria.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'Carpintería',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryCard(
                      imagePath: 'icons/servicios/Boton-I.Cerrajeria.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'Cerrajería',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryCard(
                      imagePath: 'icons/servicios/Boton-I.Durlock.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'Durlock',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryCard(
                      imagePath: 'icons/servicios/Boton-I.Electricidad.png',
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
                      imagePath: 'icons/servicios/Boton-I.Flete.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'Flete',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryCard(
                      imagePath: 'icons/servicios/Boton-I.Gas.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'Gas',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryCard(
                      imagePath: 'icons/servicios/Boton-I.Herreria.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'Herrería',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryCard(
                      imagePath: 'icons/servicios/Boton-I.imc.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'Informática',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryCard(
                      imagePath: 'icons/servicios/Boton-I.Jardineria.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'Service',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryCard(
                      imagePath: 'icons/servicios/Boton-I.Limpieza.png',
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
                    _CategoryCard(
                      imagePath: 'icons/servicios/Boton-I.Pintura.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'Pintura',
                            ),
                          ),
                        );
                      },
                    ),
                    _CategoryCard(
                      imagePath: 'icons/servicios/Boton-I.Plomeria.png',
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
                      imagePath: 'icons/servicios/Boton-I.Service.png',
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
                      imagePath: 'icons/servicios/Boton-I.Tutti.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WorkersByCategoryScreen(
                              category: 'Tutti',
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
        child: Image.asset(image, width: 210, height: 215, fit: BoxFit.cover),
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
  final String imagePath;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;

        // Ancho mínimo deseado para cada card
        const minCardWidth = 150.0;

        // Calcular número de columnas dinámicamente según el ancho disponible
        final availableWidth = screenWidth - 32; // Restar padding horizontal
        int columns = (availableWidth / minCardWidth).floor();

        // Asegurar al menos 2 columnas y máximo 6
        columns = columns.clamp(2, 6);

        // Calcular ancho de card considerando spacing
        final totalSpacing = 16 * (columns - 1); // spacing entre cards
        final cardWidth = (availableWidth - totalSpacing) / columns;

        // Altura proporcional al ancho (mantener relación de aspecto)
        final cardHeight = cardWidth * 0.85;

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: cardWidth,
            height: cardHeight,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}
