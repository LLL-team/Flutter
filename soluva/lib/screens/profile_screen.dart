import 'package:flutter/material.dart';
import 'package:soluva/screens/home_screen.dart';
import 'package:soluva/services/api_services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:soluva/widgets/header_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  bool loading = true;
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  String? profileImageUrl;

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });

      // Subir la imagen al servidor
      await ApiService.uploadProfileImage(_imageFile!.path);

      // Volver a cargar los datos del usuario para actualizar la imagen
      await loadUser();
    }
  }

  @override
  void initState() {
    super.initState();
    loadUser();
  }

 Future<void> loadUser() async {
  final data = await ApiService.getUserProfile();
  if (mounted) {
    setState(() {
      user = data;
      loading = false;
    });
  }

  // Si hay uuid, buscar la imagen después
  if (data != null && data['uuid'] != null) {
    final fotoUrl = await ApiService.getFoto(data['uuid']);
    if (mounted) {
      setState(() {
        profileImageUrl = fotoUrl;
      });
    }
  }
}


  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No se pudo cargar el perfil')),
      );
    }

    final fullName = "${user!['name'] ?? ''} ${user!['last_name'] ?? ''}"
        .trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _imageFile != null
                        ? FileImage(File(_imageFile!.path))
                        : (profileImageUrl != null
                                  ? NetworkImage(profileImageUrl!)
                                  : null)
                              as ImageProvider<Object>?,
                    child: (_imageFile == null && profileImageUrl == null)
                        ? const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.camera_alt, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Text(
              fullName.isNotEmpty ? fullName : 'Nombre no disponible',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              user!['email'] ?? 'Email no disponible',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            if (user!['descripcion'] != null) ...[
              const SizedBox(height: 20),
              Text(
                user!['descripcion'],
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Acción para editar el perfil
              },
              icon: const Icon(Icons.edit),
              label: const Text('Editar Perfil'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Configuración'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              onTap: () {
                ApiService.logout(); // Método para cerrar sesión
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
