import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfilePagos extends StatelessWidget {
  const ProfilePagos({super.key});

  final bool isLinked = true;

  @override
  Widget build(BuildContext context) {
    final data = loadMercadoPagoData();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: isLinked ? _linkedContent(context, data) : _linkButton(context),
    );
  }

  MercadoPagoData loadMercadoPagoData() {
    // MOCK – luego reemplazar por API
    return MercadoPagoData(nombre: 'María Lopez', cvu: '9898150541814054154');
  }

  Widget _linkedContent(BuildContext context, MercadoPagoData data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo MercadoPago
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 180,
              child: SvgPicture.asset(
                'assets/images/mercadopago.svg',
                width: 240.0,
                allowDrawingOutsideViewBox: true,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5BC0C8),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  elevation: 0,
                ),
                child: const Text('Desvincular'),
              ),
            ),
          ],
        ),

        const SizedBox(width: 32),

        // Datos cuenta
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Text(
              'Cuenta: ${data.nombre}',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              'CVU: ${data.cvu}',
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }

  Widget _linkButton(BuildContext context) {
    //No hace nada aun
    return Center(
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5BC0C8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          elevation: 0,
        ),
        child: const Text('Vincular MercadoPago'),
      ),
    );
  }
}

class MercadoPagoData {
  final String nombre;
  final String cvu;

  MercadoPagoData({required this.nombre, required this.cvu});
}
