import 'package:flutter/material.dart';
import 'package:soluva/services/api_services/request_service.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:intl/intl.dart';

class ProfileSolicitudes extends StatefulWidget {
  const ProfileSolicitudes({super.key});

  @override
  State<ProfileSolicitudes> createState() => _ProfileSolicitudesState();
}

class _ProfileSolicitudesState extends State<ProfileSolicitudes> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String _selectedTab = 'Todos';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }
Future<void> _loadRequests() async {
  setState(() => _loading = true);
  await Future.delayed(const Duration(seconds: 1)); // Simula carga

  final exampleRequests = [
    {
      'worker_name': 'María López',
      'service': 'Limpieza de hogar',
      'created_at': '2025-10-25T10:30:00Z',
      'scheduled_date': '2025-10-30T15:00:00Z',
      'status': 'pending',
      'cost': 15000.0,
    },
    {
      'worker_name': 'Carlos Pérez',
      'service': 'Plomería',
      'created_at': '2025-10-20T08:00:00Z',
      'scheduled_date': '2025-10-22T10:00:00Z',
      'status': 'in_progress',
      'cost': 20000.0,
    },
    {
      'worker_name': 'Laura Gómez',
      'service': 'Electricidad',
      'created_at': '2025-09-18T09:00:00Z',
      'scheduled_date': '2025-09-19T14:30:00Z',
      'status': 'completed',
      'cost': 18000.0,
    },
    {
      'worker_name': 'Juan Martínez',
      'service': 'Jardinería',
      'created_at': '2025-10-10T12:00:00Z',
      'scheduled_date': '2025-10-12T09:00:00Z',
      'status': 'confirmed',
      'cost': 12000.0,
    },
  ];

  setState(() {
    _requests = exampleRequests;
    _loading = false;
  });
}

  // Future<void> _loadRequests() async {
  //   setState(() => _loading = true);
  //   try {
  //     final requests = await RequestService.getMyRequests();
  //     setState(() {
  //       _requests = requests;
  //       _loading = false;
  //     });
  //   } catch (e) {
  //     setState(() => _loading = false);
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text('Error al cargar solicitudes: $e')),
  //       );
  //     }
  //   }
  // }

  List<Map<String, dynamic>> get _filteredRequests {
    if (_selectedTab == 'Todos') return _requests;
    return _requests.where((r) {
      final status = r['status']?.toString().toLowerCase() ?? '';
      if (_selectedTab == 'Pendientes') return status != 'completed';
      if (_selectedTab == 'Terminados') return status == 'completed';
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildTab('Todos'),
                const SizedBox(width: 32),
                _buildTab('Pendientes'),
                const SizedBox(width: 32),
                _buildTab('Terminados'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                    ? Center(
                        child: Text(
                          'No hay solicitudes',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: _filteredRequests.length,
                        itemBuilder: (context, index) {
                          return _RequestCard(
                            request: _filteredRequests[index],
                            onUpdate: _loadRequests,
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label) {
    final isSelected = _selectedTab == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = label),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.secondary : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          if (isSelected)
            Container(
              height: 3,
              width: 60,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
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

    // Calcular el fondo según el estado
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
                      side: const BorderSide(color: AppColors.secondary, width: 2),
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
                  onRatingChanged: (r) => setDialogState(() => qualityRating = r),
                ),
                const SizedBox(height: 20),
                _RatingRow(
                  label: 'Puntualidad',
                  rating: punctualityRating,
                  onRatingChanged: (r) => setDialogState(() => punctualityRating = r),
                ),
                const SizedBox(height: 20),
                _RatingRow(
                  label: 'Amabilidad',
                  rating: kindnessRating,
                  onRatingChanged: (r) => setDialogState(() => kindnessRating = r),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.text),
                  decoration: InputDecoration(
                    hintText: 'Comentarios (opcional)',
                    hintStyle: TextStyle(color: AppColors.secondary.withOpacity(0.6)),
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
                      // Enviar calificación
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
                  hintStyle: TextStyle(color: AppColors.secondary.withOpacity(0.6)),
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
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
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
      {'label': 'Confirmado,\nEsperando visita', 'icon': Icons.check_circle_outline},
      {
        'label': 'Prestador\ncomunica la finalización\ndel servicio',
        'icon': Icons.verified_outlined
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