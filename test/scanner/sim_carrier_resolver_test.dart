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
    // CHANGED BEHAVIOR (intentional, per explicit product decision): this
    // app no longer trusts BarcodeRuleRegistry's hardcoded "18 digits =
    // STC, 19 digits = everyone else" length split, because that split is
    // NOT what the live catalog itself stores — production's real stcSim
    // AND mobilySim rows both carry the IDENTICAL regex
    // `^89966[0-9]{13,14}$`, so an 18-digit code is just as "valid STC" as
    // it is "valid Mobily" by the data actually on file. Previously this
    // test asserted the old length-based auto-pick (18 digits →
    // automatically stcSim, no prompt); that was a guess this app has no
    // real ground truth for. It now correctly asks the user instead of
    // picking one. See the proposal section of the PR this test ships
    // with for the data-level fix that would make this resolve
    // automatically again (non-overlapping regex/serialLength per
    // carrier).
    test(
        '18-digit STC-shaped ICCID is ambiguous between stcSim and '
        'mobilySim — their LIVE regex is identical, so no silent pick', () {
      final result = SimCarrierResolver.resolve(
        normalizedCode: realStcIccid,
        candidates: visibleSimCandidates(),
      );
      expect(result.isAmbiguous, isTrue);
      final ids = result.ambiguousCandidates.map((t) => t.id).toSet();
      expect(ids, {'stcSim', 'mobilySim'});
      expect(result.resolved, isNull);
    });

    // CHANGED BEHAVIOR, same root cause, plus a second, more important
    // finding exposed by removing the hardcoded crutch: the CURRENT active
    // "Zain SIM New" catalog row has NO serialPrefix/serialRegex of its own
    // in production (confirmed by direct query). It used to only "work" by
    // accident — its name contained "zain", which matched a hardcoded
    // keyword lookup that force-fed it the generic 19-digit fallback rule.
    // With that keyword crutch removed, "Zain SIM New" has no validation
    // rule at all and can never appear as a match for ANY code, ambiguous
    // or otherwise, until its row is given a real serialPrefix/serialRegex
    // via the item-types admin UI. That is a real, currently-live
    // production data gap, not a bug in this resolver — flagged prominently
    // in this PR's proposal section as something to fix urgently.
    test(
        '19-digit Zain/Mobily-shared ICCID with NO selected type → ambiguous '
        'between stcSim and mobilySim (both share the identical live regex); '
        '"Zain SIM New" itself is NOT in the ambiguous set because it has no '
        'serialPrefix/serialRegex configured in production at all — a real '
        'data gap, not something this resolver can paper over', () {
      final result = SimCarrierResolver.resolve(
        normalizedCode: realZainIccid,
        candidates: visibleSimCandidates(),
      );
      expect(result.isAmbiguous, isTrue);
      final ids = result.ambiguousCandidates.map((t) => t.id).toSet();
      expect(ids, {'stcSim', 'mobilySim'});
      expect(
        ids,
        isNot(contains('97956dd0-81f3-4720-a096-f18d5a979137')),
        reason: 'Zain SIM New has no regex of its own in production — it '
            'cannot validate ANY code right now, real or not',
      );
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
    // CHANGED BEHAVIOR: "Zain SIM New" cannot validate ANYTHING right now
    // (see the data-gap note above) — selecting it no longer short-circuits
    // to an automatic match even for a genuine Zain ICCID. It correctly
    // falls through to the general candidate pool, which is itself
    // ambiguous between stcSim/mobilySim for the same live-regex-overlap
    // reason. This is the most user-visible consequence of this PR: a
    // technician in the "Zain" section scanning a real Zain SIM today gets
    // an STC-vs-Mobily disambiguation prompt instead of silent acceptance,
    // until the catalog row is fixed (see proposal).
    test('19-digit ICCID + selectedType = Zain SIM New → Zain SIM New has no '
        'validation rule of its own in production, so it fails to '
        'short-circuit and falls through to the general ambiguous '
        'stcSim/mobilySim pool instead of silently resolving to Zain', () {
      final result = SimCarrierResolver.resolve(
        normalizedCode: realZainIccid,
        candidates: visibleSimCandidates(),
        selectedType: newVisibleZainSim(),
      );
      expect(result.isResolved, isFalse);
      expect(result.isAmbiguous, isTrue);
      final ids = result.ambiguousCandidates.map((t) => t.id).toSet();
      expect(ids, {'stcSim', 'mobilySim'});
    });

    test('19-digit ICCID + selectedType = mobilySim → resolves directly to '
        'Mobily, no ambiguity prompt (mobilySim DOES carry its own valid '
        'regex, so the selected-type short-circuit still works normally '
        'here — unaffected by this change)', () {
      final result = SimCarrierResolver.resolve(
        normalizedCode: realZainIccid,
        candidates: visibleSimCandidates(),
        selectedType: mobilySim(),
      );
      expect(result.isResolved, isTrue);
      expect(result.resolved!.id, 'mobilySim');
    });

    // CHANGED BEHAVIOR, same cause as above: selectedType (Zain SIM New)
    // still can't validate anything, so this also now falls through to the
    // general pool — which, for an 18-digit code, is ALSO now ambiguous
    // between stcSim and mobilySim (their live regex is identical), not a
    // clean fallback to stcSim alone.
    test('18-digit STC-shaped ICCID + selectedType = Zain SIM New (wrong '
        'section) → selected type fails validation (no rule of its own), '
        'falls through to the general pool, which is itself ambiguous '
        'between stcSim/mobilySim', () {
      final result = SimCarrierResolver.resolve(
        normalizedCode: realStcIccid,
        candidates: visibleSimCandidates(),
        selectedType: newVisibleZainSim(),
      );
      expect(result.isResolved, isFalse);
      expect(result.isAmbiguous, isTrue);
      final ids = result.ambiguousCandidates.map((t) => t.id).toSet();
      expect(ids, {'stcSim', 'mobilySim'});
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
