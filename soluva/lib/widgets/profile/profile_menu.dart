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
          _menuButton(Icons.list_alt, "Solicitudes", 1),
          _menuButton(Icons.person, "Mis Datos", 2),
          _menuButton(Icons.credit_card, "Formas de pago", 3),
          _menuButton(Icons.work, "Inscripción como trabajador", 4),
        ],
      ),
    );
  }

  Widget _menuButton(IconData icon, String text, int index) {
    final selected = selectedMenu == index;
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      child: InkWell(
        onTap: () => onMenuChanged(index),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.text, size: 22),
              const SizedBox(width: 12),
              Expanded( // ✅ Evita overflow
                child: Text(
                  text,
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis, // corta si es muy largo
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= MOBILE =================
  Widget _buildMobileMenu() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _iconButton(Icons.list_alt, "Solicitudes", 1),
          _iconButton(Icons.person, "Datos", 2),
          _iconButton(Icons.credit_card, "Pago", 3),
          _iconButton(Icons.work, "Inscripción", 4),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, String text, int index) {
    final selected = selectedMenu == index;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onMenuChanged(index),
      child: Column(
        children: [
          Icon(icon, color: selected ? AppColors.secondary : AppColors.text),
          const SizedBox(height: 4),
          SizedBox(
            width: 60, // limita el ancho del texto en mobile
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
