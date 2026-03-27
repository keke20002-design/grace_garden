import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _buildTheme(Brightness.dark);
  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isDark ? AppColors.darkPrimaryGreen : AppColors.lightPrimaryGreen,
      onPrimary: Colors.white,
      primaryContainer: isDark ? AppColors.darkPrimaryGreenVariant : AppColors.lightPrimaryGreenVariant,
      onPrimaryContainer: Colors.white,
      secondary: isDark ? AppColors.darkGold : AppColors.lightGold,
      onSecondary: isDark ? Colors.black : Colors.white,
      secondaryContainer: isDark ? const Color(0xFF2A2416) : const Color(0xFFFFF8E1),
      onSecondaryContainer: isDark ? AppColors.darkGold : AppColors.lightGold,
      error: const Color(0xFFE57373),
      onError: Colors.white,
      surface: isDark ? AppColors.darkBackgroundLevel1 : AppColors.lightBackgroundLevel1,
      onSurface: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      surfaceContainerHighest: isDark ? AppColors.darkBackgroundLevel2 : AppColors.lightBackgroundLevel2,
    );

    final baseTextTheme = GoogleFonts.notoSansKrTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? AppColors.darkBackgroundBase : AppColors.lightBackgroundBase,
      textTheme: baseTextTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.darkBackgroundBase : AppColors.lightBackgroundLevel1,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: isDark ? AppColors.darkBackgroundLevel1 : AppColors.lightBackgroundLevel1,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColors.darkBackgroundLevel1 : AppColors.lightBackgroundLevel1,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkBackgroundLevel2 : AppColors.lightBackgroundLevel2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          minimumSize: const Size(double.infinity, 52),
          textStyle: GoogleFonts.notoSansKr(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
