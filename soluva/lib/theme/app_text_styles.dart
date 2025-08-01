import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Encabezados
  static const TextStyle heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.text,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.text,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.text,
  );

  // Texto general
  static const TextStyle bodyText = TextStyle(
    fontSize: 14,
    color: AppColors.text,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.text
  );

  // Botones
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Mensajes de error
  static const TextStyle errorText = TextStyle(
    fontSize: 13,
    color: AppColors.error,
  );

  // Aliases para retrocompatibilidad
  static const TextStyle headline = heading1;
  static const TextStyle body = bodyText;
  static const TextStyle button = buttonText;
  static const TextStyle error = errorText;
}
