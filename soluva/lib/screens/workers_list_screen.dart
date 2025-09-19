import 'package:flutter/material.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:soluva/services/api_services/worker_service.dart';

class WorkersByCategoryScreen extends StatefulWidget {
  final String category;
  const WorkersByCategoryScreen({super.key, required this.category});

  @override
  State<WorkersByCategoryScreen> createState() => _WorkersByCategoryScreenState();
}

class _WorkersByCategoryScreenState extends State<WorkersByCategoryScreen> {
  bool _loading = true;
  List<dynamic> _workers = [];

  @override
  void initState() {
    super.initState();
    _fetchWorkers();
  }

  Future<void> _fetchWorkers() async {
    setState(() => _loading = true);
    try {
      final workers = await WorkerService.getWorkersByCategory(widget.category);
      setState(() {
        _workers = workers;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar trabajadores: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.text,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              // Logo
              Image.asset(
                'assets/images/Logo_Header.webp',
                height: 36,
                fit: BoxFit.contain,
              ),
              const Spacer(),
              Text(
                'María Lopez',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              const CircleAvatar(
                backgroundColor: AppColors.secondary,
                child: Icon(Icons.person, color: Colors.white),
                radius: 16,
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 0),
              children: [
                // Header de categoría
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb, color: AppColors.primary, size: 32),
                        const SizedBox(width: 8),
                        const Icon(Icons.electrical_services, color: AppColors.secondary, size: 32),
                        const SizedBox(width: 16),
                        Text(
                          widget.category,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 26,
                            color: AppColors.text,
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          "*(Filtro de servicio requerido)*",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Lista de trabajadores
                ..._workers.map((worker) => _WorkerCard(worker: worker)).toList(),
              ],
            ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  final Map<String, dynamic> worker;
  const _WorkerCard({required this.worker});

  @override
  Widget build(BuildContext context) {
    // Simulación de datos de horarios
    final horarios = [
      ["17:45", "18:30", "19:30"],
      ["08:30", "09:00", "09:30", "11:00"],
      ["08:30", "09:00", "09:30", "11:00"],
    ];
    final dias = ["Hoy\n17 Sep", "Mañana\n18 Sep", "Vie\n19 Sep"];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: AppColors.secondary,
              radius: 32,
              child: Icon(Icons.person, color: Colors.white, size: 40),
            ),
            const SizedBox(width: 18),
            // Info principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    worker['name'] ?? 'Nombre',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    (worker['services'] as List<dynamic>?)
                            ?.take(3)
                            .join(', ') ??
                        '',
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildStars(worker['rating'] ?? 4),
                      const SizedBox(width: 6),
                      Text(
                        "${worker['opinions'] ?? 0} opiniones",
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: AppColors.text),
                      const SizedBox(width: 4),
                      Text(
                        worker['address'] ?? 'Dirección de atención',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Horarios
            Container(
              width: 170,
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: dias
                        .map((d) => Expanded(
                              child: Text(
                                d,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      horarios.length,
                      (i) => Expanded(
                        child: Column(
                          children: horarios[i]
                              .map((h) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.button,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4, horizontal: 0),
                                      child: Center(
                                        child: Text(
                                          h,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.expand_more, size: 18),
                    label: const Text(
                      "Mostrar más",
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStars(num rating) {
    int fullStars = rating.floor();
    bool halfStar = (rating - fullStars) >= 0.5;
    return Row(
      children: List.generate(5, (i) {
        if (i < fullStars) {
          return const Icon(Icons.star, color: Colors.black87, size: 18);
        } else if (i == fullStars && halfStar) {
          return const Icon(Icons.star_half, color: Colors.black87, size: 18);
        } else {
          return const Icon(Icons.star_border, color: Colors.black26, size: 18);
        }
      }),
    );
  }
}
