import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart'; // Assuming app_colors.dart is in the same directory

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      primaryColor: AppColors.primaryColor,
      scaffoldBackgroundColor: AppColors.backgroundColor,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryColor,
        secondary: AppColors.secondaryColor,
        surface: AppColors.surfaceColor,
        error: AppColors.errorColor,
        onPrimary: AppColors.onPrimaryColor,
        onSecondary: AppColors.onSecondaryColor,
        onSurface: AppColors.onSurfaceColor,
        onError: AppColors.onErrorColor,
      ),
      appBarTheme: AppBarTheme(
        color: AppColors.appBarColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onPrimaryColor),
        titleTextStyle: const TextStyle(
          color: AppColors.onPrimaryColor,
          fontSize: 22.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
          statusBarBrightness: Brightness.light, // For iOS (dark icons)
        ),
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: AppColors.buttonColor,
        textTheme: ButtonTextTheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.onPrimaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondaryColor,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceColor.withValues(alpha: 0.1),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 16.0,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: AppColors.primaryColor, width: 2.5),
        ),
        labelStyle: TextStyle(color: AppColors.textColorSecondary),
        hintStyle: TextStyle(color: AppColors.textColorSecondary),
      ),
      textTheme: GoogleFonts.robotoTextTheme(
        TextTheme(
          displayLarge: TextStyle(
            fontSize: 34.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textColorPrimary,
          ),
          displayMedium: TextStyle(
            fontSize: 30.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textColorPrimary,
          ),
          displaySmall: TextStyle(
            fontSize: 26.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textColorPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textColorPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textColorPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w700,
            color: AppColors.textColorPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 18.0,
            color: AppColors.textColorPrimary,
            height: 1.4,
          ),
          bodyMedium: TextStyle(
            fontSize: 16.0,
            color: AppColors.textColorSecondary,
            height: 1.4,
          ),
          labelLarge: TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
            color: AppColors.onPrimaryColor,
          ),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.iconColor),
      cardTheme: CardThemeData(
        elevation: 4.0,
        margin: const EdgeInsets.all(12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        color: AppColors.surfaceColor,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceColor,
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: AppColors.onSurfaceColor.withValues(alpha: 0.60),
        selectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        showUnselectedLabels: true,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.secondaryColor,
        foregroundColor: AppColors.onSecondaryColor,
      ),
    );
  }

  // If you want a dark theme in the future, you can define it here
  // static ThemeData get darkTheme { ... }
}
