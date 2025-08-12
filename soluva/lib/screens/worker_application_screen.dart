import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:soluva/services/api_services/api_service.dart';

class WorkerApplicationScreen extends StatefulWidget {
  const WorkerApplicationScreen({super.key});

  @override
  State<WorkerApplicationScreen> createState() =>
      _WorkerApplicationScreenState();
}

class _WorkerApplicationScreenState extends State<WorkerApplicationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _certificationController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _facePhoto;
  Uint8List? _webImageBytes;
  bool _isAuthenticated = false;
  bool _loadingAuth = true;
  Map<String, List<String>> _services = {};
  bool _loadingServices = true;

  List<String> _selectedServices = [];
  List<String> _selectedSubServices = [];

  File? _certificationPhoto;
  Uint8List? _webCertificationBytes;

  @override
  void initState() {
    super.initState();

    _checkAuthentication();
    _checkStatus();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _loadingServices = true);
    try {
      final services = await ApiService.getServices();
      setState(() {
        _services = services;
        _loadingServices = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to load services: $e")));
      setState(() => _loadingServices = false);
    }
  }

  Future<void> _checkAuthentication() async {
    final token = await ApiService.getToken();
    setState(() {
      _isAuthenticated = token != null && token.isNotEmpty;
      _loadingAuth = false;
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _facePhoto = null;
        });
      } else {
        setState(() {
          _facePhoto = File(picked.path);
          _webImageBytes = null;
        });
      }
    }
  }

  Future<void> _pickCertificationImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webCertificationBytes = bytes;
          _certificationPhoto = null;
        });
      } else {
        setState(() {
          _certificationPhoto = File(picked.path);
          _webCertificationBytes = null;
        });
      }
    }
  }

  void _submitApplication() async {
    if (_formKey.currentState!.validate() &&
        (_facePhoto != null || _webImageBytes != null) &&
        _selectedServices.isNotEmpty &&
        _selectedSubServices.isNotEmpty) {
      final token = await ApiService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: not authenticated")),
        );
        return;
      }

      Map<String, List<String>> tradeMap = {};
      for (String service in _selectedServices) {
        tradeMap[service] = _selectedSubServices
            .where(
              (subService) => _services[service]?.contains(subService) ?? false,
            )
            .toList();
      }
      print(
        "ä ver vamos a llmaar a la cosa :  AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
      );

      final response = await ApiService.enviarSolicitudTrabajador(
        nationalId: _dniController.text,
        trade: tradeMap,
        taskDescription: _descriptionController.text,
        description: _certificationController.text.isNotEmpty
            ? _certificationController.text
            : null,
        facePhoto: _facePhoto,
        webImageBytes: _webImageBytes,
        certifications: _certificationPhoto,
        webCertificationBytes: _webCertificationBytes,
        token: token,
      );
      print(
        "response: $response AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA",
      );
      print(" response['statusCode']: ${response.statusCode}");
      // 🔹 Aquí revisamos statusCode 201
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Su solicitud fue enviada a revisión.")),
        );

        // Espera un momento para que el usuario vea el mensaje
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: ${response.body}")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please fill all required fields, upload a photo, and select services.",
          ),
        ),
      );
    }
  }

  Widget _buildImagePreview() {
    if (kIsWeb) {
      if (_webImageBytes != null) {
        return Image.memory(_webImageBytes!, fit: BoxFit.cover);
      }
    } else {
      if (_facePhoto != null) {
        return Image.file(_facePhoto!, fit: BoxFit.cover);
      }
    }
    return const Center(child: Text("Tap to upload face photo"));
  }

  Widget _buildCertificationPreview() {
    if (kIsWeb) {
      if (_webCertificationBytes != null) {
        return Image.memory(_webCertificationBytes!, fit: BoxFit.cover);
      }
    } else {
      if (_certificationPhoto != null) {
        return Image.file(_certificationPhoto!, fit: BoxFit.cover);
      }
    }
    return const Center(child: Text("Tap to upload certification photo"));
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingAuth || _loadingServices) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthenticated) {
      return const Scaffold(
        body: Center(child: Text("You must be logged in to access this page.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Worker Application')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _dniController,
                decoration: const InputDecoration(labelText: 'DNI'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'DNI is required';
                  } else if (value.length != 8) {
                    return 'DNI must be exactly 8 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildImagePreview(),
                ),
              ),
              const SizedBox(height: 16),

              // Multi-select para servicios
              MultiSelectDialogField(
                title: const Text("Select Services"),
                buttonText: const Text("Services"),
                items: _services.keys
                    .map((e) => MultiSelectItem<String>(e, e))
                    .toList(),
                listType: MultiSelectListType.CHIP,
                onConfirm: (values) {
                  setState(() {
                    _selectedServices = List<String>.from(values);
                    _selectedSubServices.clear();
                  });
                },
                validator: (values) => (values == null || values.isEmpty)
                    ? "Select at least one service"
                    : null,
              ),
              const SizedBox(height: 16),

              // Multi-select para subservicios
              MultiSelectDialogField(
                title: const Text("Select Sub-Services"),
                buttonText: const Text("Sub-Services"),
                items: _selectedServices
                    .expand((service) => _services[service] ?? [])
                    .map((sub) => MultiSelectItem<String>(sub, sub))
                    .toList(),
                listType: MultiSelectListType.CHIP,
                onConfirm: (values) {
                  setState(() {
                    _selectedSubServices = List<String>.from(values);
                  });
                },
                validator: (values) => (values == null || values.isEmpty)
                    ? "Select at least one sub-service"
                    : null,
              ),
              const SizedBox(height: 16),
              // Dentro del ListView, después del SizedBox(height: 16) de la imagen:
              GestureDetector(
                onTap:
                    _pickCertificationImage, // ← Ahora sí puedes tocar para subir
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _buildCertificationPreview(),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _certificationController,
                decoration: const InputDecoration(
                  labelText: 'Certification (optional)',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Task Description',
                ),
                maxLines: 4,
                validator: (value) => value == null || value.isEmpty
                    ? 'Task Description is required'
                    : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitApplication,
                child: const Text("Submit Application"),
              ),
            ],
          ),
        ),
      ),
    );
  }

void _checkStatus() async {
  final response = await ApiService.getStatus();
  // final data = json.decode(response.body);

  print(response['status']);

  if (response['status'] == 'pending') {
    // Mostrar alerta
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Aviso"),
          content: const Text("Ya tienes una solicitud pendiente."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();  
              },
              child: const Text("Aceptar"),
            ),
          ],
        );
      },
    );
  }
}
}
