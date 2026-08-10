import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_radius.dart';

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'DMSans',
    scaffoldBackgroundColor: AppColors.background,
    // Prevents the dark-gray flash seen behind page transitions
    canvasColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary: AppColors.accent,
      onPrimary: AppColors.accentOn,
      surface: AppColors.surface,
      onSurface: AppColors.inkPrimary,
      outline: AppColors.borderDefault,
      error: AppColors.destructive,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
      ),
      iconTheme: IconThemeData(color: AppColors.inkPrimary),
      titleTextStyle: TextStyle(fontFamily: 'Syne', 
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: AppColors.inkPrimary,
      ),
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.accentOn,
        minimumSize: const Size(120, 48),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.br12),
        textStyle: TextStyle(fontFamily: 'DMSans', fontSize: 14, fontWeight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.inkPrimary,
        minimumSize: const Size(120, 48),
        side: const BorderSide(color: AppColors.borderDefault, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.br12),
        textStyle: TextStyle(fontFamily: 'DMSans', fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accent,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        textStyle: TextStyle(fontFamily: 'DMSans', fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      border: OutlineInputBorder(
        borderRadius: AppRadius.br10,
        borderSide: const BorderSide(color: AppColors.borderDefault, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.br10,
        borderSide: const BorderSide(color: AppColors.borderDefault, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.br10,
        borderSide: const BorderSide(color: AppColors.accent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.br10,
        borderSide: const BorderSide(color: AppColors.destructive, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.br10,
        borderSide: const BorderSide(color: AppColors.destructive, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(fontFamily: 'DMSans', fontSize: 15, color: AppColors.inkDisabled),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderSubtle,
      thickness: 1,
      space: 0,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r16)),
      ),
      elevation: 0,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.br16),
      titleTextStyle: TextStyle(fontFamily: 'Syne', 
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.inkPrimary,
      ),
      contentTextStyle: TextStyle(fontFamily: 'DMSans', 
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.inkSecondary,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.transparent,
      selectedColor: AppColors.accentTint,
      side: const BorderSide(color: AppColors.borderDefault),
      labelStyle: TextStyle(fontFamily: 'DMSans', fontSize: 13, fontWeight: FontWeight.w500),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
  );
}
