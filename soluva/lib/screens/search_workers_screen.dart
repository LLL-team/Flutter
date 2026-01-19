import 'package:flutter/material.dart';
import 'package:soluva/services/api_services/utils_service.dart';
import 'package:soluva/screens/workers_list_screen.dart';

class SearchWorkersScreen extends StatefulWidget {
  const SearchWorkersScreen({super.key});

  @override
  State<SearchWorkersScreen> createState() => _SearchWorkersScreenState();
}

class _SearchWorkersScreenState extends State<SearchWorkersScreen> {
  Map<String, dynamic> _services = {};
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
      print(e);
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cargar servicios: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Obtener todas las subcategorías de todas las categorías
    List<MapEntry<String, String>> allSubcategories = [];
    
    _services.forEach((category, subcategories) {
      if (subcategories is Map<String, dynamic>) {
        subcategories.forEach((subcategory, services) {
          allSubcategories.add(MapEntry(subcategory, category));
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar Trabajadores'),
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
            const Text(
              'Selecciona un servicio:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...allSubcategories.map(
              (entry) => Card(
                child: ListTile(
                  title: Text(entry.key),
                  subtitle: Text('Categoría: ${_formatCategoryName(entry.value)}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            WorkersByCategoryScreen(category: entry.key),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCategoryName(String category) {
    final Map<String, String> categoryNames = {
      'casa': 'Casa',
      'llaves': 'Llaves',
      'auto': 'Auto',
      'camion': 'Camión',
      'jardin': 'Jardín',
      'bienestar': 'Bienestar',
    };
    return categoryNames[category] ?? category;
  }
}