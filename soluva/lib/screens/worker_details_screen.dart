import 'package:flutter/material.dart';
import 'package:soluva/services/api_services/worker_service.dart';

class WorkerDetailsScreen extends StatefulWidget {
  final String uuid;
  const WorkerDetailsScreen({super.key, required this.uuid});

  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen> {
  bool _loading = true;
  Map<String, dynamic>? _worker;

  @override
  void initState() {
    super.initState();
    _fetchWorker();
  }

  Future<void> _fetchWorker() async {
    setState(() => _loading = true);
    try {
      final worker = await WorkerService.getWorkerByUuid(widget.uuid);
      setState(() {
        _worker = worker;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_worker == null) {
      return const Scaffold(
        body: Center(child: Text('No se encontró el trabajador.')),
      );
    }

    final trade = _worker!['trade'] as Map<String, dynamic>? ?? {};
    final tradeWidgets = trade.entries.map((entry) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
        Wrap(
          spacing: 8,
          children: (entry.value as List<dynamic>)
              .map((s) => Chip(label: Text(s.toString())))
              .toList(),
        ),
        const SizedBox(height: 8),
      ],
    ));

    return Scaffold(
      appBar: AppBar(title: Text('${_worker!['name']} ${_worker!['last_name']}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Center(
              child: CircleAvatar(
                radius: 48,
                // backgroundImage: _worker!['profile_photo'] != null
                //     ? NetworkImage(
                //         '${_worker!['profile_photo'].toString().startsWith('http') ? '' : 'http://127.0.0.1:8000'}${_worker!['profile_photo']}',
                //       )
                //     : null,
                child: _worker!['profile_photo'] == null
                    ? const Icon(Icons.person, size: 48)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            if (_worker!['face_photo'] != null)
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(
                    '${_worker!['face_photo'].toString().startsWith('http') ? '' : 'http://127.0.0.1:8000'}${_worker!['face_photo']}',
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              _worker!['description'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text('Servicios:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...tradeWidgets,
            const SizedBox(height: 16),
            if (_worker!['certifications'] != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Certificaciones:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_worker!['certifications'].toString()),
                  const SizedBox(height: 16),
                ],
              ),
            ElevatedButton(
              onPressed: () {
                // Aquí puedes implementar la lógica de contratación
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('¡Has contratado a este trabajador!')),
                );
              },
              child: const Text('Contratar'),
            ),
          ],
        ),
      ),
    );
  }
}