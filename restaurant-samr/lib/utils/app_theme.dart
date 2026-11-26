





import 'package:flutter/material.dart';

class AppThemes {
  static const Color _seedColor = Color(0xFF69C0FF);
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ).surfaceContainer,
      elevation: 0,
      scrolledUnderElevation: 2,
      titleTextStyle: TextStyle(
        color: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ).onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      iconTheme: IconThemeData(
        color: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ).onSurfaceVariant,
      ),
    ),
    cardTheme: CardThemeData(
      // Corrected to CardThemeData
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ).surfaceContainerHighest,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ).primary,
        foregroundColor: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ).onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ).primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ).primary,
        side: BorderSide(
          color: ColorScheme.fromSeed(
            seedColor: _seedColor,
            brightness: Brightness.light,
          ).outline,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: ColorScheme.fromSeed(
            seedColor: _seedColor,
            brightness: Brightness.light,
          ).outline,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: ColorScheme.fromSeed(
            seedColor: _seedColor,
            brightness: Brightness.light,
          ).primary,
          width: 2.0,
        ),
      ),
      filled: true,
      fillColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ).surfaceContainerHighest.withValues(alpha: 0.5),
      hintStyle: TextStyle(
        color: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ).onSurfaceVariant.withValues(alpha: 0.7),
      ),
      prefixIconColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ).onSurfaceVariant,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ).primaryContainer,
      foregroundColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ).onPrimaryContainer,
      elevation: 2,
    ),
    dialogTheme: DialogThemeData(
      // Corrected to DialogThemeData
      backgroundColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ).surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      titleTextStyle: TextStyle(
        color: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ).onSurface,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ).onSurfaceVariant,
      ),
    ),
    listTileTheme: ListTileThemeData(
      selectedColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ).primary,
      selectedTileColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ).primaryContainer.withValues(alpha: 0.3),
      iconColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ).secondary,
    ),
    dividerTheme: DividerThemeData(
      color: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ).outlineVariant.withValues(alpha: 0.5),
      thickness: 1,
    ),
    fontFamily: 'Roboto', // Or your preferred font
  );
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ).surfaceContainer,
      elevation: 0,
      scrolledUnderElevation: 2,
      titleTextStyle: TextStyle(
        color: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ).onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      iconTheme: IconThemeData(
        color: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ).onSurfaceVariant,
      ),
    ),
    cardTheme: CardThemeData(
      // Corrected to CardThemeData
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ).surfaceContainerHigh,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ).primary,
        foregroundColor: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ).onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ).primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ).primary,
        side: BorderSide(
          color: ColorScheme.fromSeed(
            seedColor: _seedColor,
            brightness: Brightness.dark,
          ).outline,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: ColorScheme.fromSeed(
            seedColor: _seedColor,
            brightness: Brightness.dark,
          ).outline,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(
          color: ColorScheme.fromSeed(
            seedColor: _seedColor,
            brightness: Brightness.dark,
          ).primary,
          width: 2.0,
        ),
      ),
      filled: true,
      fillColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ).surfaceContainerHigh.withValues(alpha: 0.5),
      hintStyle: TextStyle(
        color: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ).onSurfaceVariant.withValues(alpha: 0.7),
      ),
      prefixIconColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ).onSurfaceVariant,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ).primaryContainer,
      foregroundColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ).onPrimaryContainer,
      elevation: 2,
    ),
    dialogTheme: DialogThemeData(
      // Corrected to DialogThemeData
      backgroundColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ).surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      titleTextStyle: TextStyle(
        color: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ).onSurface,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ).onSurfaceVariant,
      ),
    ),
    listTileTheme: ListTileThemeData(
      selectedColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ).primary,
      selectedTileColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ).primaryContainer.withValues(alpha: 0.3),
      iconColor: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ).secondary,
    ),
    dividerTheme: DividerThemeData(
      color: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.dark,
      ).outlineVariant.withValues(alpha: 0.5),
      thickness: 1,
    ),
    fontFamily: 'Roboto', // Or your preferred font
  );
}