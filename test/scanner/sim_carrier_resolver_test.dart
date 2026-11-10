import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/shared/models/item_type.dart';
import 'package:nuolipapp/shared/scanner/barcode_rule_registry.dart';
import 'package:nuolipapp/shared/scanner/sim_carrier_resolver.dart';

/// Regression tests for [SimCarrierResolver] — never guess a carrier by
/// `sort_order` (or any other order) when more than one real, visible item
/// type validates the same scanned code. Fixtures are the REAL, verbatim
/// production `item_types` rows (read-only, confirmed 2026-09-11) and REAL
/// serials (one confirmed Zain, one confirmed STC).
void main() {
  // --- Real production fixtures (see header) ---
  ItemType mobilySim() => ItemType(
        id: 'mobilySim',
        nameEn: 'mobilySim',
        nameAr: 'شريحة موبايلي',
        sortOrder: 7,
        isActive: true,
        isVisible: true,
        category: 'sim',
        requiresSerial: true,
        serialPrefix: '89966',
        serialRegex: r'^89966[0-9]{13,14}$',
      );

  ItemType stcSim() => ItemType(
        id: 'stcSim',
        nameEn: 'stcSim',
        nameAr: 'شريحة STC',
        sortOrder: 8,
        isActive: true,
        isVisible: true,
        category: 'sim',
        requiresSerial: true,
        serialPrefix: '89966',
        serialRegex: r'^89966[0-9]{13,14}$',
      );

  // The OLD, deprecated Zain entry — is_visible = false in production.
  ItemType oldHiddenZainSim() => ItemType(
        id: 'zainSim',
        nameEn: 'zainSim',
        nameAr: 'شريحة زين القديمة',
        sortOrder: 9,
        isActive: true,
        isVisible: false,
        category: 'sim',
        requiresSerial: true,
        serialPrefix: '89966',
        serialRegex: r'^89966[0-9]{13,14}$',
      );

  // The CURRENT, active, visible Zain entry — real name_en/name_ar
  // verified; no prefix/length/regex configured on the backend row itself
  // (classified via BarcodeRuleRegistry's enterprise-by-name match instead).
  ItemType newVisibleZainSim() => ItemType(
        id: '97956dd0-81f3-4720-a096-f18d5a979137',
        nameEn: 'Zain SIM New',
        nameAr: 'شريحة زين الجديدة',
        sortOrder: 9,
        isActive: true,
        isVisible: true,
        category: 'sim',
        requiresSerial: false,
      );

  ItemType n950() => ItemType(
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
        serialRegex: r'^(NCD|NCC)[A-Z0-9]{9}$',
      );

  const realZainIccid = '8996604214013865777'; // 19 digits, real, read-only
  const realStcIccid = '899660110003457765'; // 18 digits, real, read-only

  // Candidates as the screen would actually offer them: hidden type
  // excluded, real category types included. sort_order is intentionally
  // scrambled relative to production (mobily=7, stc=8, zain=9) to prove
  // the resolver truly ignores it rather than happening to preserve it.
  List<ItemType> visibleSimCandidates() =>
      [stcSim(), newVisibleZainSim(), mobilySim()];

  setUp(() => BarcodeRuleRegistry.clearCache());

  group('SimCarrierResolver — no selected type', () {
    test('18-digit STC → resolves to stcSim automatically (single match)', () {
      final result = SimCarrierResolver.resolve(
        normalizedCode: realStcIccid,
        candidates: visibleSimCandidates(),
      );
      expect(result.isResolved, isTrue);
      expect(result.resolved!.id, 'stcSim');
    });

    test(
        '19-digit Zain/Mobily-shared ICCID with NO selected type → ambiguous, '
        'Mobily is NEVER auto-picked just because it would sort first', () {
      final result = SimCarrierResolver.resolve(
        normalizedCode: realZainIccid,
        candidates: visibleSimCandidates(),
      );
      expect(result.isAmbiguous, isTrue);
      final ids = result.ambiguousCandidates.map((t) => t.id).toSet();
      expect(ids, {'mobilySim', '97956dd0-81f3-4720-a096-f18d5a979137'});
      expect(result.resolved, isNull); // critical: nothing auto-chosen
    });

    test('the hidden old zainSim (is_visible=false) never appears as a '
        'candidate when the caller filters it out before calling resolve', () {
      // The caller is responsible for excluding hidden/deprecated types —
      // this test documents that once excluded, resolve() never sees or
      // offers it.
      final candidates = visibleSimCandidates();
      expect(candidates.any((t) => t.id == 'zainSim'), isFalse);

      final result = SimCarrierResolver.resolve(
        normalizedCode: realZainIccid,
        candidates: candidates,
      );
      final ids = result.ambiguousCandidates.map((t) => t.id);
      expect(ids, isNot(contains('zainSim')));
    });
  });

  group('SimCarrierResolver — selected type present (section-scoped)', () {
    test('19-digit ICCID + selectedType = Zain SIM New → resolves directly '
        'to Zain, no ambiguity prompt at all', () {
      final result = SimCarrierResolver.resolve(
        normalizedCode: realZainIccid,
        candidates: visibleSimCandidates(),
        selectedType: newVisibleZainSim(),
      );
      expect(result.isResolved, isTrue);
      expect(result.resolved!.id, '97956dd0-81f3-4720-a096-f18d5a979137');
      expect(result.isAmbiguous, isFalse);
    });

    test('19-digit ICCID + selectedType = mobilySim → resolves directly to '
        'Mobily, no ambiguity prompt', () {
      final result = SimCarrierResolver.resolve(
        normalizedCode: realZainIccid,
        candidates: visibleSimCandidates(),
        selectedType: mobilySim(),
      );
      expect(result.isResolved, isTrue);
      expect(result.resolved!.id, 'mobilySim');
    });

    test('18-digit STC ICCID + selectedType = Zain SIM New (wrong section) → '
        'selected type fails validation, falls through to unambiguous stcSim '
        'match', () {
      final result = SimCarrierResolver.resolve(
        normalizedCode: realStcIccid,
        candidates: visibleSimCandidates(),
        selectedType: newVisibleZainSim(),
      );
      expect(result.isResolved, isTrue);
      expect(result.resolved!.id, 'stcSim');
    });
  });

  group('SimCarrierResolver — devices are unaffected', () {
    test('n950 device serial never becomes ambiguous among SIM candidates', () {
      final result = SimCarrierResolver.resolve(
        normalizedCode: 'NCD100232013',
        candidates: [n950(), stcSim(), mobilySim(), newVisibleZainSim()],
      );
      expect(result.isResolved, isTrue);
      expect(result.resolved!.id, 'n950');
    });
  });

  group('SimCarrierResolver — no match at all', () {
    test('an unrecognizable code resolves to none, not a guess', () {
      final result = SimCarrierResolver.resolve(
        normalizedCode: 'GARBAGE123',
        candidates: visibleSimCandidates(),
      );
      expect(result.isNone, isTrue);
    });
  });

  group('SimCarrierResolver — brand-new catalog type, zero code changes', () {
    // A carrier the enterprise table has never heard of — id/name contain
    // none of BarcodeRuleRegistry's hardcoded keywords (n950/i9100/i9000/
    // a960/stc/zain/mobily/lebara/repara). If this app were genuinely
    // catalog-driven end to end, adding such a row to item_types with its
    // own serialRegex must make it classifiable with zero app code changes.
    ItemType virginSim() => ItemType(
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
          // Deliberately precise and NON-overlapping with any other
          // candidate's pattern/length — a well-configured catalog row,
          // unlike the legacy stc/mobily/zain rows whose live regex is
          // itself ambiguous (see module doc).
          serialRegex: r'^89966[0-9]{15}$',
        );

    // 89966 + 15 digits = 20 chars total, matching virginSim's regex exactly.
    const virginIccid = '89966000000000000000';

    test(
        'a synthetic unknown-to-the-enterprise-table carrier with a precise '
        'regex resolves via the live-catalog path alone, no hardcoded '
        'keyword match required', () {
      final result = SimCarrierResolver.resolve(
        normalizedCode: virginIccid,
        candidates: [...visibleSimCandidates(), virginSim()],
      );
      expect(result.isResolved, isTrue);
      expect(result.resolved!.id, 'virginSim');
    });

    test(
        'the same new type does not falsely trigger ambiguity against the '
        'existing legacy candidates (lengths are disjoint)', () {
      final result = SimCarrierResolver.resolve(
        normalizedCode: virginIccid,
        candidates: [...visibleSimCandidates(), virginSim()],
      );
      expect(result.isAmbiguous, isFalse);
    });
  });
}
