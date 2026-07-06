import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_shapes.dart';
import 'app_typography.dart';

class AppTheme {
  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryS,
          onPrimary: AppColors.primaryT,
          error: AppColors.dangerS,
          onError: AppColors.dangerT,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
        ),
        textTheme: GoogleFonts.nunitoTextTheme().copyWith(
          displayLarge:   AppTypography.displayLarge,
          headlineMedium: AppTypography.headlineMedium,
          titleMedium:    AppTypography.titleMedium,
          bodyLarge:      AppTypography.bodyLarge,
          bodyMedium:     AppTypography.bodyMedium,
          labelLarge:     AppTypography.labelLarge,
          labelSmall:     AppTypography.labelSmall,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppShapes.radiusFull),
            ),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryS,
          iconTheme: WidgetStateProperty.resolveWith(
            (states) => IconThemeData(
              color: states.contains(WidgetState.selected) ? AppColors.primaryT : AppColors.inkSoft,
            ),
          ),
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => AppTypography.labelSmall.copyWith(
              color: states.contains(WidgetState.selected) ? AppColors.primaryT : AppColors.inkSoft,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppShapes.radiusMedium),
            borderSide: const BorderSide(color: AppColors.outline, width: AppShapes.borderRegular),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppShapes.radiusMedium),
            borderSide: const BorderSide(color: AppColors.outline, width: AppShapes.borderRegular),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppShapes.radiusMedium),
            borderSide: const BorderSide(color: AppColors.primaryB, width: AppShapes.borderEmphasis),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );
}
