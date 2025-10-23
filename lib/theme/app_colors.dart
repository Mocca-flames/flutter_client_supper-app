// app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Updated with OKLCH color palette
  static const Color primaryColor = Color.fromARGB(
    255,
    197,
    127,
    47,
  ); // oklch(0.4 0.1 60)
  static const Color secondaryColor = Color(0xFF5A6C8A); // oklch(0.4 0.1 240)
  static const Color accentColor = Color(
    0xFF8C8A5C,
  ); // oklch(0.5 0.05 100) - using warning

  // Background colors
  static const Color backgroundColor = Color(0xFFF5F5F5); // oklch(0.96 0 60)
  static const Color surfaceColor = Color(0xFFFFFFFF); // oklch(1 0 60)
  static const Color errorColor = Color(0xFF8C6D5C); // oklch(0.5 0.05 30)

  // Text colors
  static const Color textColorPrimary = Color(0xFF262626); // oklch(0.15 0 60)
  static const Color textColorSecondary = Color(0xFF666666); // oklch(0.4 0 60)
  static const Color onPrimaryColor = Color(0xFFFFFFFF); // oklch(1 0 60)
  static const Color onSecondaryColor = Color(0xFFFFFFFF); // oklch(1 0 60)
  static const Color onBackgroundColor = Color(0xFF262626); // oklch(0.15 0 60)
  static const Color onSurfaceColor = Color(0xFF262626); // oklch(0.15 0 60)
  static const Color onErrorColor = Color(0xFFFFFFFF); // oklch(1 0 60)

  // Component colors
  static const Color appBarColor = Color(0xFF5A6C8A); // oklch(0.4 0.1 60)
  static const Color buttonColor = Color(0xFF5A6C8A); // oklch(0.4 0.1 60)
  static const Color iconColor = Color(0xFF5A6C8A); // oklch(0.4 0.1 60)

  // Additional accent colors
  static const Color successColor = Color(0xFF5C8C7A); // oklch(0.5 0.05 160)
  static const Color warningColor = Color(0xFF8C8A5C); // oklch(0.5 0.05 100)

  // Additional colors from your OKLCH palette
  static const Color bgDark = Color(0xFFEBEBEB); // oklch(0.92 0 60)
  static const Color bgLight = Color(0xFFFFFFFF); // oklch(1 0 60)
  static const Color highlight = Color(0xFFFFFFFF); // oklch(1 0 60)
  static const Color border = Color(0xFF999999); // oklch(0.6 0 60)
  static const Color borderMuted = Color(0xFFB3B3B3); // oklch(0.7 0 60)
  static const Color info = Color(0xFF5C7A8C); // oklch(0.5 0.05 260)
  static const Color danger = Color(0xFF8C6D5C); // oklch(0.5 0.05 30)
}
