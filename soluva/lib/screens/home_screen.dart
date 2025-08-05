import 'package:flutter/material.dart';
import 'package:soluva/screens/auth_screen.dart';
import 'package:soluva/screens/profile_screen.dart';
import 'package:soluva/screens/worker_application_screen.dart';
import 'package:soluva/widgets/header_widget.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HeaderWidget(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WorkerApplicationScreen()),
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
      ),
    );
  }
}
