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

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    // Simulación de carga - reemplazar con llamada a API
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _notifications = [
        {
          'date': DateTime.now().subtract(const Duration(days: 5)),
          'message':
              '(Nombre trabajador) ha aceptado tu solicitud de (trabajo solicitado)',
          'type': 'accepted',
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 8)),
          'message':
              '(Nombre trabajador) ha rechazado tu solicitud de (trabajo solicitado)',
          'type': 'rejected',
        },
        {
          'date': DateTime.now().subtract(const Duration(days: 9)),
          'message':
              '(Nombre trabajador) no ha aceptado tu solicitud de (trabajo solicitado)',
          'type': 'no_response',
        },
      ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Notificaciones',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? Center(
                        child: Text(
                          'No hay notificaciones',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          return _NotificationCard(
                            notification: _notifications[index],
                          );
                        },
                      ),
          ),
        ],
      ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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