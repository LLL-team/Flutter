import 'package:flutter/material.dart';
import 'package:soluva/services/api_services/api_service.dart';

class WorkerDetailsScreen extends StatefulWidget {
  final String uuid;
  const WorkerDetailsScreen({super.key, required this.uuid});

  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen> {
  bool _loading = true;
  Map<String, dynamic>? _worker;
  final Map<String, bool> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _fetchWorker();
  }

  Future<void> _fetchWorker() async {
    setState(() => _loading = true);
    try {
      final worker = await ApiService.getWorkerByUuid(widget.uuid);
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
    final tradeWidgets = trade.entries.map((entry) {
      final categoryKey = entry.key;
      final services = entry.value as List<dynamic>;
      final isExpanded = _expandedCategories[categoryKey] ?? false;
      final maxInitialServices = 4; // Mostrar máximo 4 servicios inicialmente
      final hasMore = services.length > maxInitialServices;
      final displayServices = (isExpanded || !hasMore)
          ? services
          : services.take(maxInitialServices).toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(categoryKey, style: const TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: displayServices
                .map((s) => Chip(label: Text(s.toString())))
                .toList(),
          ),
          if (hasMore)
            TextButton(
              onPressed: () {
                setState(() {
                  _expandedCategories[categoryKey] = !isExpanded;
                });
              },
              child: Text(
                isExpanded
                    ? 'Ver menos'
                    : 'Ver más (+${services.length - maxInitialServices})',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          const SizedBox(height: 8),
        ],
      );
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('${_worker!['name']} ${_worker!['last_name']}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Volver',
        ),
      ),
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