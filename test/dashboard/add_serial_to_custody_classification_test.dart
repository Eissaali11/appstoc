import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/shared/models/item_type.dart';
import 'package:nuolipapp/shared/scanner/sim_carrier_resolver.dart';

/// Regression test for the item-type classification fix in
/// `DashboardController.addSerialToCustody` (the "quick add for a
/// not-found serial" path on the dashboard's generic custody-search card).
///
/// History of this bug, in two stages:
/// 1. Originally: hardcoded `isSim ? 'sim_stc' : 'n950'` for ANY 89-prefixed
///    code regardless of actual length — a real 19-digit Zain/Mobily/Lebara/
///    Repara ICCID was silently mislabeled as an 18-digit STC ICCID.
/// 2. A later partial fix matched against `BarcodeRuleRegistry.fallbackRules`
///    instead — better, but it could still assign `itemTypeId:
///    "sim_89966_19"`, an internal rule-table label that is NOT and has
///    never been a real `item_types.id` in production (confirmed by direct
///    read-only query). Saving that id would have silently corrupted the
///    custody record with a non-existent item type.
///
/// The current fix removes both: the method now builds its candidate list
/// from the live catalog (`itemTypesMap`, filtered to active+visible+the
/// right category) and resolves through the same [SimCarrierResolver] every
/// other scan path uses — it can only ever return a real [ItemType] drawn
/// from that candidate list, never a bespoke string.
///
/// These tests mirror the method's real candidate-building + resolve logic
/// verbatim, against a realistic catalog fixture (the same production shape
/// used in `item_type_invariant_test.dart`), since the method itself
/// (`dashboard_controller.dart`) needs a full GetX/Dio widget harness to
/// instantiate directly, matching this codebase's established pattern.
void main() {
  List<ItemType> catalog() => [
        ItemType(
          id: 'n950',
          nameEn: 'N950',
          nameAr: 'N950',
          sortOrder: 1,
          isActive: true,
          isVisible: true,
          category: 'devices',
          requiresSerial: true,
          serialPrefix: 'NCC,NCD',
          serialLength: 12,
          serialRegex: r'^(NCC|NCD)[0-9]{9}$',
        ),
        ItemType(
          id: 'mobilySim',
          nameEn: 'Mobily SIM',
          nameAr: 'شريحة موبايلي',
          sortOrder: 7,
          isActive: true,
          isVisible: true,
          category: 'sim',
          requiresSerial: true,
          serialPrefix: '89966',
          serialRegex: r'^89966[0-9]{13,14}$',
        ),
        ItemType(
          id: 'stcSim',
          nameEn: 'STC SIM',
          nameAr: 'شريحة STC',
          sortOrder: 8,
          isActive: true,
          isVisible: true,
          category: 'sim',
          requiresSerial: true,
          serialPrefix: '89966',
          serialRegex: r'^89966[0-9]{13,14}$',
        ),
      ];

  /// Mirrors `addSerialToCustody`'s own category-filter + resolve logic
  /// exactly — same `looksLikeSim` heuristic, same active/visible filter,
  /// same [SimCarrierResolver] call.
  ScanTypeResolution resolveLikeAddSerialToCustody(
    String clean,
    List<ItemType> allTypes,
  ) {
    final looksLikeSim = clean.startsWith('89966') || clean.startsWith('89');
    final candidates = allTypes
        .where((t) =>
            t.isActive &&
            t.isVisible &&
            t.category == (looksLikeSim ? 'sim' : 'devices'))
        .toList();
    return SimCarrierResolver.resolve(
      normalizedCode: clean,
      candidates: candidates,
    );
  }

  group('addSerialToCustody classification — live catalog + resolver, '
      'never a fabricated id', () {
    test(
        'a real 19-digit Zain-shaped ICCID is correctly AMBIGUOUS between '
        'stcSim/mobilySim (their live regex is identical) — never silently '
        'assigned the old fake "sim_89966_19" label, and never silently '
        'picked', () {
      const realZainIccid = '8996604214013865777';
      expect(realZainIccid.length, 19);

      final result = resolveLikeAddSerialToCustody(realZainIccid, catalog());

      expect(result.isResolved, isFalse);
      expect(result.isAmbiguous, isTrue);
      final ids = result.ambiguousCandidates.map((t) => t.id).toSet();
      expect(ids, {'stcSim', 'mobilySim'});
      expect(ids, isNot(contains('sim_89966_19')));
      expect(ids, isNot(contains('sim_stc')));
    });

    test(
        'a real 18-digit STC-shaped ICCID is ALSO ambiguous between '
        'stcSim/mobilySim for the same reason — never silently assigned the '
        'old fake "sim_stc" label either', () {
      const realStcIccid = '899660110003457765';
      expect(realStcIccid.length, 18);

      final result = resolveLikeAddSerialToCustody(realStcIccid, catalog());

      expect(result.isResolved, isFalse);
      expect(result.isAmbiguous, isTrue);
      final ids = result.ambiguousCandidates.map((t) => t.id).toSet();
      expect(ids, {'stcSim', 'mobilySim'});
    });

    test('a device-shaped code resolves to the real catalog device id, not '
        'a hardcoded default', () {
      final result =
          resolveLikeAddSerialToCustody('NCD100232013', catalog());
      expect(result.isResolved, isTrue);
      expect(result.resolved!.id, 'n950');
    });

    test('when the catalog genuinely has only one SIM candidate (a '
        'well-configured, non-overlapping type), resolution still works '
        'cleanly with no prompt needed', () {
      final singleSimCatalog = [
        ItemType(
          id: 'virginSim',
          nameEn: 'Virgin Mobile SIM',
          nameAr: 'شريحة فيرجن',
          sortOrder: 20,
          isActive: true,
          isVisible: true,
          category: 'sim',
          requiresSerial: true,
          serialPrefix: '89966',
          serialLength: 20,
          serialRegex: r'^89966[0-9]{15}$',
        ),
      ];
      final result = resolveLikeAddSerialToCustody(
        '89966000000000000000', // 20 digits, matches virginSim only
        singleSimCatalog,
      );
      expect(result.isResolved, isTrue);
      expect(result.resolved!.id, 'virginSim');
    });
  });
}
