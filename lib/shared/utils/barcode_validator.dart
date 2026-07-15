import 'package:get/get.dart';
import '../models/item_type.dart';
import '../../features/dashboard/presentation/controllers/dashboard_controller.dart';
import '../../features/received_devices/presentation/controllers/devices_controller.dart';

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

  /// Normalizes raw barcode (trims, uppercases, removes prefix headers and separators)
  static String normalizeRawBarcode(String rawBarcode) {
    String cleaned = rawBarcode.trim().toUpperCase();
    cleaned = cleaned.replaceFirst(RegExp(r'^(SN|S/N|HW|SERIAL|BARCODE)[:\-\s]*', caseSensitive: false), '');
    // GS1 symbology identifiers sometimes prepended by hardware scanners
    cleaned = cleaned.replaceFirst(RegExp(r'^\]?(C1)'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[\s\-_.]'), '');
    return cleaned;
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

  /// Full serial for UI + save: keep alphabetic prefixes (e.g. NCC303042220).
  /// If only digits were entered for a device type, prepend the primary letter prefix.
  static String toDisplaySerial(String rawBarcode, ItemType? itemType) {
    final cleaned = normalizeRawBarcode(rawBarcode);
    if (itemType == null) return cleaned;

    final prefixes = _prefixesOf(itemType);
    final alphaPrefixes =
        prefixes.where((p) => RegExp(r'^[A-Z]+$').hasMatch(p)).toList();

    for (final prefix in alphaPrefixes) {
      if (cleaned.startsWith(prefix)) return cleaned;
    }

    // Digits-only matching clean length → show with primary prefix (NCC…)
    final clean = extractCleanSerialForType(cleaned, itemType);
    if (alphaPrefixes.isNotEmpty &&
        itemType.serialLength != null &&
        clean.length == itemType.serialLength &&
        RegExp(r'^\d+$').hasMatch(cleaned)) {
      return '${alphaPrefixes.first}$clean';
    }

    return cleaned;
  }

  /// True when two serials refer to the same item (prefixed or stripped).
  static bool serialsMatch(String a, String b, ItemType? itemType) {
    final da = toDisplaySerial(a, itemType);
    final db = toDisplaySerial(b, itemType);
    if (da == db) return true;
    return extractCleanSerialForType(a, itemType) ==
        extractCleanSerialForType(b, itemType);
  }

  /// Extracts the clean serial number based on item type prefix configuration
  static String extractCleanSerialForType(String rawBarcode, ItemType? itemType) {
    if (itemType == null) return normalizeRawBarcode(rawBarcode);
    final cleaned = normalizeRawBarcode(rawBarcode);
    if (itemType.serialPrefix == null || itemType.serialPrefix!.isEmpty) {
      return cleaned;
    }
    
    final prefixes = _prefixesOf(itemType);
        
    for (final prefix in prefixes) {
      if (cleaned.startsWith(prefix)) {
        // If prefix is alphabetic, strip it. If numeric, do not strip.
        final isAlphabetic = RegExp(r'^[A-Z]+$').hasMatch(prefix);
        if (isAlphabetic) {
          return cleaned.substring(prefix.length);
        }
      }
    }
    return cleaned;
  }

  /// Validates a serial number/barcode against a specific ItemType.
  /// Returns null if valid, or a descriptive error message in Arabic if invalid.
  static String? validate(String serial, ItemType? itemType) {
    if (itemType == null) return null;
    final normalized = normalizeRawBarcode(serial);
    
    // Check if the itemType has a prefix restriction
    if (itemType.serialPrefix != null && itemType.serialPrefix!.isNotEmpty) {
      final prefixes = itemType.serialPrefix!
          .split(',')
          .map((p) => p.trim().toUpperCase())
          .toList();
      
      bool matched = false;
      for (final prefix in prefixes) {
        if (normalized.startsWith(prefix)) {
          matched = true;
          break;
        }
      }
      if (!matched) {
        final isAlreadyClean = itemType.serialLength != null && 
                               normalized.length == itemType.serialLength;
        if (!isAlreadyClean) {
          return 'الرمز لا يبدأ بأي من البوادئ المعتمدة: ${itemType.serialPrefix}';
        }
      }
    }

    // Extract clean serial
    final cleanSerial = extractCleanSerialForType(serial, itemType);

    // Validate length of clean serial
    if (itemType.serialLength != null && itemType.serialLength! > 0) {
      if (cleanSerial.length != itemType.serialLength) {
        return 'يجب أن يكون طول الرقم التسلسلي النظيف ${itemType.serialLength} خانات (الحالي: ${cleanSerial.length})';
      }
    }

    // Validate regex (against the raw normalized barcode since the regex patterns usually include the prefix)
    if (itemType.serialRegex != null && itemType.serialRegex!.isNotEmpty) {
      try {
        final regex = RegExp(itemType.serialRegex!);
        bool isMatch = regex.hasMatch(normalized);
        
        // Fallback: If not matched and it is already clean (length matches target length), try prepending prefixes
        if (!isMatch && itemType.serialLength != null && normalized.length == itemType.serialLength) {
          if (itemType.serialPrefix != null && itemType.serialPrefix!.isNotEmpty) {
            final prefixes = itemType.serialPrefix!
                .split(',')
                .map((p) => p.trim().toUpperCase())
                .where((p) => RegExp(r'^[A-Z]+$').hasMatch(p))
                .toList();
            for (final prefix in prefixes) {
              if (regex.hasMatch('$prefix$normalized')) {
                isMatch = true;
                break;
              }
            }
          }
        }
        
        if (!isMatch) {
          return 'صيغة الرقم التسلسلي غير مطابقة للمواصفات المعتمدة لـ ${itemType.nameAr}';
        }
      } catch (e) {
        // Fallback if regex is invalid
      }
    }

    // Extra category safeguards:
    if (itemType.category == 'devices' && normalized.startsWith('89966')) {
      return 'تم مسح شريحة بدلاً من جهاز. الأجهزة لا تبدأ بـ 89966';
    }
    if (itemType.category == 'sim' && !normalized.startsWith('89966')) {
      return 'رقم الشريحة (ICCID) يجب أن يبدأ بـ 89966';
    }

    return null;
  }

  /// Validates a serial number generally for any device type.
  /// Returns null if valid, or a descriptive error message in Arabic if invalid.
  static String? validateAnyDevice(String serial) {
    final normalized = normalizeRawBarcode(serial);
    if (normalized.startsWith('89966')) {
      return 'تم مسح شريحة بدلاً من جهاز. أجهزة POS لا تبدأ بـ 89966';
    }
    
    // Check dynamically against active itemTypes
    final activeTypes = _getActiveItemTypes();
    final deviceTypes = activeTypes.where((t) => t.category == 'devices').toList();
    
    for (final type in deviceTypes) {
      if (validate(normalized, type) == null) {
        return null;
      }
    }

    // Fallback for general custom device models (e.g. A960)
    if (normalized.length >= 5 && normalized.length <= 30) {
      return null;
    }
    
    return 'الرقم التسلسلي غير مطابق لمواصفات الأجهزة المعتمدة';
  }

  /// Validates a serial number generally for any SIM card type.
  /// Returns null if valid, or a descriptive error message in Arabic if invalid.
  static String? validateAnySim(String serial) {
    final normalized = normalizeRawBarcode(serial);
    if (!normalized.startsWith('89966')) {
      return 'رقم الشريحة (ICCID) يجب أن يبدأ بـ 89966';
    }

    final activeTypes = _getActiveItemTypes();
    final simTypes = activeTypes.where((t) => t.category == 'sim').toList();
    for (final type in simTypes) {
      if (validate(normalized, type) == null) {
        return null;
      }
    }
    
    if (normalized.length != 18 && normalized.length != 19) {
      return 'رقم الشريحة يجب أن يكون 18 أو 19 خانة ويبدأ بـ 89966 (الحالي: ${normalized.length} خانة)';
    }
    return null;
  }
}
