import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../screens/payment_screen.dart';

class UserAssignDialog extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback? onUpdate;
  final VoidCallback? onPaymentFinished;
  const UserAssignDialog({
    super.key,
    required this.request,
    this.onUpdate,
    this.onPaymentFinished,
  });

  @override
  Widget build(BuildContext context) {
    final workerName = request['worker_name']?.toString() ?? 'Trabajador';
    final service =
        request['service']?.toString() ??
        request['type']?.toString() ??
        'servicio';

    return Dialog(
      backgroundColor: AppColors.text,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 300),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Botón cerrar
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(height: 8),

              // Título
              Text(
                '$workerName aceptó la solicitud de\n$service',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading2.copyWith(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 24),

              // Botón Pagar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Cerrar el dialog
                    Navigator.pop(context);

                    // Ir a la pantalla de pago
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentScreen(request: request),
                      ),
                    ).then((_) {
                      // ⬅️ Esto se ejecuta SIEMPRE que vuelve del pago
                      onPaymentFinished?.call();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Pagar',
                    style: AppTextStyles.buttonText.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Texto informativo
              Text(
                '*El pago NO será entregado al trabajador hasta que ambas partes confirmen la finalización',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.blue[300],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
