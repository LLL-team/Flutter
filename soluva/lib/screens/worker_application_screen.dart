import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soluva/services/api_services/api_service.dart';
import 'package:soluva/services/api_services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkerApplicationScreen extends StatefulWidget {
  const WorkerApplicationScreen({super.key});

  @override
  State<WorkerApplicationScreen> createState() =>
      _WorkerApplicationScreenState();
}

class _WorkerApplicationScreenState extends State<WorkerApplicationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _certificationController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _facePhoto; // Para mobile
  Uint8List? _webImageBytes; // Para web

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

  void _submitApplication() async {
    if (_formKey.currentState!.validate() &&
        (_facePhoto != null || _webImageBytes != null)) {
      String? token = await ProfileService.getToken();
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error no esta autenticaddo")),
        );
        return;
      } else {
        ApiService.enviarSolicitudTrabajador(
          nationalId: _dniController.text,
          trade: _occupationController.text,
          taskDescription: _descriptionController.text,
          description: _certificationController.text.isNotEmpty
              ? _certificationController.text
              : null,
          facePhoto: _facePhoto,
          certifications:
              null, // Podrías agregar otro picker para certificaciones si es necesario
          token:
              token, // Aquí deberías obtener el token de autenticación si es necesario
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Your application has been submitted for review."),
          ),
        );
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields and upload a photo."),
        ),
      );
    }
  }

  @override
  void dispose() {
    _dniController.dispose();
    _occupationController.dispose();
    _certificationController.dispose();
    _descriptionController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: ProfileService.getToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final token = snapshot.data;

        if (token == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Acceso Denegado')),
            body: const Center(
              child: Text(
                "Debes iniciar sesión para completar esta solicitud.",
              ),
            ),
          );
        }

        // El token existe → usuario autenticado → mostrar formulario
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
                    validator: (value) => value == null || value.isEmpty
                        ? 'DNI is required'
                        : null,
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
                  TextFormField(
                    controller: _occupationController,
                    decoration: const InputDecoration(labelText: 'Occupation'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Occupation is required'
                        : null,
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
                      labelText: 'Task Description (optional)',
                    ),
                    maxLines: 4,
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
      },
    );
  }
}
