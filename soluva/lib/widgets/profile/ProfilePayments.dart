import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:soluva/services/api_services/MercadoPagoService.dart';

class ProfilePayments extends StatefulWidget {
  final String trabajadorId;

  const ProfilePayments({super.key, required this.trabajadorId});

  @override
  State<ProfilePayments> createState() => _ProfilePaymentsState();
}

class _ProfilePaymentsState extends State<ProfilePayments> {
  MercadoPagoAccount? _account;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  Future<void> _loadAccount() async {
    final accountMap = await MercadoPagoService.verifyLinkedAccount();

    setState(() {
      if (accountMap != null) {
        _account = MercadoPagoAccount.fromJson(accountMap);
      } else {
        _account = null;
      }

      _isLoading = false;
    });
  }

  Future<void> _connectAccount() async {
    final url = await MercadoPagoService.getMercadoPagoConnectUrl(
      widget.trabajadorId,
    );

    // Abrir navegador externo
    // Web:
    // html.window.location.href = url;

    // Mobile:
    // usar url_launcher
  }

  Future<void> _removeLink() async {
    await MercadoPagoService.removeMercadoPagoLink();
    setState(() {
      _account = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_account != null) {
      return _linkedContent(context, _account!);
    }

    return _linkButton(context);
  }

  Widget _linkedContent(BuildContext context, MercadoPagoAccount data) {
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
                child: SvgPicture.asset(
                  'assets/images/mercadopago.svg',
                  allowDrawingOutsideViewBox: true,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 180,
                child: ElevatedButton(
                  onPressed: _removeLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5BC0C8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text('Unlink'),
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Account: ${data.name}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'CVU: ${data.cvu}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linkButton(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: _connectAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5BC0C8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        ),
        child: const Text('Link MercadoPago'),
      ),
    );
  }
}

class MercadoPagoAccount {
  final String name;
  final String cvu;

  MercadoPagoAccount({required this.name, required this.cvu});

  factory MercadoPagoAccount.fromJson(Map<String, dynamic> json) {
    return MercadoPagoAccount(name: json['name'], cvu: json['cvu']);
  }
}
