import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/api_services/request_service.dart';
import '../../screens/payment_screen.dart';

class UserAssignDialog extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback? onUpdate;

  const UserAssignDialog({super.key, required this.request, this.onUpdate});

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
                        builder: (_) => PaymentScreen(
                          request: request,
                          onPaymentSuccess: () async {
                            await _confirmAssign(context);
                          },
                        ),
                      ),
                    );
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

  Future<void> _confirmAssign(BuildContext context) async {
    final uuid = request['id']?.toString();
    if (uuid == null) {
      _showErrorDialog(context, 'No se pudo identificar la solicitud');
      return;
    }

    // Cerrar el diálogo principal
    Navigator.pop(context);

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final result = await RequestService.changeStatus(
      uuid: uuid,
      status: 'assigned',
    );

    // Cerrar indicador de carga
    if (context.mounted) Navigator.pop(context);

    if (result['success'] == true) {
      if (context.mounted) {
        _showSuccessDialog(
          context,
          'Trabajo asignado',
          result['message'] ?? 'El trabajo ha sido asignado correctamente.',
        );
      }
      // Actualizar la lista
      onUpdate?.call();
    } else {
      if (context.mounted) {
        _showErrorDialog(
          context,
          result['message'] ?? 'Error al asignar el trabajo',
        );
      }
    }
  }

  void _showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(title, style: AppTextStyles.heading2),
        content: Text(message, style: AppTextStyles.bodyText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          'Error',
          style: AppTextStyles.heading2.copyWith(color: AppColors.secondary),
        ),
        content: Text(message, style: AppTextStyles.bodyText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: AppTextStyles.buttonText.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
