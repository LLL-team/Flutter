import 'package:flutter/material.dart';
import 'package:soluva/services/api_services/api_service.dart';
import 'package:soluva/theme/app_colors.dart';

class ProfileMisDatos extends StatefulWidget {
  const ProfileMisDatos({super.key});

  @override
  State<ProfileMisDatos> createState() => _ProfileMisDatosState();
}

class _ProfileMisDatosState extends State<ProfileMisDatos> {
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _certificateController = TextEditingController();

  bool _loading = true;
  bool _isWorker = false;
  bool _editingPhone = false;
  bool _editingAddress = false;
  bool _editingCertificate = false;

  Map<String, List<String>>? _workerTrades;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _loading = true);
    try {
      final user = await ApiService.getUserProfile();
      if (user != null) {
        _nameController.text = '${user['name'] ?? ''} ${user['last_name'] ?? ''}';
        _emailController.text = user['email'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _addressController.text = user['address'] ?? '';
        _certificateController.text = user['certificate'] ?? '';
        
        // Verificar si es trabajador
        try {
          final statusResponse = await ApiService.getStatus();
          _isWorker = statusResponse['status'] == 'approved';
          
          if (_isWorker && user['trade'] != null) {
            _workerTrades = Map<String, List<String>>.from(
              (user['trade'] as Map<String, dynamic>).map(
                (key, value) => MapEntry(key, List<String>.from(value)),
              ),
            );
            if (_workerTrades!.isNotEmpty) {
              _selectedCategory = _workerTrades!.keys.first;
            }
          }
        } catch (e) {
          // Si no es trabajador, continuar normalmente
          _isWorker = false;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos: $e')),
        );
      }
    }
    setState(() => _loading = false);
  }

  Future<void> _saveField(String field) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos actualizados correctamente')),
        );
      }
      setState(() {
        _editingPhone = false;
        _editingAddress = false;
        _editingCertificate = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _certificateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 2000),
            child: Column(
              children: [
                // Card principal con datos básicos
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReadOnlyField('Nombre y Apellido', _nameController.text),
                      const SizedBox(height: 20),
                      _buildReadOnlyField('mail', _emailController.text),
                      const SizedBox(height: 20),
                      _buildEditableField(
                        'Teléfono',
                        _phoneController,
                        _editingPhone,
                        () => setState(() => _editingPhone = !_editingPhone),
                        () => _saveField('phone'),
                      ),
                      const SizedBox(height: 20),
                      _buildEditableField(
                        'Dirección',
                        _addressController,
                        _editingAddress,
                        () => setState(() => _editingAddress = !_editingAddress),
                        () => _saveField('address'),
                      ),
                      if (_isWorker) ...[
                        const SizedBox(height: 20),
                        _buildEditableField(
                          'Certificado/Matrícula',
                          _certificateController,
                          _editingCertificate,
                          () => setState(() => _editingCertificate = !_editingCertificate),
                          () => _saveField('certificate'),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Sección exclusiva para trabajadores
                if (_isWorker) ...[
                  const SizedBox(height: 32),
                  _buildWorkerSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.text,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value.isEmpty ? 'No especificado' : value,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableField(
    String label,
    TextEditingController controller,
    bool isEditing,
    VoidCallback onEdit,
    VoidCallback onSave,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (isEditing)
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.secondary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.secondary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                )
              else
                Text(
                  controller.text.isEmpty ? 'No especificado' : controller.text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.text,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: isEditing ? onSave : onEdit,
          icon: Icon(
            isEditing ? Icons.check : Icons.edit,
            color: AppColors.secondary,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkerSection() {
    if (_workerTrades == null || _workerTrades!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header "Oficios"
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.secondary,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Text(
            'Oficios:',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Grid de categorías con hover effect
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _workerTrades!.keys.map((category) {
            final isSelected = category == _selectedCategory;
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFFEAE6DB),
                    borderRadius: BorderRadius.circular(16),
                    border: isSelected
                        ? Border.all(color: AppColors.secondary, width: 3)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _getCategoryIcon(category),
                      const SizedBox(height: 12),
                      Text(
                        category,
                        style: TextStyle(
                          color: AppColors.text,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 24),
        
        // Contenido de la categoría seleccionada con hover
        if (_selectedCategory != null)
          MouseRegion(
            onEnter: (_) => _showEditTooltip(),
            child: _buildCategoryContent(_selectedCategory!),
          ),
      ],
    );
  }

  void _showEditTooltip() {
    // Aquí podrías mostrar un tooltip o cambiar un estado para mostrar el botón de edición
  }

  Widget _buildCategoryContent(String category) {
    final services = _workerTrades![category] ?? [];
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _getCategoryIcon(category),
              const SizedBox(width: 16),
              Text(
                category,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Lista de servicios con precios
          ...services.map((service) => _buildServiceRow(service)),
          const SizedBox(height: 24),
          // Botón para guardar cambios
          Center(
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cambios guardados')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Guardar cambios',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceRow(String service) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: AppColors.text),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              service,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.text,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '\$ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: AppColors.secondary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 70,
            child: Text(
              _getPriceType(service),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getPriceType(String service) {
    if (service.toLowerCase().contains('general')) return 'x m²';
    return 'x hora';
  }

  Widget _getCategoryIcon(String category) {
    IconData icon;
    Color color;
    
    switch (category.toLowerCase()) {
      case 'jardinería':
      case 'jardín':
        icon = Icons.grass;
        color = Colors.green;
        break;
      case 'limpieza':
        icon = Icons.cleaning_services;
        color = Colors.blue;
        break;
      case 'arregla tutti':
        icon = Icons.build;
        color = Colors.orange;
        break;
      case 'plomería':
        icon = Icons.plumbing;
        color = Colors.blueAccent;
        break;
      default:
        icon = Icons.work;
        color = AppColors.secondary;
    }
    
    return Icon(icon, color: color, size: 48);
  }
}