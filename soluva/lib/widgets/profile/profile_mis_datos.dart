import 'package:flutter/material.dart';
import 'package:soluva/services/api_services/api_service.dart';
import 'package:soluva/theme/app_colors.dart';

class ProfileMisDatos extends StatefulWidget {
  final String? selectedTab;

  const ProfileMisDatos({super.key, this.selectedTab});

  @override
  State<ProfileMisDatos> createState() => _ProfileMisDatosState();
}

class _ProfileMisDatosState extends State<ProfileMisDatos> {
  Map<String, dynamic>? userData;
  bool loading = true;
  int selectedServiceTab = 0; // Para tabs de categorías de servicios

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await ApiService.getUserProfile();
    setState(() {
      userData = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (userData == null) {
      return const Center(child: Text('No se pudo cargar los datos'));
    }

    final selectedTab = widget.selectedTab ?? 'Perfil';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Contenido según tab
        if (selectedTab == "Perfil")
          _buildPerfilTab()
        else if (selectedTab == "Servicios")
          _buildServiciosTab()
        else
          _buildHorariosTab(),
      ],
    );
  }

  Widget _buildPerfilTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField("Nombre", userData!['name'] ?? ''),
        const SizedBox(height: 16),
        _buildField("Apellido", userData!['last_name'] ?? ''),
        const SizedBox(height: 16),
        _buildField("Email", userData!['email'] ?? ''),
        const SizedBox(height: 16),
        _buildField("Descripción", userData!['description'] ?? ''),
      ],
    );
  }

  Widget _buildServiciosTab() {
    final services = userData!['services'] as List<dynamic>? ?? [];

    if (services.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            "No tienes servicios registrados.",
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ),
      );
    }

    // Agrupar servicios por categoría
    Map<String, List<Map<String, dynamic>>> serviciosPorCategoria = {};
    for (var service in services) {
      final category = service['category'] ?? 'Sin categoría';
      serviciosPorCategoria.putIfAbsent(category, () => []);
      serviciosPorCategoria[category]!.add(service as Map<String, dynamic>);
    }

    final categorias = serviciosPorCategoria.keys.toList();
    final selectedCategory = categorias.isNotEmpty ? categorias[selectedServiceTab] : '';
    final serviciosDeLaCategoria = serviciosPorCategoria[selectedCategory] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs de categorías
        if (categorias.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(categorias.length, (index) {
                final isSelected = selectedServiceTab == index;
                return GestureDetector(
                  onTap: () => setState(() => selectedServiceTab = index),
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.button.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      categorias[index],
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        const SizedBox(height: 16),
        // Servicios de la categoría seleccionada
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedCategory.isNotEmpty)
              Text(
                "Servicios de $selectedCategory:",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
            const SizedBox(height: 12),
            ...serviciosDeLaCategoria.map((servicio) {
              final type = servicio['type'] ?? 'Servicio';
              final price = servicio['price'] ?? 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.button),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            type.toString(),
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '\$$price',
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
          onPressed: () {
            // Navegar para editar servicios
          },
          child: const Text(
            "Editar Servicios",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildHorariosTab() {
    final horarios = userData!['schedule'] as List? ?? [];

    if (horarios.isEmpty) {
      return const Center(
        child: Text(
          "No tienes horarios registrados.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tus horarios:",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        ...horarios.map((horario) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, color: AppColors.button),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "${horario['day'] ?? 'Día'} - ${horario['start'] ?? '--'} a ${horario['end'] ?? '--'}",
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () {
            // Navegar para editar horarios
          },
          child: const Text(
            "Editar Horarios",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.text,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}