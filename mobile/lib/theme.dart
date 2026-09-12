import 'package:flutter/material.dart';

/// Identité visuelle AngeValencia : orange, noir, beige "colombe" — pas de blanc en fond.
class AppColors {
  static const Color orange = Color(0xFFF57C00);
  static const Color orangeDark = Color(0xFFE65100);
  static const Color black = Color(0xFF16130E);
  static const Color beige = Color(0xFFEAE2CE); // "couleur colombe"
  static const Color beigeLight = Color(0xFFF4EEE0); // surface des cartes
  static const Color beigeDark = Color(0xFFD9CEB4);
  static const Color textPrimary = Color(0xFF1B1710);
  static const Color textMuted = Color(0xFF6B6150);
  static const Color success = Color(0xFF2E7D32);
  static const Color error = Color(0xFFB71C1C);
}

/// Prix en FCFA au format XOF.
String formatXof(int amount) {
  return '${amount.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (m) => ' ',
  )} FCFA';
}

ThemeData buildAngeValenciaTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.orange,
      onPrimary: Colors.white,
      secondary: AppColors.orangeDark,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.beigeLight,
      onSurface: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.beige,
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.beige,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AppColors.beigeLight,
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.orangeDark,
        side: const BorderSide(color: AppColors.orangeDark),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.beigeLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.beigeDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.beigeDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.orange, width: 2),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.black,
      indicatorColor: AppColors.orange,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: Colors.white, fontSize: 12),
      ),
    ),
  );
}