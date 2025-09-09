import 'package:flutter/material.dart';
import 'package:soluva/services/api_services/api_service.dart';

class WorkerServicesPage extends StatefulWidget {
  final String uuid; 

  const WorkerServicesPage({Key? key, required this.uuid}) : super(key: key);

  @override
  State<WorkerServicesPage> createState() => _WorkerServicesPageState();
}

class _WorkerServicesPageState extends State<WorkerServicesPage> {
  final TextEditingController _costController = TextEditingController();

  String? _selectedCategory;
  String? _selectedService;
  String? _selectedType = "hora";
  Map<String, List<String>> _servicesByCategory = {};
  List<Map<String, dynamic>> _myServices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _fetchMyServices();
  }

  /// OBTENER TODAS LAS CATEGORÍAS Y SERVICIOS
  Future<void> _fetchServices() async {
    try {
      final services = await ApiService.getServices();
      setState(() {
        _servicesByCategory = services;
      });
    } catch (e) {
      debugPrint("Error al obtener servicios: $e");
    }
  }

  /// OBTENER SERVICIOS DEL TRABAJADOR USANDO UUID
  Future<void> _fetchMyServices() async {
    try {
      final services = await ApiService.getWorkerServices(widget.uuid);
      setState(() {
        _myServices = services;
      });
    } catch (e) {
      debugPrint("Error al obtener mis servicios: $e");
    }
  }

  /// AGREGAR NUEVO SERVICIO
  Future<void> _addService() async {
    if (_selectedCategory == null || _selectedService == null || _costController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Completa todos los campos.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.addWorkerService(
        type: _selectedType!,
        category: _selectedCategory!,
        service: _selectedService!,
        cost: double.tryParse(_costController.text) ?? 0,
      );

      if (result["status"] == "success") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Servicio agregado correctamente.")),
        );
        _fetchMyServices();
        _costController.clear();
        setState(() {
          _selectedCategory = null;
          _selectedService = null;
          _selectedType = "hora";
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${result["message"] ?? "No se pudo agregar."}")),
        );
      }
    } catch (e) {
      debugPrint("Error al agregar servicio: $e");
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Servicios del Trabajador")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// CATEGORÍA
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: "Categoría"),
              items: _servicesByCategory.keys.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  _selectedService = null;
                });
              },
            ),
            const SizedBox(height: 16),

            /// SERVICIO
            DropdownButtonFormField<String>(
              value: _selectedService,
              decoration: const InputDecoration(labelText: "Servicio"),
              items: _selectedCategory == null
                  ? []
                  : _servicesByCategory[_selectedCategory]!
                      .map((service) => DropdownMenuItem(value: service, child: Text(service)))
                      .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedService = value;
                });
              },
            ),
            const SizedBox(height: 16),

            /// TIPO DE COBRO
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: "Tipo de Cobro"),
              items: ["hora", "fijo"]
                  .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedType = value);
              },
            ),
            const SizedBox(height: 16),

            /// COSTO
            TextField(
              controller: _costController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Costo", prefixText: "\$ "),
            ),
            const SizedBox(height: 20),

            /// BOTÓN GUARDAR
            ElevatedButton(
              onPressed: _isLoading ? null : _addService,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Agregar Servicio"),
            ),
            const SizedBox(height: 24),

            /// LISTA DE SERVICIOS
            const Text("Mis Servicios", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_myServices.isEmpty)
              const Text("No tienes servicios registrados.")
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _myServices.length,
                itemBuilder: (context, index) {
                  final service = _myServices[index];
                  return Card(
                    child: ListTile(
                      title: Text("${service['category']} - ${service['service']}"),
                      subtitle: Text("Tipo: ${service['type']} | \$${service['cost']}"),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
