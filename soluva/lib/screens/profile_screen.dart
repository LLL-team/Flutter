import 'package:flutter/material.dart';
import 'package:soluva/screens/home_screen.dart';
import 'package:soluva/services/api_services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  bool loading = true;

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
            const CircleAvatar(
              radius: 60,
              backgroundImage: NetworkImage('https://i.pravatar.cc/300'),
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
