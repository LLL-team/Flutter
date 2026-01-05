import 'package:flutter/material.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:soluva/theme/app_text_styles.dart';
import 'package:soluva/services/api_services/request_service.dart';

class RequestDetailDialog extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback? onUpdate;

  const RequestDetailDialog({
    super.key,
    required this.request,
    this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    // Extraer datos de la API
    final service = request['service'] ?? request['type'] ?? 'Servicio';
    final date = request['date'] ?? request['scheduled_date'] ?? '';
    final time = request['time'] ?? request['scheduled_time'] ?? '09:00';

    // Datos del cliente
    final client = request['client'] ?? request['user'];
    final clientName = client != null
        ? '${client['name'] ?? ''} ${client['last_name'] ?? ''}'.trim()
        : request['client_name'] ?? request['user_name'] ?? 'Cliente';

    final address = request['address'] ?? request['location'] ?? 'Dirección no especificada';

    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 550,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // Botón cerrar
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(height: 8),

            // Icono y título del servicio
            Row(
              children: [
                // Icono del servicio
                SizedBox(
                  width: 80,
                  height: 80,
                  child: _getCategoryImage(service),
                ),
                const SizedBox(width: 16),

                // Servicio
                Expanded(
                  child: Text(
                    service,
                    style: AppTextStyles.subtitle.copyWith(
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fecha, hora y ubicación
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.button,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fecha
                  Column(
                    children: [
                      Text(
                        _getWeekday(date),
                        style: AppTextStyles.bodyText.copyWith(
                          color: AppColors.white,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _getDay(date),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Hora
                  Text(
                    time,
                    style: AppTextStyles.heading2.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Nombre del cliente y dirección
            Column(
              children: [
                Text(
                  clientName,
                  style: AppTextStyles.subtitle.copyWith(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: AppTextStyles.bodyText.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Botones de acción
            _buildActionButtons(context),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final status = request['status'] ?? 'pending';

    if (status == 'completed') {
      return Column(
        children: [
          _buildActionButton(
            'Trabajo finalizado',
            AppColors.text,
            () {
              // Acción para trabajo finalizado
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Agregar costo extra',
            AppColors.text,
            () {
              Navigator.pop(context);
              _showAddExtraCostDialog(context);
            },
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Cancelar solicitud',
            AppColors.secondary,
            () => _confirmCancelRequest(context),
          ),
        ],
      );
    } else if (status == 'accepted') {
      return Column(
        children: [
          Text(
            'Esperando que el cliente deposite el pago para garantizar el cobro de su trabajo.',
            style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else if (status == 'assigned') {
      return Column(
        children: [
          _buildActionButton(
            'Finalizar trabajo',
            AppColors.button,
            () => _confirmCompleteWork(context),
          ),
        ],
      );
    } else if (status == 'worker_completed' || status == 'provider_completed') {
      // Trabajador ya confirmó, esperando confirmación del cliente
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Esperando confirmación del cliente.\n\nCuando el cliente confirme o pasen 6 días se le enviará su dinero.',
              style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    } else if (status == 'user_completed') {
      // Usuario ya confirmó, trabajador debe confirmar también
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'El cliente confirmó que el trabajo está finalizado',
              style: AppTextStyles.bodyText.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
          _buildActionButton(
            'Sí, ya está finalizado',
            AppColors.button,
            () => _confirmCompleteWork(context),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'No, todavía no',
            AppColors.secondary,
            () => Navigator.pop(context),
          ),
        ],
      );
    } else {
      // Estado pendiente
      return Column(
        children: [
          _buildActionButton(
            'Aceptar solicitud',
            AppColors.button,
            () => _confirmAcceptRequest(context),
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            'Rechazar solicitud',
            AppColors.secondary,
            () => _confirmRejectRequest(context),
          ),
        ],
      );
    }
  }

  Widget _buildActionButton(String text, Color textColor, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(
          text,
          style: AppTextStyles.buttonText.copyWith(
            color: textColor,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  Widget _getCategoryImage(String? category) {
    String imagePath;

    switch (category?.toLowerCase()) {
      case 'electricidad':
        imagePath = 'icons/servicios/Boton-I.Electricidad.png';
        break;
      case 'plomería':
      case 'plomeria':
        imagePath = 'icons/servicios/Boton-I.Plomeria.png';
        break;
      case 'limpieza':
        imagePath = 'icons/servicios/Boton-I.Limpieza.png';
        break;
      case 'jardinería':
      case 'jardineria':
        imagePath = 'icons/servicios/Boton-I.Jardineria.png';
        break;
      case 'aire acondicionado':
      case 'aire':
        imagePath = 'icons/servicios/Boton-I.Aire.png';
        break;
      case 'gas':
        imagePath = 'icons/servicios/Boton-I.Gas.png';
        break;
      case 'carpintería':
      case 'carpinteria':
        imagePath = 'icons/servicios/Boton-I.Carpinteria.png';
        break;
      case 'pintura':
        imagePath = 'icons/servicios/Boton-I.Pintura.png';
        break;
      case 'albañilería':
      case 'albanileria':
        imagePath = 'icons/servicios/Boton-I.Albanileria.png';
        break;
      case 'cerrajería':
      case 'cerrajeria':
        imagePath = 'icons/servicios/Boton-I.Cerrajeria.png';
        break;
      case 'herrería':
      case 'herreria':
        imagePath = 'icons/servicios/Boton-I.Herreria.png';
        break;
      case 'durlock':
        imagePath = 'icons/servicios/Boton-I.Durlock.png';
        break;
      case 'flete':
        imagePath = 'icons/servicios/Boton-I.Flete.png';
        break;
      default:
        imagePath = 'icons/servicios/Boton-I.Service.png';
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.build, color: AppColors.secondary, size: 32);
      },
    );
  }

  String _getWeekday(dynamic date) {
    if (date == null) return 'Mañana';
    try {
      final DateTime parsedDate = DateTime.parse(date.toString());
      const weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
      return weekdays[parsedDate.weekday - 1];
    } catch (e) {
      return 'Mañana';
    }
  }

  String _getDay(dynamic date) {
    if (date == null) return '18 Dic';
    try {
      final DateTime parsedDate = DateTime.parse(date.toString());
      const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
                      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${parsedDate.day} ${months[parsedDate.month - 1]}';
    } catch (e) {
      return '18 Dic';
    }
  }

  void _showAddExtraCostDialog(BuildContext context) {
    // Implementar diálogo para agregar costo extra
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar costo extra'),
        content: const Text('Funcionalidad pendiente'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelRequest(BuildContext context) async {
    final uuid = request['id']?.toString();
    if (uuid == null) {
      _showErrorDialog(context, 'No se pudo identificar la solicitud');
      return;
    }

    // Cerrar el diálogo principal
    Navigator.pop(context);

    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('Cancelar solicitud', style: AppTextStyles.heading2),
        content: Text('¿Estás seguro que deseas cancelar esta solicitud?', style: AppTextStyles.bodyText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: AppTextStyles.buttonText.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí, cancelar', style: AppTextStyles.buttonText.copyWith(color: AppColors.secondary)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mostrar indicador de carga
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    final result = await RequestService.changeStatus(uuid: uuid, status: 'cancelled');

    if (context.mounted) Navigator.pop(context);

    if (result['success'] == true) {
      if (context.mounted) {
        _showSuccessDialog(context, 'Solicitud cancelada', result['message'] ?? 'La solicitud ha sido cancelada.');
      }
    } else {
      if (context.mounted) {
        _showErrorDialog(context, result['message'] ?? 'Error al cancelar la solicitud');
      }
    }
  }

  Future<void> _confirmCompleteWork(BuildContext context) async{
    final uuid = request['id']?.toString();
    if (uuid == null) {
      _showErrorDialog(context, 'No se pudo identificar la solicitud');
      return;
    }

    // Cerrar el diálogo principal
    Navigator.pop(context);

    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('Finalizar trabajo', style: AppTextStyles.heading2),
        content: Text('¿Confirmas que el trabajo ha sido completado?', style: AppTextStyles.bodyText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: AppTextStyles.buttonText.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí, finalizar', style: AppTextStyles.buttonText.copyWith(color: AppColors.secondary)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mostrar indicador de carga
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    final result = await RequestService.changeStatus(uuid: uuid, status: 'completed');

    if (context.mounted) Navigator.pop(context);

    if (result['success'] == true) {
      if (context.mounted) {
        _showSuccessDialog(context, 'Trabajo finalizado', result['message'] ?? 'El trabajo ha sido marcado como completado.');
      }
    } else {
      if (context.mounted) {
        _showErrorDialog(context, result['message'] ?? 'Error al finalizar el trabajo');
      }
    }
  }

  Future<void> _confirmAcceptRequest(BuildContext context) async {
    final uuid = request['id']?.toString();
    if (uuid == null) {
      _showErrorDialog(context, 'No se pudo identificar la solicitud');
      return;
    }

    // Cerrar el diálogo principal
    Navigator.pop(context);

    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('Aceptar solicitud', style: AppTextStyles.heading2),
        content: Text('¿Deseas aceptar esta solicitud?', style: AppTextStyles.bodyText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: AppTextStyles.buttonText.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí, aceptar', style: AppTextStyles.buttonText.copyWith(color: AppColors.secondary)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mostrar indicador de carga
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    final result = await RequestService.changeStatus(uuid: uuid, status: 'accepted');

    if (context.mounted) Navigator.pop(context);

    if (result['success'] == true) {
      if (context.mounted) {
        _showSuccessDialog(context, 'Solicitud aceptada', result['message'] ?? 'Has aceptado esta solicitud.');
      }
    } else {
      if (context.mounted) {
        _showErrorDialog(context, result['message'] ?? 'Error al aceptar la solicitud');
      }
    }
  }

  Future<void> _confirmRejectRequest(BuildContext context) async {
    final uuid = request['id']?.toString();
    if (uuid == null) {
      _showErrorDialog(context, 'No se pudo identificar la solicitud');
      return;
    }

    // Cerrar el diálogo principal
    Navigator.pop(context);

    // Mostrar diálogo de confirmación
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text('Rechazar solicitud', style: AppTextStyles.heading2),
        content: Text('¿Estás seguro que deseas rechazar esta solicitud?', style: AppTextStyles.bodyText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No', style: AppTextStyles.buttonText.copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sí, rechazar', style: AppTextStyles.buttonText.copyWith(color: AppColors.secondary)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Mostrar indicador de carga
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    final result = await RequestService.changeStatus(uuid: uuid, status: 'rejected');

    if (context.mounted) Navigator.pop(context);

    if (result['success'] == true) {
      if (context.mounted) {
        _showSuccessDialog(context, 'Solicitud rechazada', result['message'] ?? 'Has rechazado esta solicitud.');
      }
    } else {
      if (context.mounted) {
        _showErrorDialog(context, result['message'] ?? 'Error al rechazar la solicitud');
      }
    }
  }

  void _showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(title, style: AppTextStyles.heading2.copyWith(color: AppColors.secondary)),
        content: Text(message, style: AppTextStyles.bodyText),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onUpdate?.call();
            },
            child: Text('OK', style: AppTextStyles.buttonText.copyWith(color: AppColors.button)),
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
        title: Text('Error', style: AppTextStyles.heading2.copyWith(color: AppColors.error)),
        content: Text(message, style: AppTextStyles.bodyText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar', style: AppTextStyles.buttonText.copyWith(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
