import 'package:get/get.dart';
import '../models/item_type.dart';
import '../scanner/barcode_rule_registry.dart';
import '../scanner/scanner_context.dart';
import '../../features/dashboard/presentation/controllers/dashboard_controller.dart';
import '../../features/received_devices/presentation/controllers/devices_controller.dart';
import 'barcode_validation_engine.dart';

/// Facade over [BarcodeValidationEngine] + dynamic ItemType rules from API.
/// Device serials are opaque — alphabetic prefixes are identity, never stripped on accept.
class BarcodeValidator {
  static List<ItemType> _getActiveItemTypes() {
    try {
      if (Get.isRegistered<DashboardController>()) {
        return Get.find<DashboardController>().itemTypesMap.values.toList();
      }
    } catch (_) {}
    try {
      if (Get.isRegistered<DevicesController>()) {
        return Get.find<DevicesController>().itemTypes;
      }
    } catch (_) {}
    return [];
  }

  /// Normalizes raw barcode (trims, uppercases, removes newlines).
  /// Does NOT strip NCD/NCC/SAW/SAS identity prefixes.
  static String normalizeRawBarcode(String rawBarcode) {
    return BarcodeValidationEngine.normalize(rawBarcode);
  }

  static List<String> _prefixesOf(ItemType itemType) {
    if (itemType.serialPrefix == null || itemType.serialPrefix!.isEmpty) {
      return const [];
    }
    return itemType.serialPrefix!
        .split(',')
        .map((p) => p.trim().toUpperCase())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  /// Full opaque serial for UI + save. NEVER auto-prepends NCD/NCC to bare digits.
  static String toDisplaySerial(String rawBarcode, ItemType? itemType) {
    final cleaned = normalizeRawBarcode(rawBarcode);
    if (itemType == null) return cleaned;

    final prefixes = _prefixesOf(itemType);
    final alphaPrefixes =
        prefixes.where((p) => RegExp(r'^[A-Z]+$').hasMatch(p)).toList();

    for (final prefix in alphaPrefixes) {
      if (cleaned.startsWith(prefix)) return cleaned;
    }

    // Bare digits: return cleaned as-is — caller must reject via validate()
    return cleaned;
  }

  /// True when two serials refer to the same item (prefixed or legacy stripped).
  static bool serialsMatch(String a, String b, ItemType? itemType) {
    final da = toDisplaySerial(a, itemType);
    final db = toDisplaySerial(b, itemType);
    if (da == db) return true;
    return extractCleanSerialForType(a, itemType) ==
        extractCleanSerialForType(b, itemType);
  }

  /// Body-only form for legacy comparison / SEARCH — NOT for storage.
  static String extractCleanSerialForType(String rawBarcode, ItemType? itemType) {
    if (itemType == null) return normalizeRawBarcode(rawBarcode);
    final cleaned = normalizeRawBarcode(rawBarcode);
    if (itemType.serialPrefix == null || itemType.serialPrefix!.isEmpty) {
      return cleaned;
    }

    final prefixes = _prefixesOf(itemType);

    for (final prefix in prefixes) {
      if (cleaned.startsWith(prefix)) {
        final isAlphabetic = RegExp(r'^[A-Z]+$').hasMatch(prefix);
        if (isAlphabetic) {
          return cleaned.substring(prefix.length);
        }
      }
    }
    return cleaned;
  }

  /// Validates a serial against a specific ItemType via Smart Scanner V2 engine.
  /// Returns null if valid, or Arabic error if invalid.
  /// Bare digits for alphabetic-prefix types → REJECT (no auto-prepend).
  static String? validate(String serial, ItemType? itemType) {
    if (itemType == null) return null;
    final normalized = normalizeRawBarcode(serial);
    if (normalized.isEmpty) return 'الرقم التسلسلي فارغ';

    // Cache API types so UUID ids resolve via fromItemType name match.
    BarcodeRuleRegistry.cacheFromItemTypes([itemType]);

    final ctx = ScannerContext.create(
      sessionId: 'manual_validate',
      itemType: itemType,
      itemTypeId: itemType.id,
    );

    final engine = BarcodeValidationEngine.validate(normalized, context: ctx);
    if (engine.isValid) return null;

    final rule = ctx.trustedRule ??
        (ctx.trustedRules.isNotEmpty ? ctx.trustedRules.first : null);

    if (rule == null) {
      return 'لا توجد قاعدة تحقق معتمدة لهذا النوع — اختر نوع الصنف أولاً';
    }

    if (!rule.prefixes.any(normalized.startsWith)) {
      final isAlpha = rule.prefixes.any((p) => RegExp(r'^[A-Z]+$').hasMatch(p));
      if (isAlpha) {
        return 'الرمز مرفوض: يجب أن يبدأ بأحد البوادئ المعتمدة (${rule.prefixes.join(" / ")}) — لا يُقبل الرقم بدون بادئة';
      }
      return 'الرمز لا يبدأ بأي من البوادئ المعتمدة: ${rule.prefixes.join(",")}';
    }

    if (normalized.length != rule.fullLength) {
      return 'يجب أن يكون طول الرقم التسلسلي الكامل ${rule.fullLength} خانات (الحالي: ${normalized.length})';
    }

    if (itemType.category == 'devices' && normalized.startsWith('89966')) {
      return 'تم مسح شريحة بدلاً من جهاز. الأجهزة لا تبدأ بـ 89966';
    }
    if (itemType.category == 'sim' && !normalized.startsWith('89966')) {
      return 'رقم الشريحة (ICCID) يجب أن يبدأ بـ 89966';
    }

    return 'صيغة الرقم التسلسلي غير مطابقة للمواصفات المعتمدة لـ ${itemType.nameAr}';
  }

  /// Validates a serial number generally for any device type.
  static String? validateAnyDevice(String serial) {
    final normalized = normalizeRawBarcode(serial);
    if (normalized.startsWith('89966')) {
      return 'تم مسح شريحة بدلاً من جهاز. أجهزة POS لا تبدأ بـ 89966';
    }

    final deviceTypes =
        _getActiveItemTypes().where((t) => t.category == 'devices').toList();
    if (deviceTypes.isNotEmpty) {
      BarcodeRuleRegistry.cacheFromItemTypes(deviceTypes);
    }

    final ctx = ScannerContext.create(
      sessionId: 'any_device',
      allowedItemTypes: deviceTypes.isNotEmpty ? deviceTypes : null,
      categoryHint: 'devices',
      allowFallbackRegistry: true,
    );

    final engine = BarcodeValidationEngine.validate(normalized, context: ctx);
    if (engine.isValid) return null;

    // Fail closed — no loose alphanumeric accept (GTIN/PN must not pass).
    return 'الرقم التسلسلي غير مطابق لمواصفات الأجهزة المعتمدة';
  }

  /// Validates a serial number generally for any SIM card type.
  static String? validateAnySim(String serial) {
    final normalized = normalizeRawBarcode(serial);
    if (!normalized.startsWith('89966')) {
      return 'رقم الشريحة (ICCID) يجب أن يبدأ بـ 89966';
    }

    final simTypes =
        _getActiveItemTypes().where((t) => t.category == 'sim').toList();
    if (simTypes.isNotEmpty) {
      BarcodeRuleRegistry.cacheFromItemTypes(simTypes);
    }

    final ctx = ScannerContext.create(
      sessionId: 'any_sim',
      allowedItemTypes: simTypes.isNotEmpty ? simTypes : null,
      categoryHint: 'sim',
      allowFallbackRegistry: true,
    );

    final engine = BarcodeValidationEngine.validate(normalized, context: ctx);
    if (engine.isValid) return null;

    if (normalized.length != 18 && normalized.length != 19) {
      return 'رقم الشريحة يجب أن يكون 18 أو 19 خانة ويبدأ بـ 89966 (الحالي: ${normalized.length} خانة)';
    }
    return 'رقم الشريحة غير مطابق لمواصفات الشرائح المعتمدة';
  }
}
