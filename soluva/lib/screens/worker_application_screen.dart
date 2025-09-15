import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:soluva/services/api_services/api_service.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:soluva/widgets/header_widget.dart';

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
  bool _loadingServices = true;
  bool _loadingStatus = true;

  String? _workerStatus;
  Map<String, List<String>> _services = {};

  List<String> _selectedServices = [];
  List<String> _selectedSubServices = [];

  File? _certificationPhoto;
  Uint8List? _webCertificationBytes;

  String _userName = "María Lopez"; // Puedes obtenerlo del perfil si lo tienes

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _checkStatus();
    _loadServices();
    // TODO: Cargar el nombre real del usuario si está disponible
  }

  Future<void> _checkStatus() async {
    try {
      final response = await ApiService.getStatus();
      setState(() {
        _workerStatus = response['status'];
        _loadingStatus = false;
      });
    } catch (e) {
      setState(() => _loadingStatus = false);
    }
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

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Su solicitud fue enviada a revisión.")),
        );
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

  @override
  Widget build(BuildContext context) {
    if (_loadingAuth || _loadingServices || _loadingStatus) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthenticated) {
      return const Scaffold(
        body: Center(child: Text("You must be logged in to access this page.")),
      );
    }

    if (_workerStatus == "approved") {
      return Scaffold(
        appBar: AppBar(title: const Text("Estado de tu perfil")),
        body: const Center(
          child: Text(
            "✅ Tu perfil de trabajador ya fue aprobado",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // 🔹 FORMULARIO CON DISEÑO PERSONALIZADO
return Scaffold(
  appBar: HeaderWidget(),
  body: Stack(
    children: [
      // 🔹 Fondo degradado radial naranja
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Color.fromARGB(255, 255, 140, 4), // naranja más claro al centro
                Color.fromARGB(255, 255, 120, 4), // naranja más oscuro en los bordes
              ],
              stops: [0.2, 1.0],
            ),
          ),
        ),
      ),

      // 🔹 Contenido principal
      Center(
        child: SingleChildScrollView(
          child: Container(
            width: 400,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text(
                    "Para inscribirte como ",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: "prestador ",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        TextSpan(
                          text: ", necesitamos los siguientes datos:",
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.button,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _CustomField(
                    label: "Dni:",
                    child: TextFormField(
                      controller: _dniController,
                      decoration: _inputDecoration(),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'DNI es requerido';
                        } else if (value.length != 8) {
                          return 'DNI debe tener 8 dígitos';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CustomField(
                    label: "Oficio:",
                    child: MultiSelectDialogField(
                      title: const Text("Oficio"),
                      buttonText: const Text("Seleccionar oficio"),
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
                          ? "Selecciona al menos un oficio"
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CustomField(
                    label: "Certificación / Matrícula:",
                    child: TextFormField(
                      controller: _certificationController,
                      decoration: _inputDecoration(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CustomField(
                    label: "Descripción de tareas:",
                    child: TextFormField(
                      controller: _descriptionController,
                      decoration: _inputDecoration(),
                      maxLines: 4,
                      validator: (value) => value == null || value.isEmpty
                          ? 'La descripción es requerida'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border.all(color: AppColors.primary),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _webImageBytes != null
                                ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                                : _facePhoto != null
                                    ? Image.file(_facePhoto!, fit: BoxFit.cover)
                                    : const Center(
                                        child: Text(
                                          "Foto de rostro",
                                          style: TextStyle(color: Colors.black54),
                                        ),
                                      ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickCertificationImage,
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border.all(color: AppColors.primary),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: _webCertificationBytes != null
                                ? Image.memory(_webCertificationBytes!, fit: BoxFit.cover)
                                : _certificationPhoto != null
                                    ? Image.file(_certificationPhoto!, fit: BoxFit.cover)
                                    : const Center(
                                        child: Text(
                                          "Foto de documento",
                                          style: TextStyle(color: Colors.black54),
                                        ),
                                      ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitApplication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        "SOLICITAR ALTA",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "*Una vez enviada la solicitud, aguardar mail con la autorización.",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],	
                
              ),
            ),
          ),
        ),
      ),
    ],
  ),
);
  }
  InputDecoration _inputDecoration() => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
      );
}

class _CustomField extends StatelessWidget {
  final String label;
  final Widget child;

  const _CustomField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}
