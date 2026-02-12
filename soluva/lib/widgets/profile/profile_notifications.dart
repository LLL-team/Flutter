import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:soluva/services/api_services/api_service.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:soluva/widgets/dialogs/new_request_dialog.dart';
import 'package:soluva/widgets/dialogs/request_detail_dialog.dart';
import 'package:soluva/widgets/dialogs/user_assign_dialog.dart';
import 'package:intl/intl.dart';

class ProfileNotifications extends StatefulWidget {
  final bool viewingAsWorker;

  const ProfileNotifications({super.key, this.viewingAsWorker = false});

  @override
  State<ProfileNotifications> createState() => _ProfileNotificationsState();
}

class _ProfileNotificationsState extends State<ProfileNotifications> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // Future<void> _loadNotifications() async {
  //   setState(() => _loading = true);
  //   // Simulación de carga - reemplazar con llamada a API
  //   await Future.delayed(const Duration(seconds: 1));
  //   setState(() {
  //     _notifications = [
  //       {
  //         'date': DateTime.now().subtract(const Duration(days: 5)),
  //         'message':
  //             '(Nombre trabajador) ha aceptado tu solicitud de (trabajo solicitado)',
  //         'type': 'accepted',
  //       },
  //       {
  //         'date': DateTime.now().subtract(const Duration(days: 8)),
  //         'message':
  //             '(Nombre trabajador) ha rechazado tu solicitud de (trabajo solicitado)',
  //         'type': 'rejected',
  //       },
  //       {
  //         'date': DateTime.now().subtract(const Duration(days: 9)),
  //         'message':
  //             '(Nombre trabajador) no ha aceptado tu solicitud de (trabajo solicitado)',
  //         'type': 'no_response',
  //       },
  //     ];
  //     _loading = false;
  //   });
  // }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);

    await Future.delayed(const Duration(seconds: 1));

    final notifs = await ApiService.getNotifications();

    setState(() {
      _notifications = notifs.map((n) {
        // Extraer request_uuid del campo data si existe
        String? requestId;
        if (n['data'] != null) {
          try {
            final dataObj = n['data'] is String
                ? jsonDecode(n['data'])
                : n['data'];
            requestId = dataObj['request_uuid']?.toString();
          } catch (e) {
            print('Error parsing notification data: $e');
          }
        }

        return {
          'date': DateTime.parse(n['date']),
          'message': n['body'],
          'type': n['type'],
          'request_id': requestId,
        };
      }).toList();

      _loading = false;
    });
  }

  Future<void> _openRequestPopup(String? requestId) async {
    if (requestId == null) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final request = await ApiService.getRequestById(requestId);

      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading

      if (request != null) {
        _showRequestDialog(request);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo cargar la solicitud'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showRequestDialog(Map<String, dynamic> request) {
    final status = request['status']?.toString().toLowerCase() ?? 'pending';

    // Si es usuario (no trabajador) y el estado es 'pending', no hacer nada o mostrar info
    if (!widget.viewingAsWorker && status == 'pending') {
      // Usuario viendo solicitud pendiente - puede cancelar pero no desde notificaciones
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta solicitud está pendiente de confirmación'),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    // Si es usuario y el estado es 'accepted', mostrar diálogo de asignación/pago
    if (!widget.viewingAsWorker && status == 'accepted') {
      showDialog(
        context: context,
        builder: (context) =>
            UserAssignDialog(request: request, onUpdate: _loadNotifications),
      );
      return;
    }

    // Para trabajadores: mostrar el popup correspondiente según el estado
    if (widget.viewingAsWorker && status == 'pending') {
      // Nueva solicitud (sin aceptar) - mostrar para aceptar/rechazar
      showDialog(
        context: context,
        builder: (context) =>
            NewRequestDialog(request: request, onUpdate: _loadNotifications),
      );
    } else if (widget.viewingAsWorker) {
      // Solicitud aceptada, en progreso o completada - mostrar detalles
      showDialog(
        context: context,
        builder: (context) =>
            RequestDetailDialog(request: request, onUpdate: _loadNotifications),
      );
    } else {
      // Usuario viendo otros estados - mostrar detalles
      showDialog(
        context: context,
        builder: (context) =>
            RequestDetailDialog(request: request, onUpdate: _loadNotifications),
      );
    }
  }
  /*
  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    // Simulación de carga - reemplazar con llamada a API
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
     _notifications = [
        {
          'date': DateTime.now().subtract(const Duration(hours: 2)),
          'message':
              'Carlos López ha aceptado tu solicitud de limpieza general.',
          'type': 'accepted',
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 1, hours: 3)),
          'message': 'Ana Torres ha rechazado tu solicitud de plomería.',
          'type': 'rejected',
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 2, hours: 5)),
          'message': 'Javier Pérez no respondió a tu solicitud de jardinería.',
          'type': 'no_response',
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 3)),
          'message': 'Tu solicitud de mantenimiento eléctrico fue completada.',
          'type': 'accepted',
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 4)),
          'message': 'Tu pago por el servicio de limpieza fue confirmado.',
          'type': 'accepted',
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 6)),
          'message': 'María González ha rechazado tu solicitud de pintura.',
          'type': 'rejected',
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 8)),
          'message':
              'El trabajador Pablo Díaz no aceptó tu solicitud de gasista.',
          'type': 'no_response',
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 10)),
          'message': 'Tu solicitud de jardinería fue completada con éxito.',
          'type': 'accepted',
        },
      ];
    
      _loading = false;
    });
  }*/

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Text(
          'No hay notificaciones',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _NotificationCard(
          notification: notification,
          onTap: notification['request_id'] != null
              ? () => _openRequestPopup(notification['request_id'])
              : null,
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback? onTap;

  const _NotificationCard({required this.notification, this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = notification['date'] as DateTime;
    final message = notification['message'] as String;
    final type = notification['type'] as String;
    final hasRequest = notification['request_id'] != null;

    IconData icon;
    Color iconColor;

    switch (type) {
      case 'accepted':
        icon = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'rejected':
        icon = Icons.cancel;
        iconColor = Colors.red;
        break;
      case 'no_response':
        icon = Icons.access_time;
        iconColor = Colors.orange;
        break;
      case 'new_request':
      case 'pending':
        icon = Icons.work;
        iconColor = AppColors.secondary;
        break;
      default:
        icon = Icons.notifications;
        iconColor = AppColors.secondary;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(date),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.text,
                      ),
                    ),
                    // Mostrar indicador si se puede ver más detalles
                    if (hasRequest) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 14,
                            color: AppColors.secondary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Toca para ver detalles',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary.withValues(alpha: 0.7),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Flecha indicando que es clickeable
              if (hasRequest)
                Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy - HH:mm').format(date);
  }
}
