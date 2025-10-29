import 'package:flutter/material.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:intl/intl.dart';

class ProfileNotifications extends StatefulWidget {
  const ProfileNotifications({super.key});

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
  // Simulación de carga - reemplazar con llamada a API
  await Future.delayed(const Duration(seconds: 1));
  setState(() {
    _notifications = [
      {
        'date': DateTime.now().subtract(const Duration(hours: 2)),
        'message': 'Carlos López ha aceptado tu solicitud de limpieza general.',
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
        'message': 'El trabajador Pablo Díaz no aceptó tu solicitud de gasista.',
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
}

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
        return _NotificationCard(
          notification: _notifications[index],
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;

  const _NotificationCard({required this.notification});

  @override
  Widget build(BuildContext context) {
    final date = notification['date'] as DateTime;
    final message = notification['message'] as String;
    final type = notification['type'] as String;

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
      default:
        icon = Icons.notifications;
        iconColor = AppColors.secondary;
    }

    return Container(
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy - HH:mm').format(date);
  }
}