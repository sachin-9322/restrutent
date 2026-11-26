import 'package:flutter/material.dart';

class AppThemes {
  static const Color _seedColor = Color(0xFF69C0FF);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.light),
    brightness: Brightness.light,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark),
    brightness: Brightness.dark,
  );
}
