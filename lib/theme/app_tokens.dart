import 'package:flutter/material.dart';

abstract final class AppColors {
  static const brand = Color(0xFF087A52);
  static const brandDark = Color(0xFF075D41);
  static const brandSoft = Color(0xFFDDF3E9);
  static const canvas = Color(0xFFF7F8F5);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF0F3EF);
  static const outline = Color(0xFFDCE2DD);
  static const text = Color(0xFF17201B);
  static const textMuted = Color(0xFF667169);
  static const danger = Color(0xFFC64132);
  static const dangerSoft = Color(0xFFFBE9E6);
  static const warning = Color(0xFFAD7200);
  static const warningSoft = Color(0xFFFFF2D6);
  static const info = Color(0xFF256BC4);
  static const infoSoft = Color(0xFFE4EFFD);
}

abstract final class AppSpacing {
  static const x1 = 8.0;
  static const x2 = 16.0;
  static const x3 = 24.0;
  static const x4 = 32.0;
}

abstract final class AppRadius {
  static const small = 12.0;
  static const medium = 16.0;
  static const large = 24.0;
}
