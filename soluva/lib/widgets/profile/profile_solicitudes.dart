import 'package:flutter/material.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:soluva/services/api_services/request_service.dart';
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
    setState(() {
      _loading = true;
      _page = 1;
    });

    try {
      // Usar el endpoint correcto según el modo de visualización
      final result = widget.viewingAsWorker
          ? await RequestService.getWorkerRequests(page: _page)
          : await RequestService.getUserRequests(page: _page);

      setState(() {
        _requests = result['data'];
        _lastPage = result['last_page'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage) return;

    setState(() => _loadingMore = true);

    try {
      _page++;
      // Usar el endpoint correcto según el modo de visualización
      final result = widget.viewingAsWorker
          ? await RequestService.getWorkerRequests(page: _page)
          : await RequestService.getUserRequests(page: _page);

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
    final workerName = request['worker_name'] ?? 'Trabajador';
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

    if (status == 'completed' || status == 'cancelled') {
      backgroundColor = const Color(0xFFEAE6DB).withOpacity(0.8);
    } else if (status == 'worker_completed' || status == 'provider_completed') {
      backgroundColor = const Color(0xFFFFF4E6); // Color naranja claro para llamar la atención
      borderColor = AppColors.secondary; // Borde naranja para llamar más la atención
      borderWidth = 2;
    }

    // Determinar si se puede hacer clic
    final canTap = (viewingAsWorker && status != 'cancelled' && status != 'completed' && status != 'rejected') ||
                   (!viewingAsWorker && status == 'accepted');

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
                      workerName,
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
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
          _StatusProgress(status: status, isRejected: isRejected),
          const SizedBox(height: 16),
          // Mostrar botón de estado según el estado de la solicitud
          if (isRejected)
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A4A),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Solicitud rechazada',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            )
          else if (status == 'completed')
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.text,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Finalizado',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            )
          else if (status == 'cancelled')
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.text,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Cancelada',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          if ((status == 'provider_completed' || status == 'worker_completed') && !viewingAsWorker)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => _showConfirmationDialog(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'Si, ya está finalizado',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () => _showConfirmationDialog(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.secondary,
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: const Text(
                      'No, todavía no',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        ),
      ),
    );
  }

  void _showRequestDialog(BuildContext context) {
    // DEBUG: Imprimir todos los datos de la solicitud
    print('DEBUG: Datos completos de la solicitud:');
    print(request);

    final status = request['status']?.toString().toLowerCase() ?? 'pending';

    // Si es usuario y el estado es 'accepted', mostrar diálogo de asignación
    if (!viewingAsWorker && status == 'accepted') {
      showDialog(
        context: context,
        builder: (context) => UserAssignDialog(
          request: request,
          onUpdate: onUpdate,
        ),
      );
      return;
    }

    // Para trabajadores: mostrar el popup correspondiente según el estado
    if (status == 'pending') {
      // Nueva solicitud (sin aceptar)
      showDialog(
        context: context,
        builder: (context) => NewRequestDialog(
          request: request,
          onUpdate: onUpdate,
        ),
      );
    } else {
      // Solicitud aceptada, en progreso o completada
      showDialog(
        context: context,
        builder: (context) => RequestDetailDialog(
          request: request,
          onUpdate: onUpdate,
        ),
      );
    }
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
                      if (qualityRating == 0 || punctualityRating == 0 || kindnessRating == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Por favor completa todas las calificaciones'),
                            backgroundColor: AppColors.secondary,
                          ),
                        );
                        return;
                      }

                      final uuid = request['id']?.toString();
                      if (uuid == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Error: No se pudo identificar la solicitud'),
                            backgroundColor: AppColors.secondary,
                          ),
                        );
                        return;
                      }

                      // Cerrar el diálogo de calificación
                      Navigator.pop(ctx);

                      // Mostrar indicador de carga
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(child: CircularProgressIndicator()),
                      );

                      // Enviar calificación
                      final result = await RequestService.createRating(
                        requestUuid: uuid,
                        workQuality: qualityRating,
                        punctuality: punctualityRating,
                        friendliness: kindnessRating,
                        review: commentController.text.trim(),
                      );

                      // Cerrar indicador de carga
                      if (context.mounted) Navigator.pop(context);

                      // Mostrar resultado
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result['message'] ?? 'Operación completada'),
                            backgroundColor: result['success'] == true ? Colors.green : AppColors.secondary,
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

  const _StatusProgress({required this.status, this.isRejected = false});

  @override
  Widget build(BuildContext context) {
    int currentStep = 0;
    if (status == 'confirmed' || status == 'accepted' || status == 'assigned') currentStep = 1;
    if (status == 'in_progress') currentStep = 2;
    if (status == 'provider_completed' || status == 'worker_completed' || status == 'user_completed') currentStep = 2;
    if (status == 'completed') currentStep = 3;

    // Determinar el texto del paso 3 según quién completó primero
    String step3Label;
    if (status == 'user_completed') {
      step3Label = 'Usuario confirmó\nla prestación\ndel servicio';
    } else if (status == 'worker_completed' || status == 'provider_completed') {
      step3Label = 'Prestador\ncomunica la finalización\ndel servicio';
    } else {
      step3Label = 'Prestador\ncomunica la finalización\ndel servicio';
    }

    final steps = [
      {'label': 'Pendiente de\nconfirmación', 'icon': Icons.schedule},
      {
        'label': 'Confirmado,\nEsperando visita',
        'icon': Icons.check_circle_outline,
      },
      {
        'label': step3Label,
        'icon': Icons.verified_outlined,
      },
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
