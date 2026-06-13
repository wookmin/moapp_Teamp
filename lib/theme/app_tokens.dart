import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── 브랜드 (프레시 그린) ──
  static const brand = Color(0xFF059669);
  static const brandDark = Color(0xFF047857);
  static const brandSoft = Color(0xFFECFDF5);

  // ── 배경 ──
  static const canvas = Color(0xFFF4F5F7);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF4F5F7);

  // ── 테두리 ──
  static const outline = Color(0xFFE5E8EB);

  // ── 텍스트 ──
  static const text = Color(0xFF191F28);
  static const textMuted = Color(0xFF8B95A1);

  // ── 시맨틱 ──
  static const danger = Color(0xFFF04452);
  static const dangerSoft = Color(0xFFFFEBEE);
  static const warning = Color(0xFFFF8800);
  static const warningSoft = Color(0xFFFFF3E0);
  static const success = Color(0xFF059669);
  static const successSoft = Color(0xFFECFDF5);
  static const info = Color(0xFF3182F6);
  static const infoSoft = Color(0xFFE8F3FF);
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