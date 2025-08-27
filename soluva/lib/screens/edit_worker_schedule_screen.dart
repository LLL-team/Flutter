import 'package:flutter/material.dart';

class EditWorkerScheduleScreen extends StatefulWidget {
  final List<String> availableHours; // Ejemplo: ['08:00-12:00', '14:00-18:00']
  const EditWorkerScheduleScreen({super.key, required this.availableHours});

  @override
  State<EditWorkerScheduleScreen> createState() => _EditWorkerScheduleScreenState();
}

class _EditWorkerScheduleScreenState extends State<EditWorkerScheduleScreen> {
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = widget.availableHours
        .map((h) => TextEditingController(text: h))
        .toList();
  }

  @override
  void dispose() {
    _controllers.forEach((c) => c.dispose());
    super.dispose();
  }

  void _addHour() {
    setState(() {
      _controllers.add(TextEditingController());
    });
  }

  void _saveSchedule() {
    final hours = _controllers.map((c) => c.text).where((h) => h.isNotEmpty).toList();
    // Aquí puedes guardar los horarios en tu backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Horarios guardados')),
    );
    Navigator.pop(context, hours);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar horarios disponibles')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ..._controllers.asMap().entries.map((entry) => Card(
                child: ListTile(
                  title: TextField(
                    controller: entry.value,
                    decoration: const InputDecoration(labelText: 'Horario (ej: 08:00-12:00)'),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _controllers.removeAt(entry.key);
                      });
                    },
                  ),
                ),
              )),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addHour,
            icon: const Icon(Icons.add),
            label: const Text('Agregar horario'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _saveSchedule,
            child: const Text('Guardar horarios'),
          ),
        ],
      ),
    );
  }
}