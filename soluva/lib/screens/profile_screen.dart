import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:soluva/screens/edit_trade_prices_screen.dart';
import 'package:soluva/screens/edit_worker_schedule_screen.dart';
import 'package:soluva/screens/home_screen.dart';
import 'package:soluva/screens/worker_services_screen.dart';
import 'package:soluva/services/api_services/api_service.dart';

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
  Uint8List? _imageBytes; // Vista previa de imagen elegida
  String? profileImageUrl; // URL de la imagen desde el backend

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();

      setState(() {
        _imageFile = pickedFile;
        _imageBytes = bytes;
      });

      // Subir la imagen al servidor
      await ApiService.uploadProfileImage(bytes, pickedFile.name);

      // Volver a cargar los datos del usuario
      await loadUser();
    }
  }

  Future<void> loadUser() async {
    final data = await ApiService.getUserProfile();
    if (mounted) {
      setState(() {
        user = data;
        loading = false;
      });
    }
    // Si hay uuid, buscar la imagen
    if (data != null && data['uuid'] != null) {
      final fotoBytes = await ApiService.getFoto(data['uuid']);
      if (mounted) {
        setState(() {
          _imageBytes = fotoBytes;
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

    final fullName = "${user!['name'] ?? ''} ${user!['last_name'] ?? ''}".trim();
    final isWorker = user!['type'] == 'worker';
    final trade = user!['trade'] as Map<String, dynamic>? ?? {};
    final description = user!['description'] ?? user!['descripcion'];

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: _imageBytes != null
                        ? MemoryImage(_imageBytes!)
                        : (profileImageUrl != null
                                  ? NetworkImage(profileImageUrl!)
                                  : null)
                              as ImageProvider<Object>?,
                    child: (_imageBytes == null && profileImageUrl == null)
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
            const SizedBox(height: 10),
            if (description != null && description.toString().isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                description,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
            if (isWorker && trade.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text('Servicios ofrecidos:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ...trade.entries.map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: (entry.value as List<dynamic>)
                        .map((s) => Chip(label: Text(s.toString())))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                ],
              )),
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
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                // Convierte trade a Map<String, List<String>>
                final Map<String, List<String>> tradeListMap = trade.map((key, value) {
                  return MapEntry(key, List<String>.from(value as List));
                });

                final newPrices = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditTradePricesScreen(
                      trade: tradeListMap,
                      prices: {}, // Pasa los precios actuales aquí
                    ),
                  ),
                );
                // Actualiza precios en tu backend con newPrices
              },
              child: const Text('Editar precios'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final newSchedule = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkerServicesPage(uuid: user!['uuid']),
                  ),
                );
                // Actualiza horarios en tu backend con newSchedule
              },
              child: const Text('Editar horarios'),
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
                ApiService.logout();
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
