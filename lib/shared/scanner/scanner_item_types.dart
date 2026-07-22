import 'package:get/get.dart';

import '../../features/dashboard/presentation/controllers/dashboard_controller.dart';
import '../../features/received_devices/presentation/controllers/devices_controller.dart';
import '../models/item_type.dart';
import 'barcode_rule_registry.dart';

/// Resolves active [ItemType]s for camera scan screens (Dashboard → Devices).
class ScannerItemTypes {
  ScannerItemTypes._();

  static List<ItemType> all() {
    try {
      if (Get.isRegistered<DashboardController>()) {
        final map = Get.find<DashboardController>().itemTypesMap;
        if (map.isNotEmpty) return map.values.toList();
      }
    } catch (_) {}
    try {
      if (Get.isRegistered<DevicesController>()) {
        final list = Get.find<DevicesController>().itemTypes;
        if (list.isNotEmpty) return list;
      }
    } catch (_) {}
    return const [];
  }

  static List<ItemType> devices() {
    final list = all()
        .where((t) => (t.category ?? '').toLowerCase() == 'devices')
        .toList();
    if (list.isNotEmpty) return list;
    return serialTracked()
        .where((t) => (t.category ?? '').toLowerCase() == 'devices')
        .toList();
  }

  static List<ItemType> sims() {
    final list =
        all().where((t) => (t.category ?? '').toLowerCase() == 'sim').toList();
    if (list.isNotEmpty) return list;
    return serialTracked()
        .where((t) => (t.category ?? '').toLowerCase() == 'sim')
        .toList();
  }

  /// Serial-tracked types only (devices + sims with resolvable rules preferred).
  static List<ItemType> serialTracked() {
    final list = all()
        .where((t) =>
            t.requiresSerial == true ||
            (t.category ?? '') == 'devices' ||
            (t.category ?? '') == 'sim')
        .toList();
    if (list.isNotEmpty) return list;
    // Offline / cold start: synthesize from enterprise fallback table.
    return [
      for (final r in BarcodeRuleRegistry.fallbackRules)
        ItemType(
          id: r.id,
          nameEn: r.label,
          nameAr: r.label,
          sortOrder: 0,
          isActive: true,
          isVisible: true,
          category: r.id.startsWith('sim') ? 'sim' : 'devices',
          requiresSerial: true,
          serialPrefix: r.prefixes.join(','),
          serialLength: r.fullLength,
          serialRegex: r.regex.pattern,
        ),
    ];
  }

  static List<ItemType> forRole(String role) {
    final r = role.trim().toLowerCase();
    if (r == 'sim' || r == 'sim_card') return sims().isNotEmpty ? sims() : serialTracked().where((t) => t.category == 'sim').toList();
    if (r == 'device' || r == 'pos' || r == 'devices') {
      return devices().isNotEmpty
          ? devices()
          : serialTracked().where((t) => t.category == 'devices').toList();
    }
    return serialTracked();
  }
}
