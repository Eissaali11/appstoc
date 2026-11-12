// Ported from the peer session's commit 36b698d (repo D:\stcok\stock_courier,
// branch fix/scanner-a960-i9000s-i9100-all-flows) — pure SimCarrierResolver
// tests only, kept in their own file so this branch's own resolver tests are
// not clobbered.
//
// NOT PORTED (2 tests, their L334-361, group "explicit pre-selection is
// honored (no needless dialog)"): they assert the peer resolver's semantics
// "a pre-selected type wins only if it ALONE validates, otherwise fall back
// to ambiguity resolution among all candidates". That fall-back is the
// opposite of this branch's final rule (an explicit selection is validated
// ONLY against its own rule and never falls through), so they are left out
// for the user to decide. Fixture names carrierAlpha/carrierBeta are kept
// on purpose: a name like "Test Carrier X" lowercases to "...stc..." and
// accidentally matched a keyword.
//
// Scope of what these still prove here: the resolver (now used only by
// no-dropdown flows such as the dashboard quick-add) never silently picks
// one of several structurally-valid candidates, is order-independent, and
// never lets a device serial match a SIM candidate.
import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/shared/models/item_type.dart';
import 'package:nuolipapp/shared/scanner/sim_carrier_resolver.dart';
import 'package:nuolipapp/shared/utils/barcode_validator.dart';

