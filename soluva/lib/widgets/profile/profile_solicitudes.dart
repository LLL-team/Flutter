import 'package:flutter/material.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:soluva/services/api_services/request_service.dart';

class ProfileSolicitudes extends StatefulWidget {
  final String? selectedTab;

  const ProfileSolicitudes({super.key, this.selectedTab});

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

  Future<void> _loadRequests() async {
    setState(() {
      _loading = true;
      _page = 1;
    });

    try {
      final result = await RequestService.getMyRequests(page: _page);

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
      final result = await RequestService.getMyRequests(page: _page);

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
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onUpdate;

  const _RequestCard({required this.request, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final workerName = request['worker_name'] ?? 'Trabajador';
    final service = request['service'] ?? 'Servicio';
    final createdAt = request['created_at'] ?? '';
    final scheduledDate = request['scheduled_date'] ?? '';
    final status = request['status']?.toString().toLowerCase() ?? 'pending';
    final cost = request['cost'] ?? 0;
    final isRejected = request['rejected'] == true;

    DateTime? created;
    DateTime? scheduled;
    try {
      if (createdAt.isNotEmpty) created = DateTime.parse(createdAt);
      if (scheduledDate.isNotEmpty) scheduled = DateTime.parse(scheduledDate);
    } catch (_) {}

    Color backgroundColor = Colors.white;
    if (status == 'completed') {
      backgroundColor = const Color(0xFFEAE6DB).withOpacity(0.8);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
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
                    '\$${cost.toStringAsFixed(3)}',
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
          _StatusProgress(status: status),
          if (isRejected)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
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
              ),
            ),
          if (status == 'completed' && !isRejected)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Text(
                    'Solicitud de trabajo finalizada',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          if (status == 'provider_completed')
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

  const _StatusProgress({required this.status});

  @override
  Widget build(BuildContext context) {
    int currentStep = 0;
    if (status == 'confirmed') currentStep = 1;
    if (status == 'in_progress') currentStep = 2;
    if (status == 'provider_completed') currentStep = 2;
    if (status == 'completed') currentStep = 3;

    final steps = [
      {'label': 'Pendiente de\nconfirmación', 'icon': Icons.schedule},
      {
        'label': 'Confirmado,\nEsperando visita',
        'icon': Icons.check_circle_outline,
      },
      {
        'label': 'Prestador\ncomunica la finalización\ndel servicio',
        'icon': Icons.verified_outlined,
      },
      {'label': 'Trabajo\nfinalizado', 'icon': Icons.done_all},
    ];

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index <= currentStep;
        final isLast = index == steps.length - 1;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Icon(
                      steps[index]['icon'] as IconData,
                      color: isActive ? AppColors.secondary : Colors.grey[400],
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      steps[index]['label'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive ? AppColors.text : Colors.grey[500],
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
                  color: isActive ? AppColors.secondary : Colors.grey[300],
                ),
            ],
          ),
        );
      }),
    );
  }
}
