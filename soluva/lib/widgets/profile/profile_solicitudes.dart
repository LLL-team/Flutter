import 'package:flutter/material.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:soluva/services/api_services/api_service.dart';
import 'package:soluva/widgets/dialogs/new_request_dialog.dart';
import 'package:soluva/widgets/dialogs/request_detail_dialog.dart';
import 'package:soluva/widgets/dialogs/user_assign_dialog.dart';

class ProfileSolicitudes extends StatefulWidget {
  final String? selectedTab;
  final bool viewingAsWorker;

  const ProfileSolicitudes({
    super.key,
    this.selectedTab,
    this.viewingAsWorker = false,
  });

  @override
  State<ProfileSolicitudes> createState() => _ProfileSolicitudesState();
}

class _ProfileSolicitudesState extends State<ProfileSolicitudes> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  int _page = 1;
  int _lastPage = 1;
  bool _loadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadRequests();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMore();
      }
    });
  }

  @override
  void didUpdateWidget(ProfileSolicitudes oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambió el modo de visualización, recargar las solicitudes
    if (oldWidget.viewingAsWorker != widget.viewingAsWorker) {
      _loadRequests();
    }
  }

  Future<void> _loadRequests() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _page = 1;
    });

    try {
      // Usar el endpoint correcto según el modo de visualización
      final result = widget.viewingAsWorker
          ? await ApiService.getWorkerRequests(page: _page)
          : await ApiService.getUserRequests(page: _page);

      if (!mounted) return;

      setState(() {
        _requests = result['data'];
        _lastPage = result['last_page'];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage) return;

    setState(() => _loadingMore = true);

    try {
      _page++;
      // Usar el endpoint correcto según el modo de visualización
      final result = widget.viewingAsWorker
          ? await ApiService.getWorkerRequests(page: _page)
          : await ApiService.getUserRequests(page: _page);

      setState(() {
        _requests.addAll(result['data']);
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  List<Map<String, dynamic>> get _filteredRequests {
    final tab = widget.selectedTab ?? 'Todos';
    if (tab == 'Todos') return _requests;
    return _requests.where((r) {
      final status = r['status']?.toString().toLowerCase() ?? '';
      if (tab == 'Pendientes') return status != 'completed';
      if (tab == 'Terminados') return status == 'completed';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredRequests.isEmpty) {
      return Center(
        child: Text(
          'No hay solicitudes',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: _filteredRequests.length + 1,
      itemBuilder: (context, index) {
        if (index == _filteredRequests.length) {
          if (_loadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (_page < _lastPage) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: ElevatedButton(
                  onPressed: _loadMore,
                  child: const Text("Cargar más"),
                ),
              ),
            );
          }
          return const SizedBox.shrink();
        }

        return _RequestCard(
          request: _filteredRequests[index],
          onUpdate: _loadRequests,
          viewingAsWorker: widget.viewingAsWorker,
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onUpdate;
  final bool viewingAsWorker;

  const _RequestCard({
    required this.request,
    required this.onUpdate,
    this.viewingAsWorker = false,
  });

  @override
  Widget build(BuildContext context) {
    // Si estamos viendo como trabajador, mostrar el nombre del usuario; si no, el del trabajador
    final displayName = viewingAsWorker
        ? (request['user'] != null
              ? "${request['user']['name'] ?? ''} ${request['user']['last_name'] ?? ''}"
                    .trim()
              : 'Usuario')
        : (request['worker_name'] ?? 'Trabajador');

    final service = request['service'] ?? 'Servicio';
    final createdAt = request['created_at'] ?? '';
    final scheduledDate = request['scheduled_date'] ?? '';
    final status = request['status']?.toString().toLowerCase() ?? 'pending';

    // El cost viene como string desde el servicio
    final costStr = request['cost']?.toString() ?? '0';
    final cost = double.tryParse(costStr) ?? 0.0;

    final isRejected = status == 'rejected' || request['rejected'] == true;

    DateTime? created;
    DateTime? scheduled;
    try {
      if (createdAt.isNotEmpty) created = DateTime.parse(createdAt);
      if (scheduledDate.isNotEmpty) scheduled = DateTime.parse(scheduledDate);
    } catch (_) {}

    Color backgroundColor = Colors.white;
    Color borderColor = Colors.grey[200]!;
    double borderWidth = 1;

    if (status == 'completed' || status == 'cancelled' || status == 'rejected') {
      backgroundColor = const Color(0xFFEAE6DB).withOpacity(0.8);
    } else if (!viewingAsWorker &&
        (status == 'assigned' ||
            status == 'worker_completed' ||
            status == 'provider_completed')) {
      // Usuario necesita confirmar finalización
      backgroundColor = const Color(0xFFFFF4E6);
      borderColor = AppColors.secondary;
      borderWidth = 2;
    } else if (viewingAsWorker &&
        (status == 'pending' || status == 'user_completed')) {
      // Trabajador necesita actuar
      backgroundColor = const Color(0xFFFFF4E6);
      borderColor = AppColors.secondary;
      borderWidth = 2;
    }

    // Determinar si se puede hacer clic
    final canTap =
        (viewingAsWorker &&
            status != 'cancelled' &&
            status != 'completed' &&
            status != 'rejected') ||
        (!viewingAsWorker &&
            status != 'completed' &&
            status != 'cancelled' &&
            status != 'rejected');

    return GestureDetector(
      onTap: canTap ? () => _showRequestDialog(context) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: AppColors.text,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service,
                        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                      ),
                      if (scheduled != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _formatScheduledDate(scheduled),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (created != null)
                      Text(
                        _formatCreatedDate(created),
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${cost.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _StatusProgress(
              status: status,
              isRejected: isRejected,
              viewingAsWorker: viewingAsWorker,
            ),
            const SizedBox(height: 16),
            // Mostrar etiqueta de estado según rol y estado actual
            _buildStatusBadge(status, isRejected),
          ],
        ),
      ),
    );
  }

  void _showRequestDialog(BuildContext context) {
    final status = request['status']?.toString().toLowerCase() ?? 'pending';

    if (!viewingAsWorker) {
      // Flujo del usuario
      if (status == 'pending') {
        _showCancelDialog(context);
      } else if (status == 'accepted') {
        showDialog(
          context: context,
          builder: (context) => UserAssignDialog(
            request: request,
            onPaymentFinished: onUpdate,
          ),
        );
      } else if (status == 'assigned' ||
          status == 'worker_completed' ||
          status == 'provider_completed') {
        _showUserStep3Dialog(context);
      } else if (status == 'user_completed') {
        _showUserWaitingDialog(context);
      }
      return;
    }

    // Flujo del trabajador
    if (status == 'pending') {
      showDialog(
        context: context,
        builder: (context) =>
            NewRequestDialog(request: request, onUpdate: onUpdate),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) =>
            RequestDetailDialog(request: request, onUpdate: onUpdate),
      );
    }
  }

  Widget _buildStatusBadge(String status, bool isRejected) {
    String label;
    Color bgColor;

    if (isRejected) {
      label = 'Solicitud rechazada';
      bgColor = const Color(0xFF1E3A4A);
    } else if (status == 'cancelled') {
      label = 'Cancelada';
      bgColor = AppColors.text;
    } else if (status == 'completed') {
      label = 'Trabajo finalizado';
      bgColor = AppColors.text;
    } else if (!viewingAsWorker) {
      if (status == 'pending') {
        label = 'Pendiente de confirmación';
        bgColor = AppColors.text;
      } else if (status == 'accepted') {
        label = 'Esperando pago';
        bgColor = AppColors.secondary;
      } else if (status == 'assigned' ||
          status == 'worker_completed' ||
          status == 'provider_completed') {
        label = 'Confirmar finalización';
        bgColor = AppColors.button;
      } else if (status == 'user_completed') {
        label = 'Esperando confirmación del prestador';
        bgColor = AppColors.text;
      } else {
        return const SizedBox.shrink();
      }
    } else {
      // viewingAsWorker
      if (status == 'pending') {
        label = 'Nueva solicitud';
        bgColor = AppColors.secondary;
      } else if (status == 'accepted') {
        label = 'Esperando pago';
        bgColor = AppColors.text;
      } else if (status == 'assigned' || status == 'user_completed') {
        label = 'Confirmar finalización';
        bgColor = AppColors.button;
      } else if (status == 'worker_completed' ||
          status == 'provider_completed') {
        label = 'Esperando confirmación del usuario';
        bgColor = AppColors.text;
      } else {
        return const SizedBox.shrink();
      }
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showUserStep3Dialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E3A4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '¿Qué deseas hacer?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showRatingDialog(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Confirmar y clasificar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showProblemDialog(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Reportar problema',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showCancelDialog(context);
                  },
                  child: const Text(
                    'Cancelar solicitud',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserWaitingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E3A4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.hourglass_empty,
                color: AppColors.secondary,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Esperando confirmación del prestador.\nTe notificaremos cuando confirme.',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showProblemDialog(context);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Reportar problema',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Cerrar',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E3A4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.secondary,
                size: 64,
              ),
              const SizedBox(height: 24),
              const Text(
                'Quires cancelar esta solicitud?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'No',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final uuid = request['uuid']?.toString();
                        if (uuid == null) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Error: No se pudo identificar la solicitud',
                              ),
                              backgroundColor: AppColors.secondary,
                            ),
                          );
                          return;
                        }

                        // Cerrar el diálogo de confirmación
                        Navigator.pop(ctx);

                        // Cambiar el estado a 'cancelled'
                        final result = await ApiService.changeRequestStatus(
                          uuid: uuid,
                          status: 'cancelled',
                        );

                        // Mostrar resultado
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message'] ?? 'Operación completada',
                              ),
                              backgroundColor: result['success'] == true
                                  ? Colors.green
                                  : AppColors.secondary,
                            ),
                          );
                        }

                        // Actualizar lista
                        onUpdate();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Sí, cancelar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
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

  void _showConfirmationDialog(BuildContext context, bool isFinished) {
    if (isFinished) {
      _showRatingDialog(context);
    } else {
      _showProblemDialog(context);
    }
  }

  void _showRatingDialog(BuildContext context) {
    int qualityRating = 0;
    int punctualityRating = 0;
    int kindnessRating = 0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E3A4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: StatefulBuilder(
          builder: (context, setDialogState) => Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        'Contanos como fue tu experiencia\ncon ${request['worker_name'] ?? 'el trabajador'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _RatingRow(
                  label: 'Calidad de trabajo',
                  rating: qualityRating,
                  onRatingChanged: (r) =>
                      setDialogState(() => qualityRating = r),
                ),
                const SizedBox(height: 20),
                _RatingRow(
                  label: 'Puntualidad',
                  rating: punctualityRating,
                  onRatingChanged: (r) =>
                      setDialogState(() => punctualityRating = r),
                ),
                const SizedBox(height: 20),
                _RatingRow(
                  label: 'Amabilidad',
                  rating: kindnessRating,
                  onRatingChanged: (r) =>
                      setDialogState(() => kindnessRating = r),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'Comentarios (opcional)',
                    hintStyle: TextStyle(
                      color: AppColors.secondary.withOpacity(0.6),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFEAE6DB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Validar que todas las calificaciones estén completas
                      if (qualityRating == 0 ||
                          punctualityRating == 0 ||
                          kindnessRating == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Por favor completa todas las calificaciones',
                            ),
                            backgroundColor: AppColors.secondary,
                          ),
                        );
                        return;
                      }

                      final uuid = request['id']?.toString();
                      if (uuid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Error: No se pudo identificar la solicitud',
                            ),
                            backgroundColor: AppColors.secondary,
                          ),
                        );
                        return;
                      }

                      // Cerrar el diálogo de calificación
                      Navigator.pop(ctx);

                      // Enviar calificación
                      final result = await ApiService.createRating(
                        requestUuid: uuid,
                        workQuality: qualityRating,
                        punctuality: punctualityRating,
                        friendliness: kindnessRating,
                        review: commentController.text.trim(),
                      );

                      // Mostrar resultado
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result['message'] ?? 'Operación completada',
                            ),
                            backgroundColor: result['success'] == true
                                ? Colors.green
                                : AppColors.secondary,
                          ),
                        );
                      }

                      // Actualizar lista
                      onUpdate();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Enviar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProblemDialog(BuildContext context) {
    final problemController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E3A4A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Contanos, ¿hubo algún problema con el trabajador?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: problemController,
                maxLines: 6,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  hintText: 'Describir inconveniente',
                  hintStyle: TextStyle(
                    color: AppColors.secondary.withOpacity(0.6),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFEAE6DB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '*A la brevedad, analizaremos la situación\npara brindarte una respuesta',
                style: TextStyle(color: Colors.white70, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onUpdate();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Enviar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCreatedDate(DateTime date) {
    return DateFormat('d \'de\' MMMM yyyy, HH:mm', 'es').format(date);
  }

  String _formatScheduledDate(DateTime date) {
    return DateFormat('d \'de\' MMMM, HH:mm \'hs.\'', 'es').format(date);
  }
}

class _RatingRow extends StatelessWidget {
  final String label;
  final int rating;
  final ValueChanged<int> onRatingChanged;

  const _RatingRow({
    required this.label,
    required this.rating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () => onRatingChanged(index + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.star,
                    color: index < rating ? AppColors.secondary : Colors.white,
                    size: 32,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _StatusProgress extends StatelessWidget {
  final String status;
  final bool isRejected;
  final bool viewingAsWorker;

  const _StatusProgress({
    required this.status,
    this.isRejected = false,
    this.viewingAsWorker = false,
  });

  @override
  Widget build(BuildContext context) {
    int currentStep = 0;
    if (status == 'accepted') currentStep = 1;
    if (status == 'assigned' ||
        status == 'worker_completed' ||
        status == 'provider_completed' ||
        status == 'user_completed') {
      currentStep = 2;
    }
    if (status == 'completed') currentStep = 3;

    final List<Map<String, dynamic>> steps = viewingAsWorker
        ? [
            {'label': 'Nueva\nsolicitud', 'icon': Icons.schedule},
            {'label': 'Esperando\npago', 'icon': Icons.check_circle_outline},
            {'label': 'Confirmar\nfinalización', 'icon': Icons.verified_outlined},
            {'label': 'Trabajo\nfinalizado', 'icon': Icons.done_all},
          ]
        : [
            {'label': 'Pendiente de\nconfirmación', 'icon': Icons.schedule},
            {'label': 'Esperando\npago', 'icon': Icons.check_circle_outline},
            {'label': 'Confirmar\nfinalización', 'icon': Icons.verified_outlined},
            {'label': 'Trabajo\nfinalizado', 'icon': Icons.done_all},
          ];

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentStep;
        final isLast = index == steps.length - 1;

        // Colores especiales si la solicitud fue rechazada
        final rejectedColor = const Color(0xFF1E3A4A);

        final Color iconColor = isRejected
            ? (isActive ? rejectedColor : Colors.grey[400]!)
            : (isActive ? AppColors.secondary : Colors.grey[400]!);

        final Color textColor = isRejected
            ? (isActive ? rejectedColor : Colors.grey[500]!)
            : (isActive ? AppColors.text : Colors.grey[500]!);

        final Color lineColor = isRejected
            ? (isActive ? rejectedColor : Colors.grey[300]!)
            : (isActive ? AppColors.secondary : Colors.grey[300]!);

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      steps[index]['icon'] as IconData,
                      color: iconColor,
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[index]['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Container(
                  height: 2,
                  width: 20,
                  margin: const EdgeInsets.only(bottom: 40),
                  color: lineColor,
                ),
            ],
          ),
        );
      }),
    );
  }
}
