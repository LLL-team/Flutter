import 'package:flutter/material.dart';

class ProfilePagos extends StatelessWidget {
  const ProfilePagos({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          "Aquí irán las formas de pago.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
