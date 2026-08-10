import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppText {
  // Display — Syne 800, 32sp
  static TextStyle display({Color color = AppColors.inkPrimary}) =>
      TextStyle(fontFamily: 'Syne', fontSize: 32, fontWeight: FontWeight.w800, color: color, height: 1.15, letterSpacing: -0.5);

  // Headline 1 — Syne 700, 24sp
  static TextStyle headline1({Color color = AppColors.inkPrimary}) =>
      TextStyle(fontFamily: 'Syne', fontSize: 24, fontWeight: FontWeight.w700, color: color, height: 1.2, letterSpacing: -0.3);

  // Headline 2 — Syne 700, 20sp
  static TextStyle headline2({Color color = AppColors.inkPrimary}) =>
      TextStyle(fontFamily: 'Syne', fontSize: 20, fontWeight: FontWeight.w700, color: color, height: 1.25, letterSpacing: -0.2);

  // Headline 3 — Syne 700, 17sp
  static TextStyle headline3({Color color = AppColors.inkPrimary}) =>
      TextStyle(fontFamily: 'Syne', fontSize: 17, fontWeight: FontWeight.w700, color: color, height: 1.3);

  // Body Large — DM Sans 400, 16sp
  static TextStyle bodyLarge({Color color = AppColors.inkSecondary}) =>
      TextStyle(fontFamily: 'DMSans', fontSize: 16, fontWeight: FontWeight.w400, color: color, height: 1.55);

  // Body Default — DM Sans 400, 14sp
  static TextStyle bodyDefault({Color color = AppColors.inkSecondary}) =>
      TextStyle(fontFamily: 'DMSans', fontSize: 14, fontWeight: FontWeight.w400, color: color, height: 1.55);

  // Body Small — DM Sans 400, 13sp
  static TextStyle bodySmall({Color color = AppColors.inkMuted}) =>
      TextStyle(fontFamily: 'DMSans', fontSize: 13, fontWeight: FontWeight.w400, color: color, height: 1.5);

  // Label Large — DM Sans 600, 14sp
  static TextStyle labelLarge({Color color = AppColors.inkPrimary}) =>
      TextStyle(fontFamily: 'DMSans', fontSize: 14, fontWeight: FontWeight.w600, color: color, height: 1.2, letterSpacing: 0.1);

  // Label Default — DM Sans 500, 13sp
  static TextStyle labelDefault({Color color = AppColors.inkSecondary}) =>
      TextStyle(fontFamily: 'DMSans', fontSize: 13, fontWeight: FontWeight.w500, color: color, height: 1.2, letterSpacing: 0.1);

  // Label Small — DM Sans 500, 11sp
  static TextStyle labelSmall({Color color = AppColors.inkMuted}) =>
      TextStyle(fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w500, color: color, height: 1.2, letterSpacing: 0.3);

  // Mono — Syne Mono 400, 12sp
  static TextStyle mono({Color color = AppColors.inkMuted}) =>
      TextStyle(fontFamily: 'SyneMono', fontSize: 12, fontWeight: FontWeight.w400, color: color, height: 1.4);
}
