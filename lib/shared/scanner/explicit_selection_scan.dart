import '../models/item_type.dart';
import '../utils/barcode_validator.dart';

/// Core rule of the shipment-scan flow (final, user-confirmed):
///
///   * An EXPLICIT dropdown selection is final for `itemTypeId`. A scanned
///     serial is validated ONLY against the selected type's own rule. On
///     failure the scan is rejected with an error naming the selected type —
///     no other type is searched, suggested, or substituted.
///   * With NO explicit selection (the auto-defaulted first item in the list
///     does NOT count) the scan is BLOCKED and the technician is asked to pick
///     a type. Nothing is saved.
///   * `itemTypeId` therefore always comes from the selected type — never from
///     a resolver, a regex-candidate search, a carrier name, or a keyword.
///     (Carrier labels are derived separately and can never change it; see
///     [carrierLabelForItemType].)
///
/// This file has no UI and no GetX/Dio dependency so the exact same code path
/// serves manual entry and the camera/multi-scan batch, and is unit-testable.

/// Shown (in the page's existing error area) when a scan is attempted without
/// an explicit type selection.
const String kExplicitSelectionRequiredMessage =
    'اختر نوع الصنف من القائمة أولاً قبل المسح أو الإدخال — النوع الأول '
    'المعروض تلقائياً لا يُعتبر اختياراً. لم يتم حفظ أي شيء.';

/// Error naming the selected type when the scanned number does not satisfy
/// that type's own validation rule (or the rule is missing/incomplete).
String selectedTypeRejectedMessage(ItemType selected) =>
    'الرقم لا يطابق قاعدة التحقق الخاصة بالنوع المحدد "${selected.nameAr}". '
    'تأكد من الرقم، أو إن كانت قاعدة التحقق لهذا النوع غير مكتملة في '
    'النظام تواصل مع الإدارة — لن يتم البحث عن نوع آخر ولن يتم حفظ الرقم.';

enum ScanOutcomeKind { accepted, blockedNoExplicitSelection, rejectedBySelectedType }

class ScanOutcome {
  final ScanOutcomeKind kind;

  /// Set only when [kind] is [ScanOutcomeKind.accepted]: always the explicitly
  /// selected type itself.
  final ItemType? type;

  /// Serial exactly as it should be displayed AND sent (set when accepted).
  final String? displaySerial;

  /// User-facing message (set when not accepted).
  final String? error;

  const ScanOutcome._(this.kind, this.type, this.displaySerial, this.error);

  factory ScanOutcome.accepted(ItemType type, String displaySerial) =>
      ScanOutcome._(ScanOutcomeKind.accepted, type, displaySerial, null);

  factory ScanOutcome.blocked() => const ScanOutcome._(
        ScanOutcomeKind.blockedNoExplicitSelection,
        null,
        null,
        kExplicitSelectionRequiredMessage,
      );

  factory ScanOutcome.rejected(ItemType selected) => ScanOutcome._(
        ScanOutcomeKind.rejectedBySelectedType,
        null,
        null,
        selectedTypeRejectedMessage(selected),
      );

  bool get isAccepted => kind == ScanOutcomeKind.accepted;
}

/// The explicitly selected type, or null when the current dropdown value is
/// only the auto-defaulted first item (or nothing/unknown id).
ItemType? explicitSelectedType({
  required List<ItemType> types,
  required String? selectedItemTypeId,
  required bool explicitlySelected,
}) {
  if (!explicitlySelected || selectedItemTypeId == null) return null;
  for (final t in types) {
    if (t.id == selectedItemTypeId) return t;
  }
  return null;
}

/// Whether the technician's selection counts as explicit after the scanner
/// screen returns. Set only if the id the scanner returned differs from the
/// pre-scan value; an unchanged echo of an auto-default stays non-explicit,
/// and an already-explicit selection is never downgraded.
bool explicitAfterScannerReturn({
  required String? idBeforeScan,
  required String? returnedId,
  required bool currentlyExplicit,
}) {
  if (currentlyExplicit) return true;
  return returnedId != null && returnedId != idBeforeScan;
}

/// THE shared classification path for one scanned/typed code — used verbatim
/// by manual entry and by every code of a camera/multi-scan batch, so both
/// produce the identical validation result, `itemTypeId` and sent serial.
ScanOutcome classifyScan({
  required String rawCode,
  required ItemType? explicitSelected,
}) {
  if (explicitSelected == null) return ScanOutcome.blocked();

  final normalized = BarcodeValidator.normalizeRawBarcode(rawCode);
  if (BarcodeValidator.validate(normalized, explicitSelected) != null) {
    return ScanOutcome.rejected(explicitSelected);
  }
  final display = BarcodeValidator.toDisplaySerial(normalized, explicitSelected);
  if (BarcodeValidator.validate(display, explicitSelected) != null) {
    return ScanOutcome.rejected(explicitSelected);
  }
  return ScanOutcome.accepted(explicitSelected, display);
}

class BatchScanResult {
  final int added;
  final String? firstError;
  const BatchScanResult(this.added, this.firstError);
}

/// Multi-scan (camera) batch: each code goes through [classifyScan]
/// independently against the one explicit selection. No dialog, no
/// multi-candidate resolution. Without an explicit selection the whole batch
/// is blocked (nothing added). Every accepted item carries its own type id.
BatchScanResult processScanBatch({
  required List<String> codes,
  required ItemType? explicitSelected,
  required bool Function(String displaySerial, ItemType type) isDuplicate,
  required void Function(ItemType type, String displaySerial) onAccepted,
}) {
  if (explicitSelected == null) {
    return const BatchScanResult(0, kExplicitSelectionRequiredMessage);
  }

  var added = 0;
  String? firstError;
  for (final code in codes) {
    if (code.trim().isEmpty) continue;
    final outcome = classifyScan(rawCode: code, explicitSelected: explicitSelected);
    if (!outcome.isAccepted) {
      firstError ??= outcome.error;
      continue;
    }
    if (isDuplicate(outcome.displaySerial!, outcome.type!)) continue;
    onAccepted(outcome.type!, outcome.displaySerial!);
    added++;
  }
  return BatchScanResult(added, firstError);
}
