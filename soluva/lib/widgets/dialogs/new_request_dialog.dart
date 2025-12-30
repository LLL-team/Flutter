import 'package:flutter/material.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:soluva/theme/app_text_styles.dart';
import 'package:soluva/services/api_services/request_service.dart';

class NewRequestDialog extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback? onUpdate;

  const NewRequestDialog({
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

    // Datos de precio
    final amount = request['amount'] ?? request['cost'] ?? 0;
    final price = amount is String ? (double.tryParse(amount) ?? 0) : (amount as num).toDouble();
    final commission = price * 0.15; // 15% de comisión
    final total = price - commission;

    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
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
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
            const SizedBox(height: 8),

            // Título
            Text(
              '¡Nueva solicitud\nde trabajo!',
              textAlign: TextAlign.center,
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.secondary,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),

            // Icono y título del servicio
            Row(
              children: [
                // Icono del servicio
                Container(
                  width: 60,
                  height: 60,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _getCategoryImage(service),
                ),
                const SizedBox(width: 12),

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
            const SizedBox(height: 16),

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

            // Detalles de precio
            _buildPriceDetails(),
            const SizedBox(height: 16),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptRequest(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Aceptar trabajo',
                      style: AppTextStyles.buttonText.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rejectRequest(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.text,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Rechazar trabajo',
                      style: AppTextStyles.buttonText.copyWith(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceDetails() {
    // Usar los datos extraídos de la API en el build principal
    final amount = request['amount'] ?? request['cost'] ?? 0;
    final price = amount is String ? (double.tryParse(amount) ?? 0) : (amount as num).toDouble();
    final commission = price * 0.15; // 15% de comisión
    final total = price - commission;

    return Column(
      children: [
        _buildPriceRow('\$${_formatPrice(price)} ..... Valor', AppColors.text),
        const SizedBox(height: 8),
        _buildPriceRow('-\$${_formatPrice(commission)} ..... Comisión', AppColors.text),
        const SizedBox(height: 8),
        Divider(color: AppColors.textSecondary, thickness: 1),
        const SizedBox(height: 8),
        _buildPriceRow(
          '\$${_formatPrice(total)} ..... Total a recibir',
          AppColors.secondary,
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildPriceRow(String text, Color color, {bool isBold = false}) {
    return Text(
      text,
      style: (isBold ? AppTextStyles.subtitle : AppTextStyles.bodyText).copyWith(
        color: color,
        fontSize: isBold ? 16 : 14,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  String _formatPrice(num price) {
    return price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  Widget _getCategoryImage(String? category) {
    String imagePath;

    switch (category?.toLowerCase()) {
      case 'electricidad':
        imagePath = 'assets/icons/servicios/Boton-I.Electricidad.png';
        break;
      case 'plomería':
      case 'plomeria':
        imagePath = 'assets/icons/servicios/Boton-I.Plomeria.png';
        break;
      case 'limpieza':
        imagePath = 'assets/icons/servicios/Boton-I.Limpieza.png';
        break;
      case 'jardinería':
      case 'jardineria':
        imagePath = 'assets/icons/servicios/Boton-I.Jardineria.png';
        break;
      case 'aire acondicionado':
      case 'aire':
        imagePath = 'assets/icons/servicios/Boton-I.Aire.png';
        break;
      case 'gas':
        imagePath = 'assets/icons/servicios/Boton-I.Gas.png';
        break;
      case 'carpintería':
      case 'carpinteria':
        imagePath = 'assets/icons/servicios/Boton-I.Carpinteria.png';
        break;
      case 'pintura':
        imagePath = 'assets/icons/servicios/Boton-I.Pintura.png';
        break;
      case 'albañilería':
      case 'albanileria':
        imagePath = 'assets/icons/servicios/Boton-I.Albanileria.png';
        break;
      case 'cerrajería':
      case 'cerrajeria':
        imagePath = 'assets/icons/servicios/Boton-I.Cerrajeria.png';
        break;
      case 'herrería':
      case 'herreria':
        imagePath = 'assets/icons/servicios/Boton-I.Herreria.png';
        break;
      case 'durlock':
        imagePath = 'assets/icons/servicios/Boton-I.Durlock.png';
        break;
      case 'flete':
        imagePath = 'assets/icons/servicios/Boton-I.Flete.png';
        break;
      default:
        imagePath = 'assets/icons/servicios/Boton-I.Service.png';
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

  void _acceptRequest(BuildContext context) async {
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

    final result = await RequestService.changeStatus(uuid: uuid, status: 'accepted');

    // Cerrar indicador de carga
    if (context.mounted) Navigator.pop(context);

    if (result['success'] == true) {
      if (context.mounted) {
        _showSuccessDialog(context, 'Trabajo aceptado', result['message'] ?? 'Has aceptado esta solicitud de trabajo.');
      }
    } else {
      if (context.mounted) {
        _showErrorDialog(context, result['message'] ?? 'Error al aceptar la solicitud');
      }
    }
  }

  void _rejectRequest(BuildContext context) async {
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
        title: Text('Rechazar trabajo', style: AppTextStyles.heading2),
        content: Text('¿Estás seguro que deseas rechazar esta solicitud?', style: AppTextStyles.bodyText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: AppTextStyles.buttonText.copyWith(color: AppColors.textSecondary)),
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

    // Cerrar indicador de carga
    if (context.mounted) Navigator.pop(context);

    if (result['success'] == true) {
      if (context.mounted) {
        _showSuccessDialog(context, 'Trabajo rechazado', result['message'] ?? 'Has rechazado esta solicitud.');
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
