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

  Future<void> _confirmRemoveLink() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Desvincular cuenta'),
          content: const Text(
            '¿Está seguro que desea desvincular su cuenta de MercadoPago?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Desvincular'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _removeLink();
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
    // Confirmación antes de desvincular
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desvincular MercadoPago'),
        content: const Text(
          '¿Estás seguro de que querés desvincular tu cuenta de MercadoPago?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sí, desvincular',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await MercadoPagoService.removeMercadoPagoLink();

    if (result['success'] == true) {
      await _loadAccount();
    } else if (result['has_pending_job'] == true) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('No se puede desvincular'),
            content: const Text(
              'Para desvincular MercadoPago primero tenés que finalizar el trabajo que aceptaste o cancelarlo.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al desvincular'),
          ),
        );
      }
    }
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
                  onPressed: _isLinked ? _confirmRemoveLink : _connectAccount,
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
