import 'package:flutter/material.dart';

/// RASSCO brand colors — StockPro Enterprise (UI only).
class AppColors {
  // ===== Primary Brand Colors =====
  static const primary = Color(0xFF18B2B0);
  static const primaryDark = Color(0xFF149D9B);
  static const primaryGlow = Color(0x3318B2B0);

  // ===== Accent (mapped to brand; no purple) =====
  static const accentPurple = Color(0xFF18B2B0);
  static const accentIndigo = Color(0xFF5F6368);
  static const accentOrange = Color(0xFFF4B740);
  static const accentGreen = Color(0xFF18B2B0);
  static const accentRed = Color(0xFFE05252);

  // ===== Background System (RASSCO dark mode) =====
  static const backgroundDark = Color(0xFF1F2328);
  static const backgroundMid = Color(0xFF2A2F36);
  static const backgroundLight = Color(0xFF343A42);

  // ===== Surface System =====
  static const surfaceDark = Color(0xFF2A2F36);
  static const surfaceMid = Color(0xFF343A42);
  static const surfaceGlass = Color(0x1AFFFFFF);
  static const surfaceGlassBorder = Color(0x26FFFFFF);

  // ===== Status Colors =====
  static const success = Color(0xFF18B2B0);
  static const successGlow = Color(0x2018B2B0);
  static const warning = Color(0xFFF4B740);
  static const warningGlow = Color(0x20F4B740);
  static const error = Color(0xFFE05252);
  static const errorGlow = Color(0x20E05252);
  static const info = Color(0xFF18B2B0);

  // ===== Text Colors =====
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B5BB);
  static const textMuted = Color(0xFF7C838B);
  static const textLight = Color(0xFFFFFFFF);

  // ===== Border Colors =====
  static const border = Color(0xFF3A4048);
  static const borderLight = Color(0xFF4A515A);
  static const borderGlow = Color(0x4018B2B0);

  // ===== Gradient Pairs =====
  static const gradientPrimary = [Color(0xFF18B2B0), Color(0xFF149D9B)];
  static const gradientSuccess = [Color(0xFF18B2B0), Color(0xFF149D9B)];
  static const gradientWarning = [Color(0xFFF4B740), Color(0xFFE0A020)];
  static const gradientError = [Color(0xFFE05252), Color(0xFFC43D3D)];
  static const gradientPurple = [Color(0xFF18B2B0), Color(0xFF5F6368)];
  static const gradientDark = [Color(0xFF2A2F36), Color(0xFF1F2328)];
  static const gradientCard = [Color(0xFF343A42), Color(0xFF2A2F36)];

  // ===== Legacy Aliases (backward compat) =====
  static const background = backgroundDark;
  static const surface = surfaceDark;
  static const cardColor = surfaceMid;
  static const loginBackground = backgroundDark;
  static const loginBackgroundLight = backgroundMid;
  static const loginGold = Color(0xFFF4B740);
  static const loginGoldLight = Color(0xFFF7C96A);
  static const loginBlue = Color(0xFF5F6368);
  static const loginBlueLight = Color(0xFF7C838B);
  static const purpleGradient = [Color(0xFF18B2B0), Color(0xFF149D9B)];
  static const orangeGradient = [Color(0xFFF4B740), Color(0xFFE0A020)];
  static const greenGradient = [Color(0xFF18B2B0), Color(0xFF149D9B)];

  // Light surfaces (for mixed enterprise screens)
  static const lightBg = Color(0xFFF7F8FA);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF2D3135);
  static const brandGray = Color(0xFF5F6368);

  // ===== Workflow Status Colors =====
  static Color statusColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'ASSIGNED':
        return warning;
      case 'ACCEPTED':
        return info;
      case 'RECEIVING':
        return primary;
      case 'RECEIVED':
        return success;
      case 'PARTIALLY_RECEIVED':
        return primary;
      case 'ON_ROUTE':
        return primary;
      case 'ARRIVED':
        return accentOrange;
      case 'INSTALLING':
        return info;
      case 'REJECTED':
        return error;
      case 'COMPLETED':
        return success;
      default:
        return textMuted;
    }
  }
}
