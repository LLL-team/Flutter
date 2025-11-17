import 'package:flutter/material.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:soluva/services/api_services/worker_service.dart';
import 'package:soluva/widgets/header_widget.dart';

class WorkersByCategoryScreen extends StatefulWidget {
  final String category;
  const WorkersByCategoryScreen({super.key, required this.category});

  @override
  State<WorkersByCategoryScreen> createState() =>
      _WorkersByCategoryScreenState();
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
      appBar: const HeaderWidget(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Cards de trabajadores
                Padding(
                  padding: const EdgeInsets.only(top: 90),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    children: [
                      Center(
                        child: SizedBox(
                          width: 600,
                          child: Column(
                            children: _workers.isEmpty
                                ? [
                                    const Padding(
                                      padding: EdgeInsets.all(40),
                                      child: Center(
                                        child: Text(
                                          "No se encontraron trabajadores disponibles en esta categoría.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ]
                                : _workers
                                      .map((w) => _WorkerCard(worker: w))
                                      .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Cabecera de categoría con sombra proyectada
                Positioned(
                  top: 25,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 700,
                      margin: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.7),
                            blurRadius: 10,
                            offset: const Offset(0, 8),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 24,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.lightbulb,
                            color: AppColors.primary,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.electrical_services,
                            color: AppColors.secondary,
                            size: 32,
                          ),
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
                ),
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
    // Obtengo la lista de servicios del worker (del trade por categoría)
    final services =
        (worker['trade'] as Map<String, dynamic>?)?.values
            .expand((s) => (s as List<dynamic>))
            .toList() ??
        [];

    // Generamos los 3 días dinámicamente
    final now = DateTime.now();
    final dias = List.generate(3, (i) {
      final date = now.add(Duration(days: i));
      if (i == 0) return "Hoy\n${_formatDate(date)}";
      if (i == 1) return "Mañana\n${_formatDate(date)}";
      return "${_weekdayName(date.weekday)}\n${_formatDate(date)}";
    });

    // Ejemplo de horarios fijos (en la práctica deberías traerlos desde API)
    final horarios = [
      ["17:45", "18:30", "19:30"],
      ["08:30", "09:00", "09:30", "11:00"],
      ["08:30", "09:00", "09:30", "11:00"],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.0),
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
              child: const Icon(Icons.person, color: Colors.white, size: 40),
            ),
            const SizedBox(width: 18),
            // Info principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${worker['name'] ?? ''} ${worker['last_name'] ?? ''}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    services.take(3).join(', '),
                    style: const TextStyle(color: AppColors.text, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildStars(worker['ratings_avg'] ?? 4),
                      const SizedBox(width: 6),
                      Text(
                        "${worker['ratings_count'] ?? 0} opiniones",
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Horarios
            Container(
              width: 190,
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera de días
                  Row(
                    children: dias
                        .map(
                          (d) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                d,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 10),
                  // Horarios
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      horarios.length,
                      (i) => Expanded(
                        child: Column(
                          children: horarios[i]
                              .map(
                                (h) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 3,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.button,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 0,
                                    ),
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
                                ),
                              )
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

  // Helpers para formatear fecha y nombre del día
  static String _formatDate(DateTime date) {
    return "${date.day} ${_monthName(date.month)}";
  }

  static String _monthName(int month) {
    const months = [
      "Ene",
      "Feb",
      "Mar",
      "Abr",
      "May",
      "Jun",
      "Jul",
      "Ago",
      "Sep",
      "Oct",
      "Nov",
      "Dic",
    ];
    return months[month - 1];
  }

  static String _weekdayName(int weekday) {
    const days = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"];
    return days[weekday - 1];
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
