import 'package:flutter/material.dart';

class ProfileInscripcion extends StatelessWidget {
  const ProfileInscripcion({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          "Formulario de inscripción como trabajador.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
