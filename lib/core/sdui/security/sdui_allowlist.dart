import 'package:flutter/material.dart';

class SduiAllowlist {
  // Allowlisted Icon Mapping
  static const Map<String, IconData> _allowedIcons = {
    'inventory_2_outlined': Icons.inventory_2_outlined,
    'check_circle_outline': Icons.check_circle_outline,
    'pending_actions_rounded': Icons.pending_actions_rounded,
    'swap_horiz_rounded': Icons.swap_horiz_rounded,
    'filter_list_rounded': Icons.filter_list_rounded,
    'list_alt_rounded': Icons.list_alt_rounded,
    'devices_rounded': Icons.devices_rounded,
    'sim_card_rounded': Icons.sim_card_rounded,
    'archive_outlined': Icons.archive_outlined,
    'history_rounded': Icons.history_rounded,
  };

  // Safe Fallback Icon
  static const IconData defaultIcon = Icons.tune_rounded;

  // Safe Fallback Color (#18B2B0)
  static const Color defaultColor = Color(0xFF18B2B0);

  /// Resolves icon string from allowlist; returns defaultIcon if unknown.
  static IconData resolveIcon(String? iconName) {
    if (iconName == null) return defaultIcon;
    return _allowedIcons[iconName.trim()] ?? defaultIcon;
  }

  /// Parses and validates hex color string (#RRGGBB); returns defaultColor if invalid.
  static Color resolveColor(String? hexString) {
    if (hexString == null) return defaultColor;
    final clean = hexString.trim();
    final regExp = RegExp(r'^#[0-9A-Fa-f]{6}$');
    if (!regExp.hasMatch(clean)) return defaultColor;

    try {
      final colorInt = int.parse(clean.substring(1), radix: 16);
      return Color(0xFF000000 | colorInt);
    } catch (_) {
      return defaultColor;
    }
  }

  /// Validates status strings against allowable inventory statuses.
  static List<String> sanitizeStatuses(List<String>? statuses) {
    if (statuses == null) return const [];
    const allowedStatuses = {
      'UNDER_ACTION',
      'PENDING_VERIFICATION',
      'DELIVERED',
      'PROCESSING',
      'RETURNED',
      'LOST',
    };
    return statuses
        .where((s) => allowedStatuses.contains(s.trim().toUpperCase()))
        .toList();
  }
}
