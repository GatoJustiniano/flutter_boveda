import 'package:material_ui/material_ui.dart';

class AppTheme {
  static const Color primaryDark = Color(0xFF1A1A2E);
  static const Color secondaryDark = Color(0xFF16213E);
  static const Color cardDark = Color(0xFF1E2A3A);
  static const Color accentBlue = Color(0xFF4FC3F7);
  static const Color accentTeal = Color(0xFF26C6DA);
  static const Color accentGreen = Color(0xFF66BB6A);
  static const Color accentOrange = Color(0xFFFFB74D);
  static const Color accentPurple = Color(0xFFAB47BC);
  static const Color accentRed = Color(0xFFEF5350);
  static const Color textPrimary = Color(0xFFECEFF1);
  static const Color textSecondary = Color(0xFF90A4AE);
  static const Color dividerColor = Color(0xFF2A3A4A);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      primaryColor: accentBlue,
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        secondary: accentTeal,
        surface: cardDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: secondaryDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentBlue,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondaryDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: const TextStyle(color: textSecondary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: secondaryDark,
        contentTextStyle: const TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static const List<Color> categoryColors = [
    accentBlue,
    accentTeal,
    accentGreen,
    accentOrange,
    accentPurple,
    accentRed,
  ];

  static Color getCategoryColor(int index) {
    return categoryColors[index % categoryColors.length];
  }

  static const List<IconData> categoryIcons = [
    Icons.bolt_rounded,
    Icons.water_drop_rounded,
    Icons.phone_android_rounded,
    Icons.wifi_rounded,
    Icons.tv_rounded,
    Icons.credit_card_rounded,
    Icons.subscriptions_rounded,
    Icons.shopping_bag_rounded,
    Icons.cloud_rounded,
    Icons.music_note_rounded,
    Icons.games_rounded,
    Icons.school_rounded,
    Icons.local_hospital_rounded,
    Icons.home_rounded,
    Icons.directions_car_rounded,
    Icons.attach_money_rounded,
  ];
}
