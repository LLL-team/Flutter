import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soluva/screens/profile_screen.dart';
import 'package:soluva/screens/worker_application_screen.dart';
import 'package:soluva/widgets/header_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return token != null && token.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderWidget(),
      body: FutureBuilder<bool>(
        future: isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final loggedIn = snapshot.data ?? false;

          if (!loggedIn) {
            return const Center(child: Text('Por favor, iniciá sesión.'));
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WorkerApplicationScreen(),
                      ),
                    );
                  },
                  child: const Text('Quiero trabajar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                  child: const Text('Perfil'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
