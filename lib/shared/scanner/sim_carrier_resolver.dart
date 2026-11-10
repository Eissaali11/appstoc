import '../models/item_type.dart';
import '../utils/barcode_validator.dart';

/// Result of resolving a scanned code against a set of candidate item
/// types. Exactly one of four shapes:
/// - [resolved] non-null: a single, unambiguous match (either the
///   already-selected type validated it directly, or exactly one candidate
///   in the category did, when there was no prior selection).
/// - [ambiguousCandidates].length > 1: more than one candidate validated
///   the same code (e.g. a 19-digit ICCID that matches both Zain's and
///   Mobily's item types) — the caller must ask the user, never guess.
///   This can ONLY happen when there was no prior explicit selection; see
///   [rejectedSelectedType] for the pre-selected equivalent.
/// - [rejectedSelectedType] non-null: a type WAS explicitly selected
///   before scanning, but the code does not validate against that type's
///   own rule. The selection is authoritative and is never second-guessed
///   by checking other candidates — this is a dead end the caller must
///   report specifically (e.g. "the selected type's validation rule is
///   missing or doesn't match"), not a disambiguation opportunity.
/// - all null/empty: no candidate validated the code at all, and no type
///   had been pre-selected (existing "not a recognized serial" case).
class ScanTypeResolution {
  final ItemType? resolved;
  final List<ItemType> ambiguousCandidates;
  final ItemType? rejectedSelectedType;

  const ScanTypeResolution._(
      this.resolved, this.ambiguousCandidates, this.rejectedSelectedType);

  factory ScanTypeResolution.resolved(ItemType type) =>
      ScanTypeResolution._(type, const [], null);

  factory ScanTypeResolution.ambiguous(List<ItemType> candidates) =>
      ScanTypeResolution._(null, candidates, null);

  factory ScanTypeResolution.none() =>
      const ScanTypeResolution._(null, [], null);

  factory ScanTypeResolution.selectedTypeRejected(ItemType selectedType) =>
      ScanTypeResolution._(null, const [], selectedType);

  bool get isResolved => resolved != null;
  bool get isAmbiguous => ambiguousCandidates.length > 1;
  bool get isSelectedTypeRejected => rejectedSelectedType != null;
  bool get isNone =>
      resolved == null &&
      ambiguousCandidates.isEmpty &&
      rejectedSelectedType == null;
}

/// Text shown in the carrier dropdown when no carrier value exists. Display
/// only — in that state nothing is sent to the server (see
/// [carrierLabelForItemType]: unknown carrier → `null` → omitted).
const String kCarrierNotSpecifiedLabel = 'غير محدد';

/// The backend `carrierName` LABEL to send alongside a SIM item — derived
/// only from the selected type's own catalog name, or from a carrier the
/// technician explicitly chose ([explicitCarrier]). It has NO influence on
/// `itemTypeId` (classification is decided elsewhere and is never touched by
/// this).
///
/// Returns `null` when neither source yields a carrier — it NEVER invents a
/// default like "STC". An unknown carrier label is omitted from the request
/// rather than silently mislabeled; a SIM whose carrier is genuinely
/// unknown must not be recorded as belonging to the carrier that happens to
/// sort first in a hardcoded list.
String? carrierLabelForItemType(ItemType type, String? explicitCarrier) {
  if (type.category != 'sim') return null;
  final nameEn = type.nameEn.toLowerCase();
  final nameAr = type.nameAr.toLowerCase();
  if (nameEn.contains('stc') ||
      nameAr.contains('stc') ||
      nameEn.contains('اتصالات') ||
      nameAr.contains('اتصالات')) {
    return 'STC';
  }
  if (nameEn.contains('mobily') || nameAr.contains('موبايلي')) {
    return 'Mobily';
  }
  if (nameEn.contains('zain') || nameAr.contains('زين')) {
    return 'Zain';
  }
  if (nameEn.contains('lebara') ||
      nameAr.contains('ليبارا') ||
      nameEn.contains('repara') ||
      nameAr.contains('ريباره') ||
      nameAr.contains('ريبارا')) {
    return 'Lebara';
  }
  return explicitCarrier;
}

/// Decides which [ItemType] a scanned/typed code belongs to, WITHOUT ever
/// guessing between two-or-more equally-valid candidates (e.g. Zain vs
/// Mobily vs Lebara vs Repara, which all share the same 19-digit ICCID
/// shape and cannot be told apart from the digits alone).
///
/// `sort_order` is deliberately never consulted here — it is a display/
/// ordering concern only, not a classification signal. See
/// `shipment_scan_page.dart`'s scan handler for how the ambiguous case is
/// surfaced to the user (a one-time carrier-selection prompt, remembered
/// for the rest of that scan session only).
class SimCarrierResolver {
  SimCarrierResolver._();

  /// [selectedType] — when the technician has already explicitly picked a
  /// type (e.g. the shipment-scan dropdown, BEFORE scanning) — is
  /// authoritative and is validated against ONLY ITS OWN rule. It is never
  /// re-evaluated against [candidates]: on success it wins outright, on
  /// failure the result is [ScanTypeResolution.selectedTypeRejected], never
  /// a fall-through to the general candidate pool. An explicit prior choice
  /// must never be silently overridden or replaced by a different type —
  /// not even when another candidate in [candidates] would have validated
  /// the same code. [candidates] is only consulted at all when
  /// [selectedType] is null.
  ///
  /// [candidates] should already be filtered by the caller to the relevant
  /// category, active, AND visible item types only (a hidden/deprecated
  /// type — e.g. the old `zainSim` row — must never be offered or chosen).
  static ScanTypeResolution resolve({
    required String normalizedCode,
    required List<ItemType> candidates,
    ItemType? selectedType,
  }) {
    if (selectedType != null) {
      if (BarcodeValidator.validate(normalizedCode, selectedType) == null) {
        return ScanTypeResolution.resolved(selectedType);
      }
      return ScanTypeResolution.selectedTypeRejected(selectedType);
    }

    final valid = <ItemType>[];
    for (final type in candidates) {
      if (BarcodeValidator.validate(normalizedCode, type) == null) {
        valid.add(type);
      }
    }

    if (valid.isEmpty) return ScanTypeResolution.none();
    if (valid.length == 1) return ScanTypeResolution.resolved(valid.first);
    return ScanTypeResolution.ambiguous(valid);
  }
}
