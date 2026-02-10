import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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

  // Nueva estructura para categorías
  List<Map<String, dynamic>> _categories = [];

  // Selección: categoría -> subcategoría -> tareas
  Map<String, dynamic>? _selectedCategory;
  Map<String, dynamic>? _selectedSubcategory;
  List<String> _selectedTasks = [];

  File? _certificationPhoto;
  Uint8List? _webCertificationBytes;

  String _userName = "";

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
    _checkStatus();
    _loadServices();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final profile = await ApiService.getUserProfile();
    setState(() {
      _userName = profile?['name'] != null && profile?['last_name'] != null
          ? "${profile!['name']} ${profile['last_name']}"
          : (profile?['name'] ?? "Usuario");
    });
  }

  Future<void> _checkStatus() async {
    try {
      final response = await ApiService.getWorkerStatus();
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
        _categories = List<Map<String, dynamic>>.from(services['categories'] ?? []);
        _loadingServices = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al cargar servicios: $e")),
        );
      }
      if (mounted) setState(() => _loadingServices = false);
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
        _selectedSubcategory != null &&
        _selectedTasks.isNotEmpty) {
      final token = await ApiService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error: no autenticado")),
        );
        return;
      }

      // Construir el trade map con la nueva estructura
      Map<String, dynamic> tradeMap = {
        "categoria": _selectedSubcategory!['name'],
        "tareas": _selectedTasks,
      };

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.body}")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Por favor completa todos los campos requeridos, sube una foto y selecciona servicios.",
          ),
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _subcategories {
    if (_selectedCategory == null) return [];
    return List<Map<String, dynamic>>.from(_selectedCategory!['subcategories'] ?? []);
  }

  List<Map<String, dynamic>> get _tasks {
    if (_selectedSubcategory == null) return [];
    return List<Map<String, dynamic>>.from(_selectedSubcategory!['tasks'] ?? []);
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingAuth || _loadingServices || _loadingStatus) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthenticated) {
      return const Scaffold(
        body: Center(child: Text("Debes iniciar sesión para acceder a esta página.")),
      );
    }

    if (_workerStatus == "approved") {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Estado de tu perfil"),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Volver',
          ),
        ),
        body: const Center(
          child: Text(
            "Tu perfil de trabajador ya fue aprobado",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const HeaderWidget(),
      body: Stack(
        children: [
          // Fondo degradado radial naranja
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Color.fromARGB(255, 255, 140, 4),
                    Color.fromARGB(255, 255, 120, 4),
                  ],
                  stops: [0.2, 1.0],
                ),
              ),
            ),
          ),
          // Botón de volver sutil
          Positioned(
            top: 16,
            left: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 400,
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                  horizontal: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        "Para inscribirte como ",
                        style: TextStyle(fontSize: 16, color: Colors.white),
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
                                color: Colors.white,
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
                            _userName.isNotEmpty ? _userName : "Cargando...",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Disclaimer colapsable
                      const _InfoDisclaimer(),
                      const SizedBox(height: 18),
                      _CustomField(
                        label: "DNI:",
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

                      // Selección de CATEGORÍA
                      _CustomField(
                        label: "Categoría:",
                        child: DropdownButtonFormField<Map<String, dynamic>>(
                          decoration: _inputDecoration(),
                          hint: const Text("Seleccionar categoría"),
                          value: _selectedCategory,
                          items: _categories.map((category) {
                            return DropdownMenuItem<Map<String, dynamic>>(
                              value: category,
                              child: Text(category['name'] ?? 'Sin nombre'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                              _selectedSubcategory = null;
                              _selectedTasks = [];
                            });
                          },
                          validator: (value) =>
                              value == null ? "Selecciona una categoría" : null,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Selección de SUBCATEGORÍA
                      if (_selectedCategory != null)
                        _CustomField(
                          label: "Subcategoría:",
                          child: DropdownButtonFormField<Map<String, dynamic>>(
                            decoration: _inputDecoration(),
                            hint: const Text("Seleccionar subcategoría"),
                            value: _selectedSubcategory,
                            items: _subcategories.map((subcategory) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: subcategory,
                                child: Text(subcategory['name'] ?? 'Sin nombre'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedSubcategory = value;
                                _selectedTasks = [];
                              });
                            },
                            validator: (value) =>
                                value == null ? "Selecciona una subcategoría" : null,
                          ),
                        ),
                      if (_selectedCategory != null) const SizedBox(height: 12),

                      // Selección de TAREAS (múltiple)
                      if (_selectedSubcategory != null)
                        _CustomField(
                          label: "Tareas que realizas:",
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.primary, width: 2),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: _tasks.map((task) {
                                final taskName = task['name'] ?? '';
                                final isSelected = _selectedTasks.contains(taskName);
                                return CheckboxListTile(
                                  title: Text(
                                    taskName,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    _getPriceTypeLabel(task['price_type']),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  value: isSelected,
                                  activeColor: AppColors.secondary,
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                  onChanged: (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedTasks.add(taskName);
                                      } else {
                                        _selectedTasks.remove(taskName);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      if (_selectedSubcategory != null) const SizedBox(height: 12),

                      // Mostrar tareas seleccionadas
                      if (_selectedTasks.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Tareas seleccionadas:",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _selectedTasks.map((task) {
                                  return Chip(
                                    label: Text(
                                      task,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: AppColors.background,
                                    deleteIcon: const Icon(Icons.close, size: 16),
                                    onDeleted: () {
                                      setState(() {
                                        _selectedTasks.remove(task);
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      if (_selectedTasks.isNotEmpty) const SizedBox(height: 12),

                      _CustomField(
                        label: "Certificación / Matrícula (opcional):",
                        child: TextFormField(
                          controller: _certificationController,
                          decoration: _inputDecoration(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _CustomField(
                        label: "Descripción de tus servicios:",
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
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: Image.memory(
                                          _webImageBytes!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      )
                                    : _facePhoto != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(11),
                                            child: Image.file(
                                              _facePhoto!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                          )
                                        : const Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.camera_alt, color: Colors.black54),
                                                SizedBox(height: 4),
                                                Text(
                                                  "Foto de rostro",
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
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
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(11),
                                        child: Image.memory(
                                          _webCertificationBytes!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      )
                                    : _certificationPhoto != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(11),
                                            child: Image.file(
                                              _certificationPhoto!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                          )
                                        : const Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.file_copy, color: Colors.black54),
                                                SizedBox(height: 4),
                                                Text(
                                                  "Certificación",
                                                  style: TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 12,
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
                        style: TextStyle(color: Colors.black54, fontSize: 13),
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

  String _getPriceTypeLabel(String? priceType) {
    switch (priceType) {
      case 'fixed':
        return 'Precio fijo';
      case 'fixed_per_hour':
        return 'Precio por hora';
      case 'fixed_m2':
        return 'Precio por m²';
      case 'fixed_km':
        return 'Precio por km';
      case 'visit_budget':
        return 'Presupuesto con visita';
      default:
        return 'Precio a definir';
    }
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(color: Colors.red, width: 2),
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

class _InfoDisclaimer extends StatefulWidget {
  const _InfoDisclaimer();

  @override
  State<_InfoDisclaimer> createState() => _InfoDisclaimerState();
}

class _InfoDisclaimerState extends State<_InfoDisclaimer> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Información importante",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Text(
                "• Seleccione solo su trabajo principal.\n"
                "• Luego puede agregar más categorías una vez creado el perfil.\n"
                "• Si tiene una certificación, se recomienda que elija el trabajo para el que está certificado.",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
