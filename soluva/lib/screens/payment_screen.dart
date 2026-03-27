import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/api_services/api_service.dart';
import '../services/mercadoPago_services/MP_service.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> request;

  const PaymentScreen({super.key, required this.request});

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

  double baseCost = 0;
  double fixedCommission = 0;
  double totalCost = 0;
  bool loadingCost = true;

  List<dynamic> paymentMethods = [];
  String? selectedPaymentMethodId;
  String? selectedPaymentMethodName;
  bool isLoadingMethods = true;

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
    if (selectedPaymentMethodId == null) {
      _showErrorDialog(context, 'Seleccione un método de pago');
      return;
    }

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

    final expiryParts = expiryController.text.split('/');
    final expirationMonth = expiryParts[0].trim();
    final expirationYear = expiryParts[1].trim().length == 2
        ? '20${expiryParts[1].trim()}'
        : expiryParts[1].trim();

    // Generar card token
    final cardToken = await generarCardToken(
      cardNumber: cardNumberController.text.trim(),
      cardHolderName: cardHolderController.text.trim(),
      cardExpirationMonth: expirationMonth,
      cardExpirationYear: expirationYear,
      securityCode: cvvController.text.trim(),
      identificationType: 'DNI', // o el tipo que estés usando
      identificationNumber: documentController.text.trim(),
    );

    final result = await ApiService.processPayment(
      requestUuid: uuid,
      cardToken: cardToken,
      paymentMethodId: selectedPaymentMethodId!,
      metodoDePago: selectedPaymentMethodName ?? '',
    );

    if (!mounted) return;

    // Cerrar loading
    Navigator.pop(context);
    Navigator.pop(context);
    setState(() => isProcessing = false);

    if (result['success'] == true) {
      _showSuccessDialogAndExit(
        context,
        'Trabajo asignado',
        result['message'] ?? 'El trabajo ha sido asignado correctamente.',
      );
    } else {
      _showErrorDialog(
        context,
        result['message'] ?? 'Error al asignar el trabajo',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
    loadCostSummary();
  }

  void loadCostSummary() async {
    final uuid = widget.request['id']?.toString();
    if (uuid == null) {
      _showErrorDialog(context, 'No se pudo identificar la solicitud');
      return;
    }

    final result = await ApiService.getCostSummary(requestUuid: uuid);

    if (result['success']) {
      final data = result['data'];

      setState(() {
        baseCost = _toDouble(data['base_cost']);
        fixedCommission = _toDouble(data['fixed_commission']);
        totalCost = _toDouble(data['total_cost']);
        loadingCost = false;
      });
    } else {
      setState(() {
        loadingCost = false;
      });
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;

    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 0;
  }

  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await obtenerMetodosDePago();

      methods.sort(
        (a, b) => a['name'].toString().toLowerCase().compareTo(
          b['name'].toString().toLowerCase(),
        ),
      );

      setState(() {
        paymentMethods = methods;
        if (methods.isNotEmpty) {
          selectedPaymentMethodId = methods.first['id'];
          selectedPaymentMethodName = methods.first['name'];
        }
        isLoadingMethods = false;
      });
    } catch (e) {
      setState(() => isLoadingMethods = false);
      _showErrorDialog(context, 'Error cargando métodos de pago');
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

  @override
  Widget build(BuildContext context) {
    debugPrint("--...---");
    debugPrint(widget.request.toString());
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          final isDesktop = width > 900;
          final isTablet = width > 600;

          Widget content;

          if (isDesktop) {
            content = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildSummary(service, worker, cost)),
                const SizedBox(width: 32),
                Expanded(child: _buildPaymentForm()),
              ],
            );
          } else {
            content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSummary(service, worker, cost),
                const SizedBox(height: 32),
                _buildPaymentForm(),
              ],
            );
          }

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(key: _formKey, child: content),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// ---------------- LEFT ----------------
  Widget _buildSummary(String service, String worker, String cost) {
    final workerData = widget.request['worker'];
    final workerUser = workerData?['user'];

    final description = workerData?['description'] ?? '';
    final email = workerUser?['email'];
    final date = widget.request['scheduled_date'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _infoCard(
          title: 'Servicio',
          icon: Icons.build,
          children: [
            _infoRow(service, bold: true),
            if (date != null)
              _infoRow('Fecha: ${date.toString().split('T').first}'),
            _infoRow('Estado: Aceptado'),
          ],
        ),

        const SizedBox(height: 16),

        _infoCard(
          title: 'Prestador',
          icon: Icons.person,
          children: [
            _infoRow(worker, bold: true),
            if (description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  description,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ),
            if (email != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _infoRow(email, icon: Icons.email),
              ),
          ],
        ),

        const SizedBox(height: 16),

        _infoCard(
          title: 'Resumen del pago',
          icon: Icons.payments,
          children: [
            if (loadingCost)
              const CircularProgressIndicator()
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Costo del servicio'),
                  Text('\$$baseCost'),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Comisión de Soluva'),
                  Text('\$$fixedCommission'),
                ],
              ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${totalCost.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'El monto se cobrará al confirmar',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String text, {bool bold = false, IconData? icon}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 6),
        ],
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  /// ---------------- RIGHT ----------------
  Widget _buildPaymentForm() {
    return Column(
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

        const SizedBox(height: 16),

        if (isLoadingMethods)
          const Center(child: CircularProgressIndicator())
        else
          DropdownButtonFormField<String>(
            value: selectedPaymentMethodId,
            decoration: const InputDecoration(
              labelText: 'Método de pago',
              border: OutlineInputBorder(),
            ),
            items: paymentMethods.map<DropdownMenuItem<String>>((method) {
              return DropdownMenuItem<String>(
                value: method['id'],
                child: Text(method['name']),
              );
            }).toList(),
            onChanged: (value) {
              final method = paymentMethods.firstWhere((m) => m['id'] == value);
              setState(() {
                selectedPaymentMethodId = value;
                selectedPaymentMethodName = method['name'];
              });
            },
            validator: (value) =>
                value == null ? 'Seleccione un método de pago' : null,
          ),

        const SizedBox(height: 24),

        const Text(
          'Datos de facturación',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _input(documentController, 'Documento'),
        const SizedBox(height: 12),

        _input(emailController, 'Email', keyboard: TextInputType.emailAddress),
        const SizedBox(height: 12),

        _input(addressController, 'Dirección'),
        const SizedBox(height: 12),

        _input(
          postalCodeController,
          'Código postal',
          keyboard: TextInputType.number,
        ),

        const SizedBox(height: 32),

        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 280,
                child: ElevatedButton(
                  onPressed: isProcessing
                      ? null
                      : () => _confirmPaymentAndAssign(),
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
            ],
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
