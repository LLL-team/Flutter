import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soluva/screens/auth_screen.dart';
import 'package:soluva/screens/worker_application_screen.dart';
import 'package:soluva/screens/workers_list_screen.dart';
import 'package:soluva/screens/profile_screen.dart';
import 'package:soluva/services/api_services/api_service.dart';
import 'package:soluva/services/api_services/utils_service.dart';
import 'package:soluva/widgets/header_widget.dart';
import 'package:soluva/theme/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ScrollController _scrollController;
  final _categoriesKey = GlobalKey();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _categories = [];
  bool _loadingCategories = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await UtilsService.getServices();
      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(data['categories'] ?? []);
          _loadingCategories = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        setState(() => _loadingCategories = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Busca subcategorías y tareas que coincidan con el query.
  /// Retorna una lista de {subcategoryName, categoryName, matchedOn} para mostrar resultados.
  List<Map<String, String>> _searchResults() {
    if (_searchQuery.isEmpty) return [];
    final query = _searchQuery.toLowerCase();
    final results = <Map<String, String>>[];

    for (final category in _categories) {
      final categoryName = category['name'] ?? '';
      final subcategories = List<Map<String, dynamic>>.from(category['subcategories'] ?? []);

      for (final subcategory in subcategories) {
        final subcategoryName = subcategory['name'] ?? '';
        final tasks = List<Map<String, dynamic>>.from(subcategory['tasks'] ?? []);

        // Match por nombre de subcategoría
        if (subcategoryName.toLowerCase().contains(query)) {
          results.add({
            'subcategory': subcategoryName,
            'category': categoryName,
            'match': subcategoryName,
          });
          continue;
        }

        // Match por nombre de tarea
        for (final task in tasks) {
          final taskName = task['name'] ?? '';
          if (taskName.toLowerCase().contains(query)) {
            results.add({
              'subcategory': subcategoryName,
              'category': categoryName,
              'match': taskName,
            });
            break; // Una sola coincidencia por subcategoría es suficiente
          }
        }
      }
    }
    return results;
  }

  Future<void> _handleOfferService() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty) {
      try {
        final response = await ApiService.getWorkerStatus();
        final status = response['status'];

        if (!context.mounted) return;

        if (status == 'approved') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ProfileScreen(
                initialViewingAsWorker: true,
                initialSelectedMenu: 1,
                initialWorkerTab: 'Servicios',
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const WorkerApplicationScreen(),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        Navigator.push(
          this.context,
          MaterialPageRoute(
            builder: (_) => const WorkerApplicationScreen(),
          ),
        );
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AuthScreen(
            redirectTo: WorkerApplicationScreen(),
          ),
        ),
      );
    }
  }

  void _scrollToCategories() {
    final ctx = _categoriesKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showSubcategoriesDialog(Map<String, dynamic> category) {
    final subcategories = List<Map<String, dynamic>>.from(category['subcategories'] ?? []);
    final categoryName = category['name'] ?? 'Categoría';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A4A),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary,
                      AppColors.secondary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.category,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        categoryName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              // Subcategories list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: subcategories.length,
                  itemBuilder: (context, index) {
                    final subcategory = subcategories[index];
                    final subcategoryName = subcategory['name'] ?? 'Subcategoría';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkersByCategoryScreen(
                                  category: subcategoryName,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAE6DB),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getSubcategoryIcon(subcategoryName),
                                    color: AppColors.secondary,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    subcategoryName,
                                    style: const TextStyle(
                                      color: AppColors.text,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: AppColors.secondary.withValues(alpha: 0.7),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSubcategoryIcon(String name) {
    final nameLower = name.toLowerCase();
    if (nameLower.contains('aire')) return Icons.ac_unit;
    if (nameLower.contains('electric')) return Icons.electric_bolt;
    if (nameLower.contains('plom')) return Icons.plumbing;
    if (nameLower.contains('gas') || nameLower.contains('calef')) return Icons.local_fire_department;
    if (nameLower.contains('pintura')) return Icons.format_paint;
    if (nameLower.contains('albañil')) return Icons.construction;
    if (nameLower.contains('durlock')) return Icons.grid_view;
    if (nameLower.contains('carpint')) return Icons.carpenter;
    if (nameLower.contains('herrer')) return Icons.hardware;
    if (nameLower.contains('instalacion')) return Icons.build;
    if (nameLower.contains('montaje')) return Icons.handyman;
    if (nameLower.contains('limpieza')) return Icons.cleaning_services;
    if (nameLower.contains('jardin')) return Icons.grass;
    if (nameLower.contains('pileta')) return Icons.pool;
    if (nameLower.contains('riego')) return Icons.water_drop;
    if (nameLower.contains('auto')) return Icons.directions_car;
    if (nameLower.contains('grúa') || nameLower.contains('grua')) return Icons.car_repair;
    if (nameLower.contains('flete')) return Icons.local_shipping;
    if (nameLower.contains('auxilio')) return Icons.car_crash;
    if (nameLower.contains('cerraj')) return Icons.lock;
    if (nameLower.contains('digital')) return Icons.fingerprint;
    if (nameLower.contains('apertura')) return Icons.lock_open;
    if (nameLower.contains('estética') || nameLower.contains('estetica') || nameLower.contains('belleza')) return Icons.face_retouching_natural;
    if (nameLower.contains('masaje')) return Icons.spa;
    if (nameLower.contains('reiki')) return Icons.self_improvement;
    if (nameLower.contains('reflexo')) return Icons.accessibility_new;
    return Icons.home_repair_service;
  }

  String _getCategoryImage(String categoryName) {
    final nameLower = categoryName.toLowerCase();
    if (nameLower.contains('hogar')) return 'assets/icons/servicios/Boton-I.Electricidad.png';
    if (nameLower.contains('construcci')) return 'assets/icons/servicios/Boton-I.Albanileria.png';
    if (nameLower.contains('limpieza')) return 'assets/icons/servicios/Boton-I.Limpieza.png';
    if (nameLower.contains('vehículo') || nameLower.contains('vehiculo') || nameLower.contains('transporte')) return 'assets/icons/servicios/Boton-I.Auto.png';
    if (nameLower.contains('seguridad')) return 'assets/icons/servicios/Boton-I.Cerrajeria.png';
    if (nameLower.contains('bienestar')) return 'assets/icons/servicios/Boton-I.Bienestar.png';
    return 'assets/icons/servicios/Boton-I.Service.png';
  }

  @override
  Widget build(BuildContext context) {
    final fondoPath =
        dotenv.env['default_cover_webp'] ?? 'assets/images/fondo-inicio.webp';
    final offerServiceBtn =
        dotenv.env['offer_service_button'] ??
        'assets/images/boton_ofrecer_servicio.png';
    final searchServiceBtn =
        dotenv.env['search_service_button'] ??
        'assets/images/boton_buscar_servicio.webp';

    return Scaffold(
      appBar: const HeaderWidget(),
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Container(color: AppColors.background),
          Positioned.fill(child: Image.asset(fondoPath, fit: BoxFit.cover)),
          LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isMobile = screenWidth < 650;

              return ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(0),
                children: [
                  const SizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
                    child: isMobile
                        ? Column(
                            children: [
                              _MainImageButton(
                                image: offerServiceBtn,
                                onTap: () => _handleOfferService(),
                              ),
                              const SizedBox(height: 12),
                              _MainImageButton(
                                image: searchServiceBtn,
                                onTap: _scrollToCategories,
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _MainImageButton(
                                image: offerServiceBtn,
                                onTap: () => _handleOfferService(),
                              ),
                              _MainImageButton(
                                image: searchServiceBtn,
                                onTap: _scrollToCategories,
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¿Cómo funciona?',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 20,
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
                  // Buscador
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Buscar servicio...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: AppColors.secondary, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Resultados de búsqueda
                  if (_searchQuery.isNotEmpty) ...[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
                      child: Builder(
                        builder: (context) {
                          final results = _searchResults();
                          if (results.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.background.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'No se encontraron servicios',
                                style: TextStyle(color: AppColors.text, fontSize: 15),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          return Container(
                            decoration: BoxDecoration(
                              color: AppColors.background.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: results.map((result) {
                                return InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => WorkersByCategoryScreen(
                                          category: result['subcategory']!,
                                        ),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getSubcategoryIcon(result['subcategory']!),
                                          color: AppColors.secondary,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                result['subcategory']!,
                                                style: const TextStyle(
                                                  color: AppColors.text,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                ),
                                              ),
                                              if (result['match'] != result['subcategory'])
                                                Text(
                                                  'Tarea: ${result['match']}',
                                                  style: TextStyle(
                                                    color: AppColors.text.withValues(alpha: 0.6),
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              Text(
                                                result['category']!,
                                                style: TextStyle(
                                                  color: AppColors.text.withValues(alpha: 0.5),
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: AppColors.secondary.withValues(alpha: 0.7),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
              Center(
                key: _categoriesKey,
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
              // Categories from API
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _loadingCategories
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : _categories.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32),
                              child: Text(
                                'No se pudieron cargar las categorías',
                                style: TextStyle(color: AppColors.text),
                              ),
                            ),
                          )
                        : Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: _categories.map((category) {
                              final categoryName = category['name'] ?? 'Categoría';
                              return _CategoryCard(
                                categoryName: categoryName,
                                imagePath: _getCategoryImage(categoryName),
                                onTap: () => _showSubcategoriesDialog(category),
                              );
                            }).toList(),
                          ),
              ),
              const SizedBox(height: 32),
                ],
              );
            },
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;

    final double finalWidth;
    final double finalHeight;

    if (isMobile) {
      finalWidth = (screenWidth - 48).clamp(200.0, 400.0);
      finalHeight = finalWidth * 0.55;
    } else {
      final buttonWidth = (screenWidth - 48) * 0.45;
      finalWidth = buttonWidth.clamp(150.0, 250.0);
      finalHeight = (finalWidth * 1.02).clamp(153.0, 255.0);
    }

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Image.asset(
          image,
          width: finalWidth,
          height: finalHeight,
          fit: BoxFit.cover,
        ),
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
  final String categoryName;
  final String imagePath;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.categoryName,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;

        const minCardWidth = 150.0;

        final availableWidth = screenWidth - 32;
        int columns = (availableWidth / minCardWidth).floor();

        columns = columns.clamp(2, 6);

        final totalSpacing = 16 * (columns - 1);
        final cardWidth = (availableWidth - totalSpacing) / columns;

        final cardHeight = cardWidth * 1.1; // Slightly taller to fit text

        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: cardWidth,
            height: cardHeight,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.home_repair_service,
                            color: AppColors.secondary,
                            size: 48,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      categoryName,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
