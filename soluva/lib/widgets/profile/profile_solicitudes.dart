import 'package:flutter/material.dart';

class ProfileSolicitudes extends StatelessWidget {
  const ProfileSolicitudes({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(62),
        child: Text(
          "Aquí irán las solicitudes.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
