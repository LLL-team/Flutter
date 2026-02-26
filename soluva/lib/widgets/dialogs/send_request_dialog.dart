import 'package:flutter/material.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:soluva/theme/app_text_styles.dart';
import 'package:soluva/services/api_services/api_service.dart';

class SendRequestDialog extends StatefulWidget {
  final Map<String, dynamic> worker;
  final String selectedTime;
  final String selectedDate;
  final String category;

  const SendRequestDialog({
    super.key,
    required this.worker,
    required this.selectedTime,
    required this.selectedDate,
    required this.category,
  });

  @override
  State<SendRequestDialog> createState() => _SendRequestDialogState();
}

class _SendRequestDialogState extends State<SendRequestDialog> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<Map<String, dynamic>> _workerTasks = [];
  String? _selectedTask;
  double? _selectedTaskCost;
  bool _loadingTasks = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _loadingTasks = true);

    try {
      final workerUuid = widget.worker['uuid']?.toString() ?? '';
      final allServices = await ApiService.getWorkerServices(workerUuid);

      // Filtrar los servicios del trabajador que correspondan a la categoría seleccionada
      final filtered = allServices.where((s) {
        final cat = s['category']?.toString() ?? '';
        return cat.toLowerCase().trim() == widget.category.toLowerCase().trim();
      }).toList();

      setState(() {
        _workerTasks = filtered;
        if (_workerTasks.isNotEmpty) {
          _selectedTask = _workerTasks[0]['service']?.toString();
          _selectedTaskCost = _parseCost(_workerTasks[0]['cost']);
        }
        _loadingTasks = false;
      });
    } catch (e) {
      debugPrint('Error loading worker tasks: $e');
      setState(() => _loadingTasks = false);
    }
  }

  double _parseCost(dynamic raw) {
    if (raw == null) return 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final workerName = "${widget.worker['name'] ?? ''} ${widget.worker['last_name'] ?? ''}".trim();

    return Dialog(
      backgroundColor: AppColors.text,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 700,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header con botón cerrar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Detalle de la solicitud',
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 32),

              // Información del trabajador
              Text(
                workerName,
                style: AppTextStyles.heading2.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Categoría
              Text(
                widget.category,
                style: AppTextStyles.bodyText.copyWith(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              // Dropdown de subcategorías
              if (_loadingTasks)
                const Center(child: CircularProgressIndicator())
              else if (_workerTasks.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedTask,
                  decoration: InputDecoration(
                    labelText: 'Tipo de servicio',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: AppColors.background.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: AppColors.text,
                  style: const TextStyle(color: Colors.white),
                  items: _workerTasks.map((task) {
                    final name = task['service']?.toString() ?? '';
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    final task = _workerTasks.firstWhere(
                      (t) => t['service']?.toString() == value,
                      orElse: () => {},
                    );
                    setState(() {
                      _selectedTask = value;
                      _selectedTaskCost = task.isNotEmpty ? _parseCost(task['cost']) : null;
                    });
                  },
                ),
              const SizedBox(height: 16),

              // Horario seleccionado
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.button,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.selectedTime} ${widget.selectedDate}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Precio de la tarea seleccionada
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _selectedTaskCost != null
                      ? '\$${_selectedTaskCost!.toStringAsFixed(2)}'
                      : '\$-',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Campo de dirección
              TextField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Dirección:',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: AppColors.background.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campo de descripción (opcional)
              TextField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: AppColors.background.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Enviar solicitud
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _sendRequest(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Enviar solicitud',
                    style: AppTextStyles.buttonText.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Texto informativo
              Text(
                '*En cuanto el trabajador responda se le notificará y podrá ejercer el pago',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.blue[300],
                  fontSize: 12,
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendRequest(BuildContext context) async {
    final address = _addressController.text.trim();
    final description = _descriptionController.text.trim();

    // Validaciones
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa una dirección'),
          backgroundColor: AppColors.secondary,
        ),
      );
      return;
    }

    if (_selectedTask == null || _selectedTask!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un tipo de servicio'),
          backgroundColor: AppColors.secondary,
        ),
      );
      return;
    }

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Parsear la fecha del formato "8 Ene 2026" al formato "2026-01-08"
      final dateStr = _parseDate(widget.selectedDate);

      final result = await ApiService.createRequest(
        location: address,
        date: dateStr,
        type: widget.category,
        subtype: _selectedTask!,
        workerUuid: widget.worker['uuid'],
        startAt: widget.selectedTime,
        amount: _selectedTaskCost ?? 0,
        description: description.isNotEmpty ? description : null,
      );

      if (mounted) Navigator.pop(context); // Cerrar indicador de carga

      if (mounted) {
        if (result['success'] == true) {
          Navigator.pop(context); // Cerrar diálogo
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Solicitud enviada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al enviar la solicitud'),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    }
  }

  // Función para parsear la fecha del formato "8 Ene 2026" a "2026-01-08"
  String _parseDate(String dateStr) {
    try {
      final parts = dateStr.split(' ');
      if (parts.length == 3) {
        final day = int.parse(parts[0]).toString().padLeft(2, '0');
        final monthMap = {
          'Ene': '01', 'Feb': '02', 'Mar': '03', 'Abr': '04',
          'May': '05', 'Jun': '06', 'Jul': '07', 'Ago': '08',
          'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dic': '12',
        };
        final month = monthMap[parts[1]] ?? '01';
        final year = parts[2];
        return '$year-$month-$day';
      }
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }
    // Fallback: devolver fecha actual
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
