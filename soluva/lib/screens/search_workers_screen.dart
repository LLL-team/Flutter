import 'package:flutter/material.dart';
import 'package:soluva/services/api_services/utils_service.dart';
import 'package:soluva/services/api_services/worker_service.dart';

class SearchWorkersScreen extends StatefulWidget {
  const SearchWorkersScreen({super.key});

  @override
  State<SearchWorkersScreen> createState() => _SearchWorkersScreenState();
}

class _SearchWorkersScreenState extends State<SearchWorkersScreen> {
  Map<String, List<String>> _services = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _loading = true);
    try {
      final services = await UtilsService.getServices();
      setState(() {
        _services = services;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar servicios: $e')),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Trabajadores')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text(
              'Selecciona una categoría:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ..._services.keys.map((category) => Card(
                  child: ListTile(
                    title: Text(category),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              WorkersListScreen(category: category),
                        ),
                      );
                    },
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class WorkersListScreen extends StatefulWidget {
  final String category;

  const WorkersListScreen({super.key, required this.category});

  @override
  State<WorkersListScreen> createState() => _WorkersListScreenState();
}

class _WorkersListScreenState extends State<WorkersListScreen> {
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
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Trabajadores en ${widget.category}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _workers.isEmpty
              ? const Center(child: Text('No hay trabajadores en esta categoría.'))
              : ListView.builder(
                  itemCount: _workers.length,
                  itemBuilder: (context, index) {
                    final worker = _workers[index];
                    return Card(
                      child: ListTile(
                        leading: worker['profile_photo'] != null
                            ? CircleAvatar(
                                backgroundImage: NetworkImage(
                                  '${worker['profile_photo'].toString().startsWith('http') ? '' : 'http://127.0.0.1:8000'}${worker['profile_photo']}',
                                ),
                              )
                            : const CircleAvatar(child: Icon(Icons.person)),
                        title: Text('${worker['name']} ${worker['last_name']}'),
                        subtitle: Text(worker['description'] ?? ''),
                      ),
                    );
                  },
                ),
    );
  }
}