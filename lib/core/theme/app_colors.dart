import 'package:flutter/material.dart';

class AppColors {
  // ===== Primary Brand Colors =====
  static const primary = Color(0xFF00D9FF); // Neon Cyan — اللون الأساسي
  static const primaryDark = Color(0xFF00B8D9); // Darker Cyan
  static const primaryGlow = Color(0x3300D9FF); // Glow effect (20% opacity)

  // ===== Accent Colors =====
  static const accentPurple = Color(0xFF7C3AED); // Electric Purple
  static const accentIndigo = Color(0xFF4F46E5); // Indigo
  static const accentOrange = Color(0xFFF97316); // Vivid Orange
  static const accentGreen = Color(0xFF22C55E); // Vivid Green
  static const accentRed = Color(0xFFEF4444); // Vivid Red

  // ===== Background System (Ultra Dark) =====
  static const backgroundDark = Color(0xFF060D1A); // Almost Black Navy
  static const backgroundMid = Color(0xFF0A1628); // Deep Navy
  static const backgroundLight = Color(0xFF0F1F38); // Slightly lighter Navy

  // ===== Surface System (Glassmorphism) =====
  static const surfaceDark = Color(0xFF111E35); // Card Background
  static const surfaceMid = Color(0xFF1A2B47); // Elevated surface
  static const surfaceGlass = Color(0x1AFFFFFF); // Glass overlay (10%)
  static const surfaceGlassBorder = Color(0x26FFFFFF); // Glass border (15%)

  // ===== Status Colors =====
  static const success = Color(0xFF10B981); // Emerald Green
  static const successGlow = Color(0x2010B981); // Success glow
  static const warning = Color(0xFFF59E0B); // Amber
  static const warningGlow = Color(0x20F59E0B); // Warning glow
  static const error = Color(0xFFEF4444); // Red
  static const errorGlow = Color(0x20EF4444); // Error glow
  static const info = Color(0xFF3B82F6); // Blue

  // ===== Text Colors =====
  static const textPrimary = Color(0xFFE2E8F0); // Near White
  static const textSecondary = Color(0xFF94A3B8); // Slate 400
  static const textMuted = Color(0xFF475569); // Slate 600
  static const textLight = Color(0xFFFFFFFF); // Pure White

  // ===== Border Colors =====
  static const border = Color(0xFF1E3A5F); // Dark Border
  static const borderLight = Color(0xFF2D4A6E); // Lighter Border
  static const borderGlow = Color(0x4000D9FF); // Glowing border

  // ===== Gradient Pairs =====
  static const gradientPrimary = [Color(0xFF00D9FF), Color(0xFF0066CC)];
  static const gradientSuccess = [Color(0xFF10B981), Color(0xFF059669)];
  static const gradientWarning = [Color(0xFFF59E0B), Color(0xFFD97706)];
  static const gradientError = [Color(0xFFEF4444), Color(0xFFDC2626)];
  static const gradientPurple = [Color(0xFF7C3AED), Color(0xFF5B21B6)];
  static const gradientDark = [Color(0xFF111E35), Color(0xFF060D1A)];
  static const gradientCard = [Color(0xFF1A2B47), Color(0xFF111E35)];

  // ===== Legacy Aliases (backward compat) =====
  static const background = backgroundDark;
  static const surface = surfaceDark;
  static const cardColor = surfaceMid;
  static const loginBackground = backgroundDark;
  static const loginBackgroundLight = backgroundMid;
  static const loginGold = Color(0xFFD4AF37);
  static const loginGoldLight = Color(0xFFE5C158);
  static const loginBlue = Color(0xFF1E3A5F);
  static const loginBlueLight = Color(0xFF2A4A6F);
  static const purpleGradient = [Color(0xFF6366F1), Color(0xFF4F46E5)];
  static const orangeGradient = [Color(0xFFF59E0B), Color(0xFFD97706)];
  static const greenGradient = [Color(0xFF22C55E), Color(0xFF16A34A)];

  // ===== Workflow Status Colors =====
  static Color statusColor(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'ASSIGNED':
        return warning;
      case 'ACCEPTED':
        return info;
      case 'RECEIVING':
        return accentPurple;
      case 'RECEIVED':
        return success;
      case 'PARTIALLY_RECEIVED':
        return Color(0xFF06B6D4);
      case 'ON_ROUTE':
        return Color(0xFF14B8A6);
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
