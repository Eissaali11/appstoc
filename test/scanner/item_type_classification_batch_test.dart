import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/shared/models/item_type.dart';
import 'package:nuolipapp/shared/scanner/sim_carrier_resolver.dart';

/// Resolver-level regression tests for [SimCarrierResolver].
///
/// SCOPE NOTE (updated after the final "explicit selection is mandatory"
/// decision): `shipment_scan_page.dart` NO LONGER uses this resolver — its
/// `itemTypeId` comes only from the explicit dropdown selection, validated
/// against that type's own rule (see `explicit_selection_scan.dart` and
/// `explicit_selection_integration_test.dart`; no ambiguity dialog exists
/// any more). This resolver is still used by flows that have NO dropdown —
/// `dashboard_controller.dart`'s `addSerialToCustody` quick-add — where an
/// ambiguous or unknown code is rejected with a snackbar rather than
/// guessed. These tests keep proving that no-dropdown behavior (never a
/// silent first-match pick), and the "explicit selection wins outright"
/// case documents the resolver's own contract for any caller that does pass
/// a selection.
///
/// Historic root cause (still the reason the resolver never guesses): the
/// camera multi-scan handler used to "iterate this category's types, first
/// one whose validation passes wins" — a silent guess whenever more than
/// one item type validated the same code.
void main() {
  // Two illustrative SIM catalog types, named plainly as "Z" and "SCC" to
  // match the mandatory acceptance scenario literally, sharing the exact
  // same underlying serial shape (as real production SIM families do —
  // see sim_carrier_resolver_test.dart for the real mobily/zain/stc rows)
  // so pattern-matching alone genuinely cannot tell them apart.
  // NOTE: serialLength MUST be set alongside serialPrefix/serialRegex —
  // BarcodeRuleRegistry.fromItemType() fails closed (returns no rule at
  // all) when any of the three API-config fields is missing, UNLESS the
  // type's id/name happens to contain a recognized enterprise keyword
  // (zain/mobily/stc/...), which "Z"/"SCC" deliberately do not, to match
  // the mandatory acceptance scenario's arbitrary catalog codes literally.
  ItemType simZ() => ItemType(
        id: 'sim-type-z',
        nameEn: 'SIM Z',
        nameAr: 'شريحة Z',
        sortOrder: 1,
        isActive: true,
        isVisible: true,
        category: 'sim',
        requiresSerial: true,
        serialPrefix: '89966',
        serialLength: 19,
        serialRegex: r'^89966[0-9]{14}$',
      );

  ItemType simScc() => ItemType(
        id: 'sim-type-scc',
        nameEn: 'SIM SCC',
        nameAr: 'شريحة SCC',
        sortOrder: 2,
        isActive: true,
        isVisible: true,
        category: 'sim',
        requiresSerial: true,
        serialPrefix: '89966',
        serialLength: 19,
        serialRegex: r'^89966[0-9]{14}$',
      );

  ItemType hiddenSimLegacy() => ItemType(
        id: 'sim-type-legacy',
        nameEn: 'SIM Legacy (deprecated)',
        nameAr: 'شريحة قديمة',
        sortOrder: 3,
        isActive: true,
        isVisible: false,
        category: 'sim',
        requiresSerial: true,
        serialPrefix: '89966',
        serialLength: 19,
        serialRegex: r'^89966[0-9]{14}$',
      );

  ItemType deviceN950() => ItemType(
        id: 'n950',
        nameEn: 'N950',
        nameAr: 'N950',
        sortOrder: 10,
        isActive: true,
        isVisible: true,
        category: 'devices',
        requiresSerial: true,
        serialPrefix: 'NCC,NCD',
        serialLength: 12,
        serialRegex: r'^(NCD|NCC)[A-Z0-9]{9}$',
      );

  const ambiguousZOrSccIccid = '8996600000000000012'; // 19 digits, matches both Z and SCC
  const n950Serial = 'NCD123456789';

  group('Mandatory acceptance case — SIM Z must never be stored as SCC', () {
    test(
        'explicit selection of Z wins outright even though SCC would also '
        'validate the same code — never asks, never guesses the other way',
        () {
      final result = SimCarrierResolver.resolve(
        normalizedCode: ambiguousZOrSccIccid,
        candidates: [simZ(), simScc()],
        selectedType: simZ(),
      );
      expect(result.isResolved, isTrue);
      expect(result.resolved!.id, 'sim-type-z');
    });

    test(
        'explicit selection of SCC wins outright for the exact same code — '
        'proves the decision is driven by the deliberate choice, not the '
        'code pattern', () {
      final result = SimCarrierResolver.resolve(
        normalizedCode: ambiguousZOrSccIccid,
        candidates: [simZ(), simScc()],
        selectedType: simScc(),
      );
      expect(result.isResolved, isTrue);
      expect(result.resolved!.id, 'sim-type-scc');
    });

    test(
        'with NO explicit selection, the ambiguous code is NEVER silently '
        'auto-assigned to whichever type happens to be first in the '
        'candidate list — this is the exact bug that used to store Z as SCC',
        () {
      // Z listed first, SCC second — the old "iterate, first match wins"
      // logic would have silently picked Z here even with zero selection,
      // which would be right by luck in this ordering and WRONG the moment
      // the catalog order changed. The fix must refuse to guess either way.
      final resultZFirst = SimCarrierResolver.resolve(
        normalizedCode: ambiguousZOrSccIccid,
        candidates: [simZ(), simScc()],
      );
      expect(resultZFirst.isAmbiguous, isTrue);
      expect(resultZFirst.resolved, isNull);

      // Same code, candidates reversed — must be equally ambiguous, proving
      // list order never influences the outcome.
      final resultSccFirst = SimCarrierResolver.resolve(
        normalizedCode: ambiguousZOrSccIccid,
        candidates: [simScc(), simZ()],
      );
      expect(resultSccFirst.isAmbiguous, isTrue);
      expect(resultSccFirst.resolved, isNull);
      expect(
        resultZFirst.ambiguousCandidates.map((t) => t.id).toSet(),
        resultSccFirst.ambiguousCandidates.map((t) => t.id).toSet(),
      );
    });

    test('a hidden/deprecated SIM type is never offered as an ambiguity '
        'candidate once the caller has excluded it (mirrors '
        '_typesForSelectedCategory\'s isVisible filter)', () {
      // All three share the exact same pattern. A real caller
      // (shipment_scan_page.dart's _typesForSelectedCategory) filters out
      // non-visible types BEFORE calling resolve() — this test proves that
      // once excluded, the hidden type never reappears in the ambiguity
      // list, even though it would otherwise also match the code.
      final allThree = [simZ(), simScc(), hiddenSimLegacy()];
      final visibleOnly = allThree.where((t) => t.isVisible).toList();
      expect(visibleOnly.any((t) => t.id == 'sim-type-legacy'), isFalse);

      final result = SimCarrierResolver.resolve(
        normalizedCode: ambiguousZOrSccIccid,
        candidates: visibleOnly,
      );
      expect(result.isAmbiguous, isTrue);
      expect(
        result.ambiguousCandidates.map((t) => t.id),
        isNot(contains('sim-type-legacy')),
      );
    });
  });

  group('Batch independence — multiple different types in one submission', () {
    test('a batch containing a device code, a Z code (explicit), and an '
        'ambiguous code with no selection each resolve independently, with '
        'zero cross-contamination between items', () {
      // Simulates exactly what _processScannedCodesIntoBatch does: call
      // resolve() once per code, each with its own selectedType snapshot.
      final deviceResult = SimCarrierResolver.resolve(
        normalizedCode: n950Serial,
        candidates: [deviceN950(), simZ(), simScc()],
        selectedType: null,
      );
      final explicitZResult = SimCarrierResolver.resolve(
        normalizedCode: ambiguousZOrSccIccid,
        candidates: [simZ(), simScc()],
        selectedType: simZ(),
      );
      final noSelectionResult = SimCarrierResolver.resolve(
        normalizedCode: ambiguousZOrSccIccid,
        candidates: [simZ(), simScc()],
        selectedType: null,
      );

      expect(deviceResult.resolved!.id, 'n950');
      expect(explicitZResult.resolved!.id, 'sim-type-z');
      expect(noSelectionResult.isAmbiguous, isTrue);

      // Resolving the device code first must not leak into / bias the
      // later SIM resolutions, and vice versa — each call is independent.
      expect(deviceResult.resolved!.category, 'devices');
      expect(explicitZResult.resolved!.category, 'sim');
    });

    test('three SIM items of three different effective types in one batch '
        'each keep their own independently-resolved type', () {
      final results = <String>[];
      final codes = <String, ItemType?>{
        'AAA': simZ(), // explicit Z
        'BBB': simScc(), // explicit SCC
        'CCC': null, // no explicit type — must be ambiguous, not guessed
      };
      codes.forEach((code, selected) {
        final r = SimCarrierResolver.resolve(
          normalizedCode: ambiguousZOrSccIccid,
          candidates: [simZ(), simScc()],
          selectedType: selected,
        );
        results.add(r.isResolved ? r.resolved!.id : 'AMBIGUOUS');
      });

      expect(results, ['sim-type-z', 'sim-type-scc', 'AMBIGUOUS']);
    });
  });

  group('Retry / resubmission stability', () {
    test('resolving the exact same code+candidates+selection twice in a row '
        '(simulating a retried/resubmitted scan) yields an IDENTICAL result '
        'both times — classification never drifts on retry', () {
      final first = SimCarrierResolver.resolve(
        normalizedCode: ambiguousZOrSccIccid,
        candidates: [simZ(), simScc()],
        selectedType: simZ(),
      );
      final second = SimCarrierResolver.resolve(
        normalizedCode: ambiguousZOrSccIccid,
        candidates: [simZ(), simScc()],
        selectedType: simZ(),
      );
      expect(first.resolved!.id, second.resolved!.id);
    });

    test('a retried AMBIGUOUS resolution stays ambiguous with the exact '
        'same candidate set both times, not a different guess on retry', () {
      final first = SimCarrierResolver.resolve(
        normalizedCode: ambiguousZOrSccIccid,
        candidates: [simZ(), simScc()],
      );
      final second = SimCarrierResolver.resolve(
        normalizedCode: ambiguousZOrSccIccid,
        candidates: [simZ(), simScc()],
      );
      expect(first.isAmbiguous, isTrue);
      expect(second.isAmbiguous, isTrue);
      expect(
        first.ambiguousCandidates.map((t) => t.id).toSet(),
        second.ambiguousCandidates.map((t) => t.id).toSet(),
      );
    });
  });

  // NOTE: the page-level manual-vs-camera parity proof now lives in
  // `explicit_selection_integration_test.dart` (scenario 5, via the shared
  // `classifyScan`) and `shipment_scan_page_wiring_test.dart`. This group
  // only documents that the RESOLVER itself has no "entry method" input.
  group('Resolver has no entry-method input (manual vs camera cannot diverge)',
      () {
    test(
        'the resolver gives the same answer regardless of how the normalized '
        'code was obtained — it has no entry-method parameter at all (the '
        'shipment page no longer calls it; the dashboard quick-add does)', () {
      // There is no "entry method" parameter on resolve() at all — by
      // construction, a manual-entry call and a camera-scan call with the
      // same normalizedCode/candidates/selectedType cannot diverge, because
      // they are literally the same function call. This test documents
      // that invariant explicitly rather than leaving it implicit.
      final asIfManual = SimCarrierResolver.resolve(
        normalizedCode: ambiguousZOrSccIccid,
        candidates: [simZ(), simScc()],
        selectedType: simZ(),
      );
      final asIfCameraScan = SimCarrierResolver.resolve(
        normalizedCode: ambiguousZOrSccIccid,
        candidates: [simZ(), simScc()],
        selectedType: simZ(),
      );
      expect(asIfManual.resolved!.id, asIfCameraScan.resolved!.id);
    });
  });
}
