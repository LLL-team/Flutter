import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:soluva/services/api_services/mercado_pago_service.dart';
import 'dart:html' as html;

class ProfilePayments extends StatefulWidget {
  final String trabajadorId;

  const ProfilePayments({super.key, required this.trabajadorId});

  @override
  State<ProfilePayments> createState() => _ProfilePaymentsState();
}

class _ProfilePaymentsState extends State<ProfilePayments> {
  bool _isLinked = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccount();

    html.window.onFocus.listen((event) {
      _loadAccount();
    });
  }

  Future<void> _loadAccount() async {
    try {
      final isLinked = await MercadoPagoService.verifyLinkedAccount();

      setState(() {
        _isLinked = isLinked;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _connectAccount() async {
    final url = await MercadoPagoService.getMercadoPagoConnectUrl(
      widget.trabajadorId,
    );

    if (url != null) {
      html.window.open(url, '_blank');
    }
  }

  Future<void> _removeLink() async {
    await MercadoPagoService.removeMercadoPagoLink();
    await _loadAccount();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 180,
                height: 60,
                child: SvgPicture.asset(
                  'assets/images/mercadopago.svg',
                  fit: BoxFit.fitHeight,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: _isLinked ? _removeLink : _connectAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BC0C8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: Text(
                    _isLinked
                        ? 'Desvincular MercadoPago'
                        : 'Vincular MercadoPago',
                  ),
                ),
              ),
            ],
          ),

          if (_isLinked) ...[
            const SizedBox(width: 32),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SizedBox(height: 24),
                Text(
                  'Cuenta vinculada correctamente',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
