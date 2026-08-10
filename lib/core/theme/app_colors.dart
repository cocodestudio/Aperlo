import 'package:flutter/material.dart';

abstract final class AppColors {
  // Background layer
  static const background = Color(0xFFF5F7F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceRaised = Color(0xFFEEF1EE);
  static const surfaceMuted = Color(0xFFE7EBE7);

  // Borders
  static const borderSubtle = Color(0xFFDCE0DC);
  static const borderDefault = Color(0xFFC8CEC8);
  static const borderStrong = Color(0xFFA0A8A0);

  // Text / Ink
  static const inkPrimary = Color(0xFF141A14);
  static const inkSecondary = Color(0xFF475247);
  static const inkMuted = Color(0xFF7D877D);
  static const inkDisabled = Color(0xFFB0B8B0);

  // Accent — deep forest green
  static const accent = Color(0xFF1A6B4A);
  static const accentHover = Color(0xFF145A3D);
  static const accentTint = Color(0xFFE8F3ED);
  static const accentOn = Color(0xFFFFFFFF);

  // Semantic
  static const destructive = Color(0xFFC0392B);
  static const destructiveTint = Color(0xFFFDECEA);
  static const warning = Color(0xFFA0660A);
  static const warningTint = Color(0xFFFDF3E3);
}
