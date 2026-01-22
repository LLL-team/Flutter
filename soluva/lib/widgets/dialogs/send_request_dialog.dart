import 'package:flutter/material.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:soluva/theme/app_text_styles.dart';
import 'package:soluva/services/api_services/request_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SendRequestDialog extends StatefulWidget {
  final Map<String, dynamic> worker;
  final String selectedTime;
  final String selectedDate;
  final String category;

  const SendRequestDialog({
    super.key,
    required this.worker,
    required this.selectedTime,
    required this.selectedDate,
    required this.category,
  });

  @override
  State<SendRequestDialog> createState() => _SendRequestDialogState();
}

class _SendRequestDialogState extends State<SendRequestDialog> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  List<String> _subcategories = [];
  String? _selectedSubcategory;
  bool _loadingSubcategories = true;

  @override
  void initState() {
    super.initState();
    _loadSubcategories();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _normalizeString(String text) {
    // Quitar acentos y convertir a minúsculas
    final withoutAccents = text
        .replaceAll('á', 'a')
        .replaceAll('Á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('É', 'e')
        .replaceAll('í', 'i')
        .replaceAll('Í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('Ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('Ú', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('Ñ', 'n')
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'\s+'), ' '); // Normalizar múltiples espacios a uno solo

    print('DEBUG NORMALIZE: "$text" -> "$withoutAccents"');
    return withoutAccents;
  }

  bool _categoriesMatch(String cat1, String cat2) {
    final norm1 = _normalizeString(cat1);
    final norm2 = _normalizeString(cat2);

    print('DEBUG MATCH: Comparing "$norm1" with "$norm2"');

    // Comparación directa (contiene)
    if (norm1.contains(norm2) || norm2.contains(norm1)) {
      print('DEBUG MATCH: Direct match found!');
      return true;
    }

    // Extraer palabras significativas
    final words1 = norm1.split(' ').where((w) => w.length >= 3).toSet();
    final words2 = norm2.split(' ').where((w) => w.length >= 3).toSet();

    print('DEBUG MATCH: Words1: $words1, Words2: $words2');

    // Si alguna palabra clave coincide, consideramos match
    final hasMatch = words1.intersection(words2).isNotEmpty;
    print('DEBUG MATCH: Intersection match: $hasMatch');
    return hasMatch;
  }

  Future<void> _loadSubcategories() async {
    setState(() => _loadingSubcategories = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final baseUrl = dotenv.env['BASE_URL'] ?? '';

      final response = await http.get(
        Uri.parse('$baseUrl/service'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('DEBUG: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        print('DEBUG: Category to find: ${widget.category}');

        // Buscar la categoría en la estructura anidada
        List<String> foundSubcategories = [];

        // Recorrer todos los niveles del JSON
        for (var mainCategory in data.entries) {
          print('DEBUG: Main category: ${mainCategory.key}');
          final mainCategoryData = mainCategory.value as Map<String, dynamic>;

          for (var subCategory in mainCategoryData.entries) {
            print('DEBUG: Sub category: ${subCategory.key}');

            // Si encontramos la categoría buscada
            if (_categoriesMatch(widget.category, subCategory.key)) {
              print('DEBUG: MATCH FOUND! ${subCategory.key}');

              final services = subCategory.value as Map<String, dynamic>;
              foundSubcategories = services.keys.toList();
              print('DEBUG: Services found: $foundSubcategories');
              break;
            }
          }

          if (foundSubcategories.isNotEmpty) break;
        }

        setState(() {
          _subcategories = foundSubcategories;
          if (_subcategories.isNotEmpty) {
            _selectedSubcategory = _subcategories[0];
          }
          _loadingSubcategories = false;
        });

        print('DEBUG: Final subcategories: $_subcategories');
      } else {
        print('DEBUG: Error response: ${response.statusCode}');
        setState(() => _loadingSubcategories = false);
      }
    } catch (e) {
      print('Error loading subcategories: $e');
      setState(() => _loadingSubcategories = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workerName = "${widget.worker['name'] ?? ''} ${widget.worker['last_name'] ?? ''}".trim();
    final price = widget.worker['price'] ?? 0;

    return Dialog(
      backgroundColor: AppColors.text,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 500,
          maxHeight: 700,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header con botón cerrar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Detalle de la solicitud',
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const Divider(color: Colors.white24, height: 32),

              // Información del trabajador
              Text(
                workerName,
                style: AppTextStyles.heading2.copyWith(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Categoría
              Text(
                widget.category,
                style: AppTextStyles.bodyText.copyWith(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),

              // Dropdown de subcategorías
              if (_loadingSubcategories)
                const Center(child: CircularProgressIndicator())
              else if (_subcategories.isNotEmpty)
                DropdownButtonFormField<String>(
                  value: _selectedSubcategory,
                  decoration: InputDecoration(
                    labelText: 'Tipo de servicio',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: AppColors.background.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownColor: AppColors.text,
                  style: const TextStyle(color: Colors.white),
                  items: _subcategories.map((subcat) {
                    return DropdownMenuItem<String>(
                      value: subcat,
                      child: Text(subcat),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubcategory = value;
                    });
                  },
                ),
              const SizedBox(height: 16),

              // Horario seleccionado
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.button,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.selectedTime} ${widget.selectedDate}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Precio
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '\$${price.toStringAsFixed(3)}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Campo de dirección
              TextField(
                controller: _addressController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Dirección:',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: AppColors.background.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campo de descripción (opcional)
              TextField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: AppColors.background.withValues(alpha: 0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botón Enviar solicitud
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _sendRequest(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Enviar solicitud',
                    style: AppTextStyles.buttonText.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Texto informativo
              Text(
                '*En cuanto el trabajador responda se le notificará y podrá ejercer el pago',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.blue[300],
                  fontSize: 12,
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sendRequest(BuildContext context) async {
    final address = _addressController.text.trim();
    final description = _descriptionController.text.trim();

    // Validaciones
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa una dirección'),
          backgroundColor: AppColors.secondary,
        ),
      );
      return;
    }

    if (_selectedSubcategory == null || _selectedSubcategory!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona un tipo de servicio'),
          backgroundColor: AppColors.secondary,
        ),
      );
      return;
    }

    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final baseUrl = dotenv.env['BASE_URL'] ?? '';

      // Parsear la fecha del formato "8 Ene 2026" al formato "2026-01-08"
      final dateStr = _parseDate(widget.selectedDate);

      // Construir el body de la solicitud
      final body = {
        'location': address,
        'date': dateStr,
        'type': widget.category,
        'subtype': _selectedSubcategory,
        'uuid': widget.worker['uuid'],
        'start_at': widget.selectedTime,
        'ammount': widget.worker['price'] ?? 0,
      };

      // Agregar descripción solo si no está vacía
      if (description.isNotEmpty) {
        body['descripcion'] = description;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/request/new'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (mounted) Navigator.pop(context); // Cerrar indicador de carga

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          Navigator.pop(context); // Cerrar diálogo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solicitud enviada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Error en la solicitud
        if (mounted) Navigator.pop(context); // Cerrar indicador de carga

        final errorData = jsonDecode(response.body);
        String errorMessage = 'Error al enviar la solicitud';

        if (errorData['errors'] != null) {
          // Formatear errores de validación
          final errors = errorData['errors'] as Map<String, dynamic>;
          errorMessage = errors.values.first[0].toString();
        } else if (errorData['message'] != null) {
          errorMessage = errorData['message'].toString();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar indicador de carga
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: $e'),
            backgroundColor: AppColors.secondary,
          ),
        );
      }
    }
  }

  // Función para parsear la fecha del formato "8 Ene 2026" a "2026-01-08"
  String _parseDate(String dateStr) {
    try {
      final parts = dateStr.split(' ');
      if (parts.length == 3) {
        final day = int.parse(parts[0]).toString().padLeft(2, '0');
        final monthMap = {
          'Ene': '01', 'Feb': '02', 'Mar': '03', 'Abr': '04',
          'May': '05', 'Jun': '06', 'Jul': '07', 'Ago': '08',
          'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dic': '12',
        };
        final month = monthMap[parts[1]] ?? '01';
        final year = parts[2];
        return '$year-$month-$day';
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    // Fallback: devolver fecha actual
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
