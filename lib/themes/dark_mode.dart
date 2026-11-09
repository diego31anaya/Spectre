import 'package:flutter/material.dart';

final ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    surface: Color(0xFF0A0D0A),
    primary: Color(0xFFB9FF4A),
    onPrimary: Color(0xFF17210A),
    secondary: Color(0xFF9BD444),
    tertiary: Color(0xFF75826E),
    onSurface: Color(0xFFF1F4EB),
    outline: Color(0xFF2B3529),
    inversePrimary: Color(0xFF17210A),
  ),
  scaffoldBackgroundColor: const Color(0xFF0A0D0A),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFF0A0D0A),
    foregroundColor: Color(0xFFB9FF4A),
    elevation: 0,
    titleTextStyle: TextStyle(
      fontFamily: 'VT323',
      fontSize: 32,
      letterSpacing: 2,
      color: Color(0xFFB9FF4A),
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFF0A0D0A),
    selectedItemColor: Color(0xFFB9FF4A),
    unselectedItemColor: Color(0xFF75826E),
  ),
);
