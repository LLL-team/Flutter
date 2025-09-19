import 'package:flutter/material.dart';
import 'package:soluva/services/api_services/utils_service.dart';
import 'package:soluva/screens/workers_list_screen.dart';

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
                          builder: (context) => WorkersByCategoryScreen(category: category),
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