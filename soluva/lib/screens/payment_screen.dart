import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../services/api_services/request_service.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> request;
  final VoidCallback onPaymentSuccess;

  const PaymentScreen({
    super.key,
    required this.request,
    required this.onPaymentSuccess,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isProcessing = false;

  final cardHolderController = TextEditingController();
  final cardNumberController = TextEditingController();
  final expiryController = TextEditingController();
  final cvvController = TextEditingController();
  final documentController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final postalCodeController = TextEditingController();

  @override
  void dispose() {
    cardHolderController.dispose();
    cardNumberController.dispose();
    expiryController.dispose();
    cvvController.dispose();
    documentController.dispose();
    emailController.dispose();
    addressController.dispose();
    postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _confirmPaymentAndAssign() async {
    if (!_formKey.currentState!.validate()) return;

    final uuid = widget.request['id']?.toString();
    if (uuid == null) {
      _showErrorDialog(context, 'No se pudo identificar la solicitud');
      return;
    }

    setState(() => isProcessing = true);

    // Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await RequestService.changeStatus(
      uuid: uuid,
      status: 'assigned',
    );

    if (!mounted) return;

    // Cerrar loading
    Navigator.pop(context);
    setState(() => isProcessing = false);

    if (result['success'] == true) {
      _showSuccessDialogAndExit(
        context,
        'Trabajo asignado',
        result['message'] ?? 'El trabajo ha sido asignado correctamente.',
      );

      widget.onPaymentSuccess();
    } else {
      _showErrorDialog(
        context,
        result['message'] ?? 'Error al asignar el trabajo',
      );
    }
  }

  void _showSuccessDialogAndExit(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // cerrar dialog
              Navigator.pop(context); // salir de PaymentScreen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.request['service'] ?? 'Servicio';
    final cost = widget.request['cost']?.toString() ?? '0';
    final worker = widget.request['worker_name'] ?? 'Trabajador';

    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pago'),
        backgroundColor: AppColors.text,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildSummary(service, worker, cost)),
                    const SizedBox(width: 32),
                    Expanded(child: _buildPaymentForm()),
                  ],
                )
              : Column(
                  children: [
                    _buildSummary(service, worker, cost),
                    const SizedBox(height: 32),
                    _buildPaymentForm(),
                  ],
                ),
        ),
      ),
    );
  }

  /// ---------------- LEFT ----------------
  Widget _buildSummary(String service, String worker, String cost) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          service,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('Prestador: $worker'),
        const SizedBox(height: 24),
        Text('Monto a pagar', style: TextStyle(color: Colors.grey[600])),
        const SizedBox(height: 8),
        Text(
          '\$$cost',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// ---------------- RIGHT ----------------
  Widget _buildPaymentForm() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Datos de pago',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _input(cardHolderController, 'Nombre del titular'),
                const SizedBox(height: 12),

                _input(
                  cardNumberController,
                  'Número de tarjeta',
                  keyboard: TextInputType.number,
                  minLength: 16,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _input(
                        expiryController,
                        'MM/AA',
                        keyboard: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _input(
                        cvvController,
                        'CVV',
                        keyboard: TextInputType.number,
                        minLength: 3,
                        obscure: true,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                const Text(
                  'Datos de facturación',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                _input(documentController, 'Documento'),
                const SizedBox(height: 12),

                _input(
                  emailController,
                  'Email',
                  keyboard: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),

                _input(addressController, 'Dirección'),
                const SizedBox(height: 12),

                _input(
                  postalCodeController,
                  'Código postal',
                  keyboard: TextInputType.number,
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),

        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            width: 280,
            child: ElevatedButton(
              onPressed: isProcessing ? null : () => _confirmPaymentAndAssign(),

              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Confirmar pago',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// ---------------- INPUT GENERICO ----------------
  Widget _input(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
    int minLength = 1,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) =>
          value == null || value.length < minLength ? 'Campo inválido' : null,
    );
  }
}
