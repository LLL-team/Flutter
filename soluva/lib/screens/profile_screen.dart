import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:soluva/services/api_services/api_service.dart';
import 'package:soluva/services/api_services/request_service.dart'; // <--- Importa el servicio
import 'package:soluva/theme/app_colors.dart';
import 'package:soluva/widgets/header_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  Uint8List? _imageBytes;
  bool loading = true;
  int selectedMenu = 1; // 1: Solicitudes, 2: Mis Datos, 3: Formas de pago

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final data = await ApiService.getUserProfile();
    if (mounted) {
      setState(() {
        user = data;
        loading = false;
      });
    }
    if (data != null && data['uuid'] != null) {
      final fotoBytes = await ApiService.getFoto(data['uuid']);
      if (mounted) {
        setState(() {
          _imageBytes = fotoBytes;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: Text('No se pudo cargar el perfil')),
      );
    }

    final fullName = "${user!['name'] ?? ''} ${user!['last_name'] ?? ''}".trim();
    final email = user!['email'] ?? '';
    final avatar = _imageBytes != null ? MemoryImage(_imageBytes!) : null;

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const HeaderWidget(),
      body: isMobile
          ? _MobileProfileView(
              fullName: fullName,
              email: email,
              avatar: avatar,
              selectedMenu: selectedMenu,
              onMenuChanged: (i) => setState(() => selectedMenu = i),
              mainContent: _buildMainContent(isMobile: true),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menú lateral
                Container(
                  width: 260,
                  color: AppColors.background,
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.secondary,
                        backgroundImage: avatar,
                        child: avatar == null
                            ? const Icon(Icons.person, size: 60, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppColors.text,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      _ProfileMenuButton(
                        icon: Icons.person,
                        text: "Mis Datos",
                        selected: selectedMenu == 2,
                        onTap: () => setState(() => selectedMenu = 2),
                      ),
                      _ProfileMenuButton(
                        icon: Icons.list_alt,
                        text: "Solicitudes",
                        selected: selectedMenu == 1,
                        onTap: () => setState(() => selectedMenu = 1),
                      ),
                      _ProfileMenuButton(
                        icon: Icons.credit_card,
                        text: "Formas de pago",
                        selected: selectedMenu == 3,
                        onTap: () => setState(() => selectedMenu = 3),
                      ),
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () {
                          // Acción inscripción como trabajador
                        },
                        child: const Text(
                          "Inscripción\ncomo trabajador",
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenido principal
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Container(
                        width: 600,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _buildMainContent(isMobile: false),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMainContent({required bool isMobile}) {
    if (selectedMenu == 1) {
      // Solicitudes (vacío, listo para conectar a API)
      return _SolicitudesList(isMobile: isMobile);
    } else if (selectedMenu == 2) {
      // Mis Datos
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            "Aquí irán los datos del usuario para editar.",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    } else {
      // Formas de pago
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            "Aquí irán las formas de pago.",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }
  }
}

class _ProfileMenuButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileMenuButton({
    required this.icon,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          child: Row(
            children: [
              Icon(icon, color: AppColors.text, size: 22),
              const SizedBox(width: 16),
              Text(
                text,
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Responsive mobile view
class _MobileProfileView extends StatelessWidget {
  final String fullName;
  final String email;
  final ImageProvider<Object>? avatar;
  final int selectedMenu;
  final ValueChanged<int> onMenuChanged;
  final Widget mainContent;

  const _MobileProfileView({
    required this.fullName,
    required this.email,
    required this.avatar,
    required this.selectedMenu,
    required this.onMenuChanged,
    required this.mainContent,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      children: [
        Center(
          child: CircleAvatar(
            radius: 44,
            backgroundColor: AppColors.secondary,
            backgroundImage: avatar,
            child: avatar == null
                ? const Icon(Icons.person, size: 48, color: Colors.white)
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Text(
            fullName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.text,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Center(
          child: Text(
            email,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _MobileMenuButton(
              icon: Icons.list_alt,
              text: "Solicitudes",
              selected: selectedMenu == 1,
              onTap: () => onMenuChanged(1),
            ),
            _MobileMenuButton(
              icon: Icons.person,
              text: "Mis Datos",
              selected: selectedMenu == 2,
              onTap: () => onMenuChanged(2),
            ),
            _MobileMenuButton(
              icon: Icons.credit_card,
              text: "Pago",
              selected: selectedMenu == 3,
              onTap: () => onMenuChanged(3),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: () {
              // Acción inscripción como trabajador
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "Inscripción como trabajador",
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: mainContent,
          ),
        ),
      ],
    );
  }
}

class _MobileMenuButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _MobileMenuButton({
    required this.icon,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.background : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          child: Column(
            children: [
              Icon(icon, color: AppColors.text, size: 22),
              Text(
                text,
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Lista de solicitudes vacía, lista para conectar a API
class _SolicitudesList extends StatefulWidget {
  final bool isMobile;
  const _SolicitudesList({required this.isMobile});

  @override
  State<_SolicitudesList> createState() => _SolicitudesListState();
}

class _SolicitudesListState extends State<_SolicitudesList> {
  int selectedTab = 0; // 0: Todos, 1: Pendientes, 2: Terminados
  List<Map<String, dynamic>> solicitudes = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => loading = true);
    final reqs = await RequestService.getMyRequests();
    setState(() {
      solicitudes = reqs;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Filtrado por estado
    List<Map<String, dynamic>> filtered = solicitudes;
    if (selectedTab == 1) {
      filtered = solicitudes.where((r) => r['status'] == 'pending' || r['status'] == 'assigned').toList();
    } else if (selectedTab == 2) {
      filtered = solicitudes.where((r) => r['status'] == 'finished' || r['status'] == 'completed').toList();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 24,
        horizontal: widget.isMobile ? 8 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs
          Row(
            mainAxisAlignment: widget.isMobile ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              _TabButton(
                text: "Todos",
                selected: selectedTab == 0,
                onTap: () => setState(() => selectedTab = 0),
              ),
              _TabButton(
                text: "Pendientes",
                selected: selectedTab == 1,
                onTap: () => setState(() => selectedTab = 1),
              ),
              _TabButton(
                text: "Terminados",
                selected: selectedTab == 2,
                onTap: () => setState(() => selectedTab = 2),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (filtered.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  "No hay solicitudes para mostrar.",
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
            )
          else
            ...filtered.map((s) => _SolicitudCard(solicitud: s)).toList(),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 18),
          decoration: BoxDecoration(
            color: selected ? AppColors.button.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}

class _SolicitudCard extends StatelessWidget {
  final Map<String, dynamic> solicitud;
  const _SolicitudCard({required this.solicitud});

  @override
  Widget build(BuildContext context) {
    // Ejemplo de visualización básica, puedes personalizarlo
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.notes, color: AppColors.text, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  solicitud['descripcion'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.text,
                  ),
                ),
              ),
              Text(
                solicitud['date'] ?? '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            solicitud['location'] ?? '',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 15,
            ),
          ),
          Text(
            solicitud['type'] ?? '',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                solicitud['status'] ?? '',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              Text(
                solicitud['created_at'] != null
                    ? solicitud['created_at'].toString().substring(0, 10)
                    : '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
