import '../models/item_type.dart';
import '../utils/barcode_validator.dart';

/// Result of resolving a scanned code against a set of candidate item
/// types. Exactly one of three shapes:
/// - [resolved] non-null, [ambiguousCandidates] empty: a single, unambiguous
///   match (either the already-selected type validated it directly, or
///   exactly one candidate in the category did).
/// - [resolved] null, [ambiguousCandidates].length > 1: more than one
///   candidate validated the same code (e.g. a 19-digit ICCID that matches
///   both Zain's and Mobily's item types, since neither's serial pattern
///   can tell the two apart) — the caller must ask the user, never guess.
/// - [resolved] null, [ambiguousCandidates] empty: no candidate validated
///   the code at all (existing "not a recognized serial" error case).
class ScanTypeResolution {
  final ItemType? resolved;
  final List<ItemType> ambiguousCandidates;

  const ScanTypeResolution._(this.resolved, this.ambiguousCandidates);

  factory ScanTypeResolution.resolved(ItemType type) =>
      ScanTypeResolution._(type, const []);

  factory ScanTypeResolution.ambiguous(List<ItemType> candidates) =>
      ScanTypeResolution._(null, candidates);

  factory ScanTypeResolution.none() => const ScanTypeResolution._(null, []);

  bool get isResolved => resolved != null;
  bool get isAmbiguous => ambiguousCandidates.length > 1;
  bool get isNone => resolved == null && ambiguousCandidates.isEmpty;
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

  /// [selectedType] is tried first and wins outright if it validates the
  /// code — this is the "already inside a specific section" case, and it
  /// deliberately never falls through to the ambiguity check below even if
  /// other candidates would also validate; a technician who opened the
  /// Zain section scanning a Zain ICCID must never be asked to disambiguate.
  ///
  /// [candidates] should already be filtered by the caller to the relevant
  /// category, active, AND visible item types only (a hidden/deprecated
  /// type — e.g. the old `zainSim` row — must never be offered or chosen).
  static ScanTypeResolution resolve({
    required String normalizedCode,
    required List<ItemType> candidates,
    ItemType? selectedType,
  }) {
    if (selectedType != null &&
        BarcodeValidator.validate(normalizedCode, selectedType) == null) {
      return ScanTypeResolution.resolved(selectedType);
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
