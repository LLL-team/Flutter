import 'package:flutter/material.dart';
import 'package:soluva/services/api_services/api_service.dart';
import 'package:soluva/services/api_services/schedule_service.dart';
import 'package:soluva/theme/app_colors.dart';

class ProfileMisDatos extends StatefulWidget {
  final String? selectedTab;
  final bool viewingAsWorker;

  const ProfileMisDatos({
    super.key,
    this.selectedTab,
    this.viewingAsWorker = false,
  });

  @override
  State<ProfileMisDatos> createState() => _ProfileMisDatosState();
}

class _ProfileMisDatosState extends State<ProfileMisDatos> {
  Map<String, dynamic>? userData;
  List<Map<String, dynamic>> workerServices = [];
  bool loading = true;
  int selectedServiceTab = 0; // Para tabs de categorías de servicios

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final data = await ApiService.getUserProfile();

    // Si estamos en modo trabajador, cargar servicios del trabajador
    List<Map<String, dynamic>> services = [];
    if (widget.viewingAsWorker && data != null && data['uuid'] != null) {
      try {
        services = await ApiService.getWorkerServices(data['uuid']);
      } catch (e) {
        print('Error cargando servicios del trabajador: $e');
      }
    }

    setState(() {
      userData = data;
      workerServices = services;
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
        // Solo mostrar descripción en modo trabajador
        if (widget.viewingAsWorker) ...[
          const SizedBox(height: 16),
          _buildField("Descripción", userData!['description'] ?? ''),
        ],
      ],
    );
  }

  Widget _buildServiciosTab() {
    final services = workerServices;

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
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () => _showChangePriceDialog(),
                child: const Text(
                  "Cambiar precio",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90E2),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () => _showChangeScheduleDialog(),
                child: const Text(
                  "Cambiar horario",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
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

  void _showChangePriceDialog() {
    final services = userData!['services'] as List<dynamic>? ?? [];
    if (services.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes servicios para editar')),
      );
      return;
    }

    // DEBUG: Imprimir estructura de servicios
    print('DEBUG: Estructura de servicios:');
    for (var service in services) {
      print('  Servicio: $service');
    }

    // Obtener el servicio actual de la categoría seleccionada
    Map<String, List<Map<String, dynamic>>> serviciosPorCategoria = {};
    for (var service in services) {
      final category = service['category'] ?? 'Sin categoría';
      serviciosPorCategoria.putIfAbsent(category, () => []);
      serviciosPorCategoria[category]!.add(service as Map<String, dynamic>);
    }

    final categorias = serviciosPorCategoria.keys.toList();
    final selectedCategory = categorias.isNotEmpty ? categorias[selectedServiceTab] : '';
    final serviciosDeLaCategoria = serviciosPorCategoria[selectedCategory] ?? [];

    if (serviciosDeLaCategoria.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) {
        String? selectedService;
        final priceController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Cambiar precio de servicio'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar servicio',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedService,
                    items: serviciosDeLaCategoria.map<DropdownMenuItem<String>>((servicio) {
                      final serviceName = servicio['service']?.toString() ?? servicio['type']?.toString() ?? '';
                      return DropdownMenuItem<String>(
                        value: serviceName,
                        child: Text(serviceName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedService = value;
                        final servicio = serviciosDeLaCategoria.firstWhere(
                          (s) => (s['service']?.toString() ?? s['type']?.toString()) == value,
                        );
                        priceController.text = servicio['cost']?.toString() ?? '0';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Nuevo precio',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                  ),
                  onPressed: () async {
                    if (selectedService == null || priceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Completa todos los campos')),
                      );
                      return;
                    }

                    final newPrice = double.tryParse(priceController.text);
                    if (newPrice == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Precio inválido')),
                      );
                      return;
                    }

                    try {
                      print('DEBUG: Enviando actualización de precio');
                      print('  service: $selectedService');
                      print('  category: $selectedCategory');
                      print('  cost: $newPrice');

                      final success = await ApiService.updateWorkerServiceCost(
                        service: selectedService!,
                        category: selectedCategory,
                        cost: newPrice,
                      );

                      if (success && mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Precio actualizado correctamente')),
                        );
                        _loadUserData(); // Recargar datos
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No se pudo actualizar el precio')),
                        );
                      }
                    } catch (e) {
                      print('ERROR al actualizar precio: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Genera lista de horas en formato HH:mm (con ceros a la izquierda en horas)
  List<String> _generateTimeOptions() {
    final times = <String>[];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final hourStr = hour.toString().padLeft(2, '0'); // Con padLeft para formato HH:mm
        final minuteStr = minute.toString().padLeft(2, '0');
        times.add('$hourStr:$minuteStr');
      }
    }
    return times;
  }

  void _showChangeScheduleDialog() async {
    // Cargar horarios actuales
    final userUuid = userData!['uuid'];
    if (userUuid == null) return;

    List<Map<String, dynamic>> currentSchedules = [];
    try {
      currentSchedules = await ApiService.getWorkerSchedule(userUuid);
    } catch (e) {
      // Si no hay horarios, continuamos con lista vacía
    }

    if (!mounted) return;

    final timeOptions = _generateTimeOptions();

    showDialog(
      context: context,
      builder: (ctx) {
        final scheduleControllers = <Map<String, dynamic>>[];

        // Inicializar con horarios existentes o crear uno nuevo
        if (currentSchedules.isNotEmpty) {
          for (var schedule in currentSchedules) {
            // Convertir formato de tiempo si es necesario (mantener formato HH:mm)
            String startTime = schedule['start_time'] ?? '09:00';
            String endTime = schedule['end_time'] ?? '17:00';

            // Si viene con segundos (HH:MM:SS), convertir a HH:MM
            if (startTime.length > 5) startTime = startTime.substring(0, 5);
            if (endTime.length > 5) endTime = endTime.substring(0, 5);

            // Asegurar que tenga padding (9:00 -> 09:00)
            if (startTime.length == 4) startTime = '0$startTime';
            if (endTime.length == 4) endTime = '0$endTime';

            scheduleControllers.add({
              'day': schedule['day_of_week'] ?? 'Monday',
              'start': startTime,
              'end': endTime,
            });
          }
        } else {
          scheduleControllers.add({
            'day': 'Monday',
            'start': '09:00',
            'end': '17:00',
          });
        }

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Configurar horarios'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: scheduleControllers.length,
                  itemBuilder: (context, index) {
                    final schedule = scheduleControllers[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: schedule['day'],
                              decoration: const InputDecoration(
                                labelText: 'Día',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Monday', child: Text('Lunes')),
                                DropdownMenuItem(value: 'Tuesday', child: Text('Martes')),
                                DropdownMenuItem(value: 'Wednesday', child: Text('Miércoles')),
                                DropdownMenuItem(value: 'Thursday', child: Text('Jueves')),
                                DropdownMenuItem(value: 'Friday', child: Text('Viernes')),
                                DropdownMenuItem(value: 'Saturday', child: Text('Sábado')),
                                DropdownMenuItem(value: 'Sunday', child: Text('Domingo')),
                              ],
                              onChanged: (value) {
                                setDialogState(() => schedule['day'] = value!);
                              },
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: schedule['start'],
                                    decoration: const InputDecoration(
                                      labelText: 'Hora inicio',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: timeOptions.map((time) {
                                      return DropdownMenuItem<String>(
                                        value: time,
                                        child: Text(time),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setDialogState(() => schedule['start'] = value!);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: schedule['end'],
                                    decoration: const InputDecoration(
                                      labelText: 'Hora fin',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: timeOptions.map((time) {
                                      return DropdownMenuItem<String>(
                                        value: time,
                                        child: Text(time),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setDialogState(() => schedule['end'] = value!);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (scheduleControllers.length > 1)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setDialogState(() => scheduleControllers.removeAt(index));
                                },
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      scheduleControllers.add({
                        'day': 'Monday',
                        'start': '09:00',
                        'end': '17:00',
                      });
                    });
                  },
                  child: const Text('Agregar horario'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A90E2),
                  ),
                  onPressed: () async {
                    // Convert to the format expected by /schedule/replace endpoint
                    // Group schedules by day of week
                    final schedulesByDay = <String, List<Map<String, String>>>{};

                    // Initialize all days with empty arrays
                    for (var day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']) {
                      schedulesByDay[day] = [];
                    }

                    // Add schedules to their respective days
                    for (var s in scheduleControllers) {
                      final day = s['day'] as String;
                      schedulesByDay[day]!.add({
                        'start': s['start'] as String,
                        'end': s['end'] as String,
                      });
                    }

                    try {
                      final result = await ScheduleService.replaceSchedules(schedulesByDay);

                      if (result['success'] == true && mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? 'Horarios actualizados correctamente')),
                        );
                        _loadUserData();
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? 'Error al actualizar horarios')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}