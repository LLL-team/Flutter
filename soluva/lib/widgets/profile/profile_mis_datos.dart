import 'package:flutter/material.dart';

class ProfileMisDatos extends StatelessWidget {
  const ProfileMisDatos({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          "Aquí irán los datos del usuario para editar.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
