import 'package:flutter/material.dart';

/// Light Material 3 theme used on every screen.
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF0B7A75);
  static const Color accent = Color(0xFFFF7A45);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light).copyWith(secondary: accent, surface: Colors.white);
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF6F8F8),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFFF6F8F8),
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade500),
        errorMaxLines: 2,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: Colors.white,
        indicatorColor: scheme.primaryContainer,
        labelTextStyle: WidgetStatePropertyAll(base.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      dividerTheme: DividerThemeData(color: Colors.grey.shade200, space: 1),
    );
  }
}
