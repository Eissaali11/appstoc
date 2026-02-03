import 'package:flutter/material.dart';

/// Utility class to map icon names to Material Icons
class IconMapper {
  static final Map<String, IconData> _iconMap = {
    // Devices
    'smartphone': Icons.smartphone,
    'phone': Icons.phone_android,
    'device': Icons.devices,
    'tablet': Icons.tablet,
    'terminal': Icons.point_of_sale,

    // Accessories
    'battery': Icons.battery_charging_full,
    'charger': Icons.power,
    'cable': Icons.cable,
    'head': Icons.power_input,

    // SIM Cards
    'sim': Icons.sim_card,
    'simcard': Icons.sim_card,
    'mobile': Icons.sim_card,
    'stc': Icons.sim_card,
    'zain': Icons.sim_card,
    'mobily': Icons.sim_card,

    // Paper & Labels
    'paper': Icons.description,
    'roll': Icons.description,
    'label': Icons.label,
    'sticker': Icons.label_outline,
    'tag': Icons.local_offer,

    // Inventory
    'inventory': Icons.inventory_2,
    'box': Icons.inventory,
    'package': Icons.inventory_2_outlined,
    'warehouse': Icons.warehouse,

    // Shipping
    'shipping': Icons.local_shipping,
    'delivery': Icons.delivery_dining,
    'truck': Icons.local_shipping,

    // Default
    'default': Icons.inventory_2,
    'unknown': Icons.help_outline,
  };

  /// Get icon data from icon name
  /// Returns a default icon if name is not found
  static IconData getIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) {
      return _iconMap['default']!;
    }

    // Convert to lowercase and remove spaces
    final normalizedName = iconName.toLowerCase().trim().replaceAll(' ', '_');

    // Try exact match
    if (_iconMap.containsKey(normalizedName)) {
      return _iconMap[normalizedName]!;
    }

    // Try partial match
    for (var entry in _iconMap.entries) {
      if (normalizedName.contains(entry.key) ||
          entry.key.contains(normalizedName)) {
        return entry.value;
      }
    }

    // Return default if no match found
    return _iconMap['default']!;
  }

  /// Get icon based on item type name (Arabic or English)
  static IconData getIconFromItemName(String? nameAr, String? nameEn) {
    if (nameAr == null && nameEn == null) {
      return _iconMap['default']!;
    }

    final searchText = '${nameAr ?? ''} ${nameEn ?? ''}'.toLowerCase();

    // Check for common keywords
    if (searchText.contains('جهاز') ||
        searchText.contains('device') ||
        searchText.contains('terminal') ||
        searchText.contains('n950') ||
        searchText.contains('i9000') ||
        searchText.contains('i9100')) {
      return Icons.smartphone;
    }

    if (searchText.contains('شريحة') ||
        searchText.contains('sim') ||
        searchText.contains('stc') ||
        searchText.contains('زين') ||
        searchText.contains('موبايلي')) {
      return Icons.sim_card;
    }

    if (searchText.contains('ورق') ||
        searchText.contains('paper') ||
        searchText.contains('رول') ||
        searchText.contains('roll')) {
      return Icons.description;
    }

    if (searchText.contains('ملصق') ||
        searchText.contains('label') ||
        searchText.contains('sticker') ||
        searchText.contains('tag')) {
      return Icons.label;
    }

    if (searchText.contains('بطارية') || searchText.contains('battery')) {
      return Icons.battery_charging_full;
    }

    if (searchText.contains('شاحن') || searchText.contains('charger')) {
      return Icons.power;
    }

    return _iconMap['default']!;
  }
}
