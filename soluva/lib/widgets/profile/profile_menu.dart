import 'package:flutter/material.dart';
import 'package:soluva/theme/app_colors.dart';

class ProfileMenu extends StatelessWidget {
  final String fullName;
  final String email;
  final ImageProvider? avatar;
  final int selectedMenu;
  final ValueChanged<int> onMenuChanged;
  final bool isMobile;

  const ProfileMenu({
    super.key,
    required this.fullName,
    required this.email,
    required this.avatar,
    required this.selectedMenu,
    required this.onMenuChanged,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return isMobile ? _buildMobileMenu() : _buildDesktopMenu();
  }

  // ================= DESKTOP =================
  Widget _buildDesktopMenu() {
    return Container(
      width: 220,
      color: AppColors.background,
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Avatar circular grande
          CircleAvatar(
            radius: 60,
            backgroundColor: AppColors.secondary,
            backgroundImage: avatar,
            child: avatar == null
                ? const Icon(Icons.person, size: 70, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 24),
          // Nombre y email
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.text,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Botones del menú estándar
          _menuButton("Mis Datos", 1),
          _menuButton("Solicitudes", 2),
          _menuButton("Formas de pago", 3),
          _menuButton("Notificaciones", 4),
          const SizedBox(height: 20),
          // Botón destacado de inscripción
          _highlightedMenuButton("Inscripción\ncomo trabajador", 5),
        ],
      ),
    );
  }

  Widget _menuButton(String text, int index) {
    final selected = selectedMenu == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onMenuChanged(index),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            border: selected
                ? Border(
                    left: BorderSide(
                      color: AppColors.secondary,
                      width: 4,
                    ),
                  )
                : null,
          ),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? AppColors.text : Colors.grey[700],
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _highlightedMenuButton(String text, int index) {
    final selected = selectedMenu == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onMenuChanged(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: selected 
                    ? [AppColors.secondary, const Color(0xFFFF6B35)]
                    : [AppColors.secondary.withOpacity(0.9), const Color(0xFFFF6B35).withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
                height: 1.3,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= MOBILE =================
  Widget _buildMobileMenu() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 12),
            _mobileTab("Solicitudes", 1),
            _mobileTab("Datos", 2),
            _mobileTab("Pago", 3),
            _mobileTab("Inscripción", 4),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _mobileTab(String text, int index) {
    final selected = selectedMenu == index;
    return GestureDetector(
      onTap: () => onMenuChanged(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(color: AppColors.secondary, width: 2)
              : Border.all(color: Colors.grey[400]!, width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? AppColors.text : Colors.grey[700],
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}