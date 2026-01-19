import 'package:flutter/material.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:soluva/services/api_services/worker_service.dart';
import 'package:soluva/widgets/header_widget.dart';
import 'package:soluva/widgets/dialogs/send_request_dialog.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  List<dynamic> _allWorkers = [];
  List<String> _subcategories = [];
  String? _selectedSubcategory;
  bool _loadingSubcategories = true;

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
    _fetchWorkers();
  }

  Future<void> _loadSubcategories() async {
    setState(() => _loadingSubcategories = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final baseUrl = dotenv.env['BASE_URL'] ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/service'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        List<String> foundSubcategories = [];

        // Buscar las subcategorías de esta categoría
        for (var mainCategory in data.entries) {
          final mainCategoryData = mainCategory.value as Map<String, dynamic>;

          for (var subCategory in mainCategoryData.entries) {
            // Comparación flexible (normalizar para comparar)
            if (_categoriesMatch(widget.category, subCategory.key)) {
              final services = subCategory.value as Map<String, dynamic>;
              foundSubcategories = services.keys.toList();
              break;
            }
          }

          if (foundSubcategories.isNotEmpty) break;
        }

        setState(() {
          _subcategories = foundSubcategories;
          _loadingSubcategories = false;
        });
      } else {
        setState(() => _loadingSubcategories = false);
      }
    } catch (e) {
      setState(() => _loadingSubcategories = false);
    }
  }

  bool _categoriesMatch(String cat1, String cat2) {
    final norm1 = cat1.toLowerCase().trim();
    final norm2 = cat2.toLowerCase().trim();

    // Comparación directa
    if (norm1.contains(norm2) || norm2.contains(norm1)) {
      return true;
    }

    // Comparación por palabras
    final words1 = norm1.split(' ').where((w) => w.length >= 3).toSet();
    final words2 = norm2.split(' ').where((w) => w.length >= 3).toSet();
    return words1.intersection(words2).isNotEmpty;
  }

  Future<void> _fetchWorkers() async {
    setState(() => _loading = true);
    try {
      final workers = await WorkerService.getWorkersByCategory(widget.category);
      setState(() {
        _allWorkers = workers;
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

  void _filterWorkersBySubcategory(String? subcategory) {
    setState(() {
      _selectedSubcategory = subcategory;
      if (subcategory == null) {
        _workers = _allWorkers;
      } else {
        // Filtrar trabajadores que tengan esta subcategoría en sus servicios
        _workers = _allWorkers.where((worker) {
          final services = worker['services'] as List<dynamic>? ?? [];
          return services.any((service) {
            final serviceName = service['service']?.toString().toLowerCase() ?? '';
            return serviceName.contains(subcategory.toLowerCase());
          });
        }).toList();
      }
    });
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
                // Botón de volver sutil
                Positioned(
                  top: 16,
                  left: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: AppColors.text,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
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
                                      .map((w) => _WorkerCard(
                                            worker: w,
                                            category: widget.category,
                                          ))
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
                          if (_loadingSubcategories)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else if (_subcategories.length == 1)
                            // Si solo hay una subcategoría, mostrar solo un label
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _subcategories[0],
                                    style: const TextStyle(
                                      color: AppColors.text,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else if (_subcategories.length > 1)
                            // Si hay múltiples subcategorías, mostrar dropdown
                            Container(
                              constraints: const BoxConstraints(maxWidth: 300),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.text.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.filter_list,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _selectedSubcategory,
                                        dropdownColor: AppColors.background,
                                        style: const TextStyle(
                                          color: AppColors.text,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        icon: const Icon(
                                          Icons.arrow_drop_down,
                                          color: AppColors.text,
                                          size: 20,
                                        ),
                                        isDense: true,
                                        items: [
                                          const DropdownMenuItem<String>(
                                            value: null,
                                            child: Text('Todos'),
                                          ),
                                          ..._subcategories.map((subcat) {
                                            return DropdownMenuItem<String>(
                                              value: subcat,
                                              child: Text(subcat),
                                            );
                                          }),
                                        ],
                                        onChanged: (value) {
                                          _filterWorkersBySubcategory(value);
                                        },
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
                ),
              ],
            ),
    );
  }
}

class _WorkerCard extends StatefulWidget {
  final Map<String, dynamic> worker;
  final String category;
  const _WorkerCard({required this.worker, required this.category});

  @override
  State<_WorkerCard> createState() => _WorkerCardState();
}

class _WorkerCardState extends State<_WorkerCard> {
  bool expanded = false;

  String _formatHour(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }

  @override
  Widget build(BuildContext context) {
    final worker = widget.worker;

    final services =
        (worker['services'] as List<dynamic>?)
            ?.map((s) => s as Map<String, dynamic>)
            .toList() ??
        [];

    final grouped = <String, List<String>>{};
    for (var item in services) {
      final category = item['category'] ?? 'Sin categoría';
      final service = item['service'] ?? '';
      grouped.putIfAbsent(category, () => []);
      grouped[category]!.add(service);
    }

    final serviceText = grouped.entries
        .map((entry) {
          final category = entry.key;
          final items = entry.value.take(3).join(', ');
          return "$category: $items";
        })
        .join('\n');

    final now = DateTime.now();
    final dias = List.generate(3, (i) {
      final date = now.add(Duration(days: i));
      if (i == 0) return "Hoy\n${_formatDate(date)}";
      if (i == 1) return "Mañana\n${_formatDate(date)}";
      return "${_weekdayName(date.weekday)}\n${_formatDate(date)}";
    });

    // Guardar las fechas formateadas para usarlas en el diálogo
    final diasFormatted = List.generate(3, (i) {
      final date = now.add(Duration(days: i));
      return "${date.day} ${_monthName(date.month)} ${date.year}";
    });

    final schedules = worker['available_schedules'] as List<dynamic>? ?? [];

    List<List<String>> horarios = List.generate(3, (_) => []);

    for (int i = 0; i < 3; i++) {
      final dateToCheck = DateTime(now.year, now.month, now.day + i);

      for (var sched in schedules) {
        final schedDate = DateTime.parse(sched['date']);
        if (schedDate.year == dateToCheck.year &&
            schedDate.month == dateToCheck.month &&
            schedDate.day == dateToCheck.day) {
          int start = sched['start'];
          int end = sched['end'];

          List<String> slots = [];
          DateTime t = DateTime(
            schedDate.year,
            schedDate.month,
            schedDate.day,
            start,
            0,
          );

          while (t.hour < end) {
            slots.add(_formatHour(t));
            t = t.add(const Duration(minutes: 30));
          }

          horarios[i] = slots;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(0),
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: AppColors.secondary,
              radius: 32,
              child: const Icon(Icons.person, color: Colors.white, size: 40),
            ),
            const SizedBox(width: 18),

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
                    serviceText,
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

            Container(
              width: 190,
              padding: const EdgeInsets.only(left: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(horarios.length, (i) {
                      final list = horarios[i];
                      final dateFormatted = diasFormatted[i];

                      return Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: expanded ? null : 150,
                          clipBehavior: Clip.hardEdge,
                          decoration: const BoxDecoration(),
                          child: expanded
                              ? Column(
                                  children: list
                                      .map((h) => _HorarioItem(
                                            h,
                                            onTap: () => _showRequestDialog(
                                              context,
                                              worker,
                                              h,
                                              dateFormatted,
                                            ),
                                          ))
                                      .toList(),
                                )
                              : _CollapsedScheduleColumn(list, dateFormatted, worker),
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 6),

                  TextButton.icon(
                    onPressed: () => setState(() => expanded = !expanded),
                    icon: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 18,
                    ),
                    label: Text(
                      expanded ? "Mostrar menos" : "Mostrar más",
                      style: const TextStyle(
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

  void _showRequestDialog(
    BuildContext context,
    Map<String, dynamic> worker,
    String time,
    String date,
  ) {
    showDialog(
      context: context,
      builder: (context) => SendRequestDialog(
        worker: worker,
        selectedTime: time,
        selectedDate: date,
        category: widget.category,
      ),
    );
  }

  Widget _CollapsedScheduleColumn(List<String> list, String dateFormatted, Map<String, dynamic> worker) {
    return ClipRect(
      child: SizedBox(
        height: 150,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(), // no deja scrollear
            child: Column(
              children: list
                  .take(5)
                  .map((h) => _HorarioItem(
                        h,
                        onTap: () => _showRequestDialog(
                          context,
                          worker,
                          h,
                          dateFormatted,
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ítem de horario
  Widget _HorarioItem(String h, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.button,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
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
    );
  }

  // Helpers
  static String _formatDate(DateTime date) =>
      "${date.day} ${_monthName(date.month)}";

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
    const days = ["Lun", "Mar", "Mie", "Jue", "Vie", "Sáb", "Dom"];
    return days[weekday - 1];
  }

  Widget _buildStars(num rating) {
    int full = rating.floor();
    bool half = (rating - full) >= 0.5;

    return Row(
      children: List.generate(5, (i) {
        if (i < full)
          return const Icon(Icons.star, color: Colors.black87, size: 18);
        if (i == full && half)
          return const Icon(Icons.star_half, color: Colors.black87, size: 18);
        return const Icon(Icons.star_border, color: Colors.black26, size: 18);
      }),
    );
  }
}