void main() {
  // Same enterprise-table-backed fixtures as
  // test/utils/barcode_validation_engine_test.dart — id/name alone is
  // enough for BarcodeRuleRegistry.fromItemType() to route these through
  // the real (current, widened) sim_stc / sim_89966_19 rules regardless of
  // the serialLength/serialRegex declared here.
  final stc = ItemType(
    id: 'stc',
    nameEn: 'STC',
    nameAr: 'STC',
    sortOrder: 4,
    isActive: true,
    isVisible: true,
    category: 'sim',
    requiresSerial: true,
    serialPrefix: '89966',
    serialLength: 18,
    serialRegex: r'^89966[0-9]{13}$',
  );

  final zain = ItemType(
    id: 'zain',
    nameEn: 'Zain SIM',
    nameAr: 'زين',
    sortOrder: 5,
    isActive: true,
    isVisible: true,
    category: 'sim',
    requiresSerial: true,
    serialPrefix: '89966',
    serialLength: 19,
    serialRegex: r'^89966[0-9]{14}$',
  );

  final mobily = ItemType(
    id: 'mobily',
    nameEn: 'Mobily SIM',
    nameAr: 'موبايلي',
    sortOrder: 6,
    isActive: true,
    isVisible: true,
    category: 'sim',
    requiresSerial: true,
    serialPrefix: '89966',
    serialLength: 19,
    serialRegex: r'^89966[0-9]{14}$',
  );

  final repara = ItemType(
    id: 'repara',
    nameEn: 'Repara SIM',
    nameAr: 'ريبارا',
    sortOrder: 7,
    isActive: true,
    isVisible: true,
    category: 'sim',
    requiresSerial: true,
    serialPrefix: '89966',
    serialLength: 19,
    serialRegex: r'^89966[0-9]{14}$',
  );

  final lebara = ItemType(
    id: 'lebara_sim',
    nameEn: 'Lebara SIM',
    nameAr: 'ليبارا',
    sortOrder: 8,
    isActive: true,
    isVisible: true,
    category: 'sim',
    requiresSerial: true,
    serialPrefix: '89966',
    serialLength: 19,
    serialRegex: r'^89966[0-9]{14}$',
  );

  // Deliberately NOT a recognized carrier name/id (BarcodeRuleRegistry's
  // enterprise table only matches on substrings like 'stc'/'zain'/'mobily'/
  // 'lebara'/'repara' — chosen so NONE of those appear even as an
  // accidental substring after lowercasing + removing spaces; e.g.
  // "Test Carrier X" → "testcarrierx" actually DOES contain "stc" by
  // coincidence, which is exactly the trap "carrier_alpha"/"carrier_beta"
  // avoid). This makes these two fixtures resolve purely from their OWN
  // declared serialPrefix/serialLength/serialRegex
  // (BarcodeRuleRegistry.fromItemType's non-enterprise fallback path),
  // with ZERO dependency on whatever the live enterprise table currently
  // says for sim_stc / sim_89966_19. Deliberately identical shape →
  // always overlap, on any branch state — this is what makes the
  // ambiguity-detection tests below reproducible and self-contained
  // regardless of other uncommitted scanner changes.
  final carrierAlpha = ItemType(
    id: 'carrier_alpha',
    nameEn: 'Carrier Alpha',
    nameAr: 'شركة ألفا',
    sortOrder: 20,
    isActive: true,
    isVisible: true,
    category: 'sim',
    requiresSerial: true,
    serialPrefix: '89966',
    serialLength: 19,
    serialRegex: r'^89966[0-9]{14}$',
  );

  final carrierBeta = ItemType(
    id: 'carrier_beta',
    nameEn: 'Carrier Beta',
    nameAr: 'شركة بيتا',
    sortOrder: 21,
    isActive: true,
    isVisible: true,
    category: 'sim',
    requiresSerial: true,
    serialPrefix: '89966',
    serialLength: 19,
    serialRegex: r'^89966[0-9]{14}$',
  );

  final n950 = ItemType(
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
    serialRegex: r'^(NCD|NCC)[0-9]{9}$',
  );

  final i9100 = ItemType(
    id: 'i9100',
    nameEn: 'i9100',
    nameAr: 'i9100',
    sortOrder: 2,
    isActive: true,
    isVisible: true,
    category: 'devices',
    requiresSerial: true,
    serialPrefix: 'SAW',
    serialLength: 11,
    serialRegex: r'^SAW[0-9]{8}$',
  );

  final i9000s = ItemType(
    id: 'i9000s',
    nameEn: 'i9000S',
    nameAr: 'i9000S',
    sortOrder: 3,
    isActive: true,
    isVisible: true,
    category: 'devices',
    requiresSerial: true,
    serialPrefix: 'SAS',
    serialLength: 11,
    serialRegex: r'^SAS[0-9]{8}$',
  );

  const realIccid19 = '8996604213325098366'; // 19 digits, real production shape
  const realIccid18 = '899660609902052180'; // 18 digits, real production shape
  final allSimCarriers = [stc, zain, mobily, lebara, repara];

  group('SimCarrierResolver — single-candidate classification', () {
    test('STC classifies correctly when STC is the only candidate', () {
      final r = SimCarrierResolver.resolve(
        normalizedCode: realIccid18,
        candidates: [stc],
      );
      expect(r.isResolved, isTrue);
      expect(r.resolved!.id, 'stc');
    });

    test('Zain classifies correctly when Zain is the only candidate', () {
      final r = SimCarrierResolver.resolve(
        normalizedCode: realIccid19,
        candidates: [zain],
      );
      expect(r.isResolved, isTrue);
      expect(r.resolved!.id, 'zain');
    });

    test('Mobily classifies correctly when Mobily is the only candidate', () {
      final r = SimCarrierResolver.resolve(
        normalizedCode: realIccid19,
        candidates: [mobily],
      );
      expect(r.isResolved, isTrue);
      expect(r.resolved!.id, 'mobily');
    });

    test('Lebara and Repara classify correctly when each is the only candidate', () {
      final lebaraResult = SimCarrierResolver.resolve(
        normalizedCode: realIccid19,
        candidates: [lebara],
      );
      expect(lebaraResult.isResolved, isTrue);
      expect(lebaraResult.resolved!.id, 'lebara_sim');

      final reparaResult = SimCarrierResolver.resolve(
        normalizedCode: realIccid19,
        candidates: [repara],
      );
      expect(reparaResult.isResolved, isTrue);
      expect(reparaResult.resolved!.id, 'repara');
    });
  });

  group('SimCarrierResolver — ambiguity detection (the actual regression)', () {
    test(
        'two carriers whose rules structurally overlap are BOTH reported '
        'ambiguous, never silently assigned to whichever sorts first '
        '(self-contained fixtures — true regardless of the live '
        'BarcodeRuleRegistry enterprise table state on this branch)', () {
      final r = SimCarrierResolver.resolve(
        normalizedCode: realIccid19,
        candidates: [carrierAlpha, carrierBeta],
      );
      expect(r.isAmbiguous, isTrue,
          reason: 'carrierAlpha and carrierBeta declare the exact same '
              'prefix/length/regex on purpose — a code matching one must '
              'match the other, so the resolver must refuse to guess, '
              'which is exactly the precondition that makes '
              'ShipmentScanPage show the carrier-selection dialog instead '
              'of a silent first-match pick.');
      expect(
        r.ambiguousCandidates.map((t) => t.id).toSet(),
        {'carrier_alpha', 'carrier_beta'},
        reason: 'every structurally-valid candidate must be surfaced — '
            'dropping one silently would reproduce the same bug for that '
            'one carrier.',
      );
      // Never auto-resolved — this is the exact bug this fix closes.
      expect(r.isResolved, isFalse);
    });

    test(
        'INTEGRATION SANITY CHECK — the real carrier fixtures (STC / Zain / '
        'Mobily / Lebara / Repara) never let the resolver report a WRONG '
        'carrier for a real-shaped ICCID; whatever BarcodeRuleRegistry '
        'currently considers a match is exactly what comes back, nothing '
        'silently dropped and nothing silently invented.\n'
        'NOTE: whether this specific overlap is 4-way, 5-way or fully '
        'resolved depends on BarcodeRuleRegistry\'s CURRENT (possibly '
        'uncommitted) sim_stc / sim_89966_19 length rules on this branch — '
        'that is intentional and tracked separately; see the '
        'self-contained carrierX/carrierY test above for the '
        'branch-independent proof of the actual fix.', () {
      for (final realIccid in [realIccid18, realIccid19]) {
        final independentlyValid = allSimCarriers
            .where((t) => BarcodeValidator.validate(realIccid, t) == null)
            .toSet();

        final r = SimCarrierResolver.resolve(
          normalizedCode: realIccid,
          candidates: allSimCarriers,
        );

        final reported = r.isAmbiguous
            ? r.ambiguousCandidates.toSet()
            : (r.resolved != null ? {r.resolved!} : <ItemType>{});

        expect(
          reported,
          independentlyValid,
          reason: 'for $realIccid: the resolver must report exactly the '
              'set of carriers that BarcodeValidator.validate() itself '
              'accepts — no more (never invents a match) and no fewer '
              '(never silently drops a real candidate).',
        );
      }
    });

    test(
        'REGRESSION GUARD: reordering the candidate list must not change '
        'which carriers are reported as ambiguous (proves there is no '
        'hidden first-match bias left in the resolver)', () {
      final forward = SimCarrierResolver.resolve(
        normalizedCode: realIccid19,
        candidates: [stc, zain, mobily, lebara, repara],
      );
      final reversed = SimCarrierResolver.resolve(
        normalizedCode: realIccid19,
        candidates: [repara, lebara, mobily, zain, stc],
      );
      expect(
        forward.ambiguousCandidates.map((t) => t.id).toSet(),
        reversed.ambiguousCandidates.map((t) => t.id).toSet(),
      );
    });
  });

  group('SimCarrierResolver — rejects cross-category misclassification', () {
    test('a device serial never matches any SIM candidate (no false accept)',
        () {
      final r = SimCarrierResolver.resolve(
        normalizedCode: 'NCD100229213',
        candidates: allSimCarriers,
      );
      expect(r.isNone, isTrue);
      expect(r.isResolved, isFalse);
      expect(r.isAmbiguous, isFalse);
    });

    test('an unrecognizable code resolves to none, not a guess', () {
      final r = SimCarrierResolver.resolve(
        normalizedCode: '12345',
        candidates: allSimCarriers,
      );
      expect(r.isNone, isTrue);
    });
  });

  group('SimCarrierResolver — device scanning (A960/I9000S/I9100) unaffected', () {
    test('a Urovo i9100 serial resolves uniquely among device candidates', () {
      final r = SimCarrierResolver.resolve(
        normalizedCode: 'SAW12345678',
        candidates: [n950, i9100, i9000s],
      );
      expect(r.isResolved, isTrue);
      expect(r.resolved!.id, 'i9100');
    });

    test('a Urovo i9000S serial resolves uniquely among device candidates', () {
      final r = SimCarrierResolver.resolve(
        normalizedCode: 'SAS12345678',
        candidates: [n950, i9100, i9000s],
      );
      expect(r.isResolved, isTrue);
      expect(r.resolved!.id, 'i9000s');
    });

    test('an N950 serial resolves uniquely among device candidates', () {
      final r = SimCarrierResolver.resolve(
        normalizedCode: 'NCD100229213',
        candidates: [n950, i9100, i9000s],
      );
      expect(r.isResolved, isTrue);
      expect(r.resolved!.id, 'n950');
    });

    test('device candidates never introduce ambiguity between i9100/i9000s',
        () {
      final r = SimCarrierResolver.resolve(
        normalizedCode: 'SAW12345678',
        candidates: [n950, i9100, i9000s],
      );
      expect(r.isAmbiguous, isFalse);
    });
  });
}
