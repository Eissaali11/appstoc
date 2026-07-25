import 'package:flutter/material.dart';

/// RASSCO brand colors — StockPro ERP Enterprise Light System.
class AppColors {
  // ===== Corporate Brand Colors =====
  static const primary = Color(0xFF00A896);       // Corporate Turquoise
  static const primaryDark = Color(0xFF028090);   // Deep Turquoise
  static const primaryLight = Color(0xFFE6F7F5);  // Light Turquoise Surface
  static const primaryGlow = Color(0x2000A896);

  static const secondaryBlue = Color(0xFF2563EB); // Primary Blue
  static const secondaryBlueLight = Color(0xFFEFF6FF);

  // ===== Accent System =====
  static const accentPurple = Color(0xFF00A896);
  static const accentIndigo = Color(0xFF4F46E5);
  static const accentOrange = Color(0xFFF59E0B); // Warning Orange
  static const accentGreen = Color(0xFF10B981);  // Success Green
  static const accentRed = Color(0xFFEF4444);    // Danger Red

  // ===== Background System (Enterprise Light Architecture) =====
  static const backgroundLight = Color(0xFFF8FAFC); // Very Light Gray Page Background
  static const backgroundMid = Color(0xFFF1F5F9);   // Surface Light Gray
  static const backgroundDark = Color(0xFFF8FAFC);  // Mapped to Light for enterprise mode

  // ===== Card & Surface System =====
  static const surfaceLight = Color(0xFFFFFFFF);    // Pure White Card
  static const surfaceDark = Color(0xFFFFFFFF);     // Mapped to White Card
  static const surfaceMid = Color(0xFFF8FAFC);
  static const surfaceGlass = Color(0xFFFFFFFF);
  static const surfaceGlassBorder = Color(0xFFE2E8F0); // Very light gray border

  // ===== Status Colors =====
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFECFDF5);
  static const successGlow = Color(0x1A10B981);

  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFFFEF3);
  static const warningGlow = Color(0x1AF59E0B);

  static const error = Color(0xFFEF4444);
  static const errorLight = Color(0xFFFFF2F2);
  static const errorGlow = Color(0x1AEF4444);

  static const info = Color(0xFF2563EB);
  static const infoLight = Color(0xFFEFF6FF);

  // ===== Text Colors =====
  static const textPrimary = Color(0xFF0F172A);    // Dark slate body / titles
  static const textSecondary = Color(0xFF475569);  // Medium slate
  static const textMuted = Color(0xFF94A3B8);      // Muted caption
  static const textLight = Color(0xFFFFFFFF);      // On-dark text

  // ===== Border & Divider Colors =====
  static const border = Color(0xFFE2E8F0);         // Subtle Light Border
  static const borderLight = Color(0xFFF1F5F9);    // Soft Border
  static const borderGlow = Color(0x3300A896);

  // ===== Gradient Pairs =====
  static const gradientPrimary = [Color(0xFF00A896), Color(0xFF028090)];
  static const gradientSuccess = [Color(0xFF10B981), Color(0xFF059669)];
  static const gradientWarning = [Color(0xFFF59E0B), Color(0xFFD97706)];
  static const gradientError = [Color(0xFFEF4444), Color(0xFFDC2626)];
  static const gradientPurple = [Color(0xFF00A896), Color(0xFF2563EB)];
  static const gradientDark = [Color(0xFFFFFFFF), Color(0xFFF8FAFC)];
  static const gradientCard = [Color(0xFFFFFFFF), Color(0xFFFFFFFF)];

  // ===== Backward Compatibility Aliases =====
  static const background = backgroundLight;
  static const surface = surfaceLight;
  static const cardColor = surfaceLight;
  static const loginBackground = backgroundLight;
  static const loginBackgroundLight = backgroundMid;
  static const loginGold = Color(0xFFF59E0B);
  static const loginGoldLight = Color(0xFFFCD34D);
  static const loginBlue = Color(0xFF2563EB);
  static const loginBlueLight = Color(0xFF60A5FA);
  static const purpleGradient = gradientPrimary;
  static const orangeGradient = gradientWarning;
  static const greenGradient = gradientSuccess;

  // Enterprise UI Badges & Backgrounds
  static const lightBg = Color(0xFFF8FAFC);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightText = Color(0xFF0F172A);
  static const brandGray = Color(0xFF64748B);

  // ===== Workflow Status Colors =====
  static Color statusColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'PENDING':
      case 'ASSIGNED':
        return warning;
      case 'ACCEPTED':
      case 'COMPLETED':
      case 'RECEIVED':
        return success;
      case 'REJECTED':
      case 'CANCELLED':
        return error;
      case 'IN_PROGRESS':
      case 'RECEIVING':
      case 'PARTIALLY_RECEIVED':
      case 'ON_ROUTE':
      case 'INSTALLING':
        return secondaryBlue;
      default:
        return textMuted;
    }
  }

  static Color statusBgColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'PENDING':
      case 'ASSIGNED':
        return warningLight;
      case 'ACCEPTED':
      case 'COMPLETED':
      case 'RECEIVED':
        return successLight;
      case 'REJECTED':
      case 'CANCELLED':
        return errorLight;
      case 'IN_PROGRESS':
      case 'RECEIVING':
      case 'PARTIALLY_RECEIVED':
      case 'ON_ROUTE':
      case 'INSTALLING':
        return secondaryBlueLight;
      default:
        return backgroundMid;
    }
  }
}

