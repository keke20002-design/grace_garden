import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // === Dark Mode ===
  static const darkBackgroundBase = Color(0xFF121212);
  static const darkBackgroundLevel1 = Color(0xFF1E1E1E);
  static const darkBackgroundLevel2 = Color(0xFF2A2A2A);
  static const darkSurface = Color(0xFF242424);
  static const darkPrimaryGreen = Color(0xFF4CAF87);
  static const darkPrimaryGreenVariant = Color(0xFF3D9B75);
  static const darkTextPrimary = Color(0xFFFFFFFF);
  static const darkTextSecondary = Color(0xFFB0B0B0);
  static const darkTextDisabled = Color(0xFF666666);
  static const darkDivider = Color(0xFF333333);
  static const darkTreeGreen = Color(0xFF56AB2F);
  static const darkGold = Color(0xFFFFD700); // 달란트 색상
  static const darkAmen = Color(0xFFE57373); // 아멘 버튼

  // === Light Mode ===
  static const lightBackgroundBase = Color(0xFFF5F5F5);
  static const lightBackgroundLevel1 = Color(0xFFFFFFFF);
  static const lightBackgroundLevel2 = Color(0xFFEEEEEE);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightPrimaryGreen = Color(0xFF2E7D5E);
  static const lightPrimaryGreenVariant = Color(0xFF245F4A);
  static const lightTextPrimary = Color(0xFF1A1A1A);
  static const lightTextSecondary = Color(0xFF666666);
  static const lightTextDisabled = Color(0xFFAAAAAA);
  static const lightDivider = Color(0xFFDDDDDD);
  static const lightTreeGreen = Color(0xFF3D8B1F);
  static const lightGold = Color(0xFFB8860B);
  static const lightAmen = Color(0xFFC62828);
}

extension AppColorsExtension on ColorScheme {
  Color get backgroundLevel1 =>
      brightness == Brightness.dark
          ? AppColors.darkBackgroundLevel1
          : AppColors.lightBackgroundLevel1;

  Color get backgroundLevel2 =>
      brightness == Brightness.dark
          ? AppColors.darkBackgroundLevel2
          : AppColors.lightBackgroundLevel2;

  Color get textSecondary =>
      brightness == Brightness.dark
          ? AppColors.darkTextSecondary
          : AppColors.lightTextSecondary;

  Color get dividerColor =>
      brightness == Brightness.dark
          ? AppColors.darkDivider
          : AppColors.lightDivider;

  Color get treeGreen =>
      brightness == Brightness.dark
          ? AppColors.darkTreeGreen
          : AppColors.lightTreeGreen;

  Color get goldColor =>
      brightness == Brightness.dark
          ? AppColors.darkGold
          : AppColors.lightGold;
}
