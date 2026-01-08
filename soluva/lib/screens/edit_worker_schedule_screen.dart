import 'package:flutter/material.dart';
import '../services/api_services/schedule_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class EditWorkerScheduleScreen extends StatefulWidget {
  final String workerUuid;

  const EditWorkerScheduleScreen({
    super.key,
    required this.workerUuid,
  });

  @override
  State<EditWorkerScheduleScreen> createState() => _EditWorkerScheduleScreenState();
}

class _EditWorkerScheduleScreenState extends State<EditWorkerScheduleScreen> {
  final Map<String, List<TimeRange>> _schedulesByDay = {
    'Monday': [],
    'Tuesday': [],
    'Wednesday': [],
    'Thursday': [],
    'Friday': [],
    'Saturday': [],
    'Sunday': [],
  };

  final Map<String, String> _dayNames = {
    'Monday': 'Lunes',
    'Tuesday': 'Martes',
    'Wednesday': 'Miércoles',
    'Thursday': 'Jueves',
    'Friday': 'Viernes',
    'Saturday': 'Sábado',
    'Sunday': 'Domingo',
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    setState(() => _isLoading = true);

    final result = await ScheduleService.getSchedules(widget.workerUuid);

    if (result['success'] == true) {
      final schedules = result['schedules'] as List;

      // Limpiar horarios actuales
      _schedulesByDay.forEach((key, value) => value.clear());

      // Cargar horarios del backend
      for (var schedule in schedules) {
        final dayOfWeek = _capitalize(schedule['day_of_week']?.toString() ?? '');
        final startTime = schedule['start_time']?.toString() ?? '';
        final endTime = schedule['end_time']?.toString() ?? '';

        if (_schedulesByDay.containsKey(dayOfWeek) && startTime.isNotEmpty && endTime.isNotEmpty) {
          _schedulesByDay[dayOfWeek]!.add(
            TimeRange(
              start: _parseTime(startTime),
              end: _parseTime(endTime),
            ),
          );
        }
      }
    }

    setState(() => _isLoading = false);
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  TimeOfDay _parseTime(String time) {
    // Formato esperado: "HH:MM:SS" o "HH:MM"
    final parts = time.split(':');
    if (parts.length >= 2) {
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 0,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  Future<void> _saveSchedules() async {
    // Validar que no haya solapamientos
    for (var entry in _schedulesByDay.entries) {
      if (!_validateNoOverlap(entry.value)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hay horarios solapados en ${_dayNames[entry.key]}'),
            backgroundColor: AppColors.secondary,
          ),
        );
        return;
      }
    }

    // Convertir a formato de API (HH:mm format - con padding en hora)
    final schedulesByDayFormatted = <String, List<Map<String, String>>>{};

    // Incluir TODOS los días de la semana, incluso vacíos
    // Esto asegura que el endpoint replace elimine los horarios de días no incluidos
    for (var day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']) {
      final ranges = _schedulesByDay[day] ?? [];
      schedulesByDayFormatted[day] = ranges.map((range) {
        return {
          'start': '${range.start.hour.toString().padLeft(2, '0')}:${range.start.minute.toString().padLeft(2, '0')}',
          'end': '${range.end.hour.toString().padLeft(2, '0')}:${range.end.minute.toString().padLeft(2, '0')}',
        };
      }).toList();
    }

    print('DEBUG - Sending schedules: $schedulesByDayFormatted');

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await ScheduleService.replaceSchedules(schedulesByDayFormatted);

    if (mounted) Navigator.pop(context); // Cerrar indicador de carga

    if (result['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Horarios guardados'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar que se guardó
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al guardar horarios'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    }
  }

  bool _validateNoOverlap(List<TimeRange> ranges) {
    for (int i = 0; i < ranges.length; i++) {
      for (int j = i + 1; j < ranges.length; j++) {
        if (_rangesOverlap(ranges[i], ranges[j])) {
          return false;
        }
      }
    }
    return true;
  }

  bool _rangesOverlap(TimeRange a, TimeRange b) {
    final aStart = a.start.hour * 60 + a.start.minute;
    final aEnd = a.end.hour * 60 + a.end.minute;
    final bStart = b.start.hour * 60 + b.start.minute;
    final bEnd = b.end.hour * 60 + b.end.minute;

    return (aStart < bEnd && aEnd > bStart);
  }

  void _addTimeRange(String day) async {
    final TimeOfDay? startTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.secondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (startTime == null) return;

    final TimeOfDay? endTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: startTime.hour + 1, minute: startTime.minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.secondary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (endTime == null) return;

    // Validar que end sea mayor que start
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;

    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de fin debe ser mayor que la de inicio'),
          backgroundColor: AppColors.secondary,
        ),
      );
      return;
    }

    setState(() {
      _schedulesByDay[day]!.add(TimeRange(start: startTime, end: endTime));
    });
  }

  void _removeTimeRange(String day, int index) {
    setState(() {
      _schedulesByDay[day]!.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Editar Horarios',
          style: AppTextStyles.heading1.copyWith(fontSize: 20),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _schedulesByDay.keys.map((day) {
                      return _buildDaySection(day);
                    }).toList(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSchedules,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Guardar Horarios',
                        style: AppTextStyles.buttonText.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDaySection(String day) {
    final ranges = _schedulesByDay[day]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _dayNames[day]!,
                style: AppTextStyles.heading2.copyWith(fontSize: 18),
              ),
              IconButton(
                onPressed: () => _addTimeRange(day),
                icon: const Icon(Icons.add_circle, color: AppColors.secondary),
              ),
            ],
          ),
          if (ranges.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Sin horarios configurados',
                style: AppTextStyles.bodyText.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...ranges.asMap().entries.map((entry) {
              final index = entry.key;
              final range = entry.value;
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${range.start.format(context)} - ${range.end.format(context)}',
                      style: AppTextStyles.bodyText,
                    ),
                    IconButton(
                      onPressed: () => _removeTimeRange(day, index),
                      icon: const Icon(Icons.delete, color: AppColors.secondary, size: 20),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class TimeRange {
  final TimeOfDay start;
  final TimeOfDay end;

  TimeRange({required this.start, required this.end});
}
