import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:soluva/services/api_services/api_service.dart';
import 'package:soluva/theme/app_colors.dart';
import 'package:soluva/widgets/header_widget.dart';
import 'package:soluva/widgets/profile/profile_menu.dart';
import 'package:soluva/widgets/profile/profile_mis_datos.dart';
import 'package:soluva/widgets/profile/profile_solicitudes.dart';
import 'package:soluva/widgets/profile/profile_pagos.dart';
import 'package:soluva/widgets/profile/profile_inscripcion.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? user;
  Uint8List? _imageBytes;
  bool loading = true;
  int selectedMenu = 1; // 1: Solicitudes, 2: Mis Datos, 3: Pago, 4: Inscripción

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
          ? _buildMobileLayout(fullName, email, avatar)
          : _buildDesktopLayout(fullName, email, avatar),
    );
  }

  Widget _buildDesktopLayout(String fullName, String email, ImageProvider? avatar) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProfileMenu(
          fullName: fullName,
          email: email,
          avatar: avatar,
          selectedMenu: selectedMenu,
          onMenuChanged: (i) => setState(() => selectedMenu = i),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.topCenter,
            child: _buildContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(String fullName, String email, ImageProvider? avatar) {
    return Column(
      children: [
        ProfileMenu(
          fullName: fullName,
          email: email,
          avatar: avatar,
          selectedMenu: selectedMenu,
          onMenuChanged: (i) => setState(() => selectedMenu = i),
          isMobile: true,
        ),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    switch (selectedMenu) {
      case 1:
        return const ProfileSolicitudes();
      case 2:
        return const ProfileMisDatos();
      case 3:
        return const ProfilePagos();
      case 4:
        return const ProfileInscripcion();
      default:
        return const SizedBox.shrink();
    }
  }
}
