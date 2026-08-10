import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const double r2 = 2;
  static const double r6 = 6;
  static const double r10 = 10;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double full = 9999;

  static BorderRadius br2 = BorderRadius.circular(r2);
  static BorderRadius br6 = BorderRadius.circular(r6);
  static BorderRadius br10 = BorderRadius.circular(r10);
  static BorderRadius br12 = BorderRadius.circular(r12);
  static BorderRadius br16 = BorderRadius.circular(r16);
  static BorderRadius br20 = BorderRadius.circular(r20);
  static BorderRadius brFull = BorderRadius.circular(full);

  // Bottom sheet: radius only on top corners
  static const bottomSheet = BorderRadius.vertical(top: Radius.circular(r16));
}
