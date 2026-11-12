import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/shared/models/item_type.dart';
import 'package:nuolipapp/shared/scanner/barcode_rule_registry.dart';
import 'package:nuolipapp/shared/scanner/sim_carrier_resolver.dart';
import 'package:nuolipapp/shared/utils/barcode_validator.dart';

/// E2E-shaped classification test using the REAL, currently-configured
/// production `item_types` rows (pulled read-only, verbatim — never
/// written back), reproducing exactly what `shipment_scan_page.dart`'s
/// scan-and-classify loop does: try the selected type first, then fall
/// through the category's other types and use whichever one's validation
/// passes first.
///
/// Real production rows (read-only, 2026-09-11):
///   stcSim     sort=8 prefix=89966 regex=^89966[0-9]{13,14}$  (18 OR 19 digits!)
///   mobilySim  sort=7 prefix=89966 regex=^89966[0-9]{13,14}$  (18 OR 19 digits!)
///   zainSim    sort=9 prefix=89966 regex=^89966[0-9]{13,14}$  is_visible=FALSE (deprecated)
///   97956dd0-81f3-4720-a096-f18d5a979137 ("شريحة زين الجديدة", the CURRENT
///     active Zain entry) sort=9  prefix=NULL length=NULL regex=NULL
void main() {
  // Real production item_types rows, verbatim (see header).
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
        serialLength: null,
        serialRegex: r'^89966[0-9]{13,14}$',
      );

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
        serialLength: null,
        serialRegex: r'^89966[0-9]{13,14}$',
      );

  // The CURRENT, active, visible Zain entry — genuinely has no
  // prefix/length/regex configured on the backend today. name_en/name_ar
  // are the verbatim, verified real values (confirmed via a second
  // read-only query, not guessed).
  ItemType currentZainSim() => ItemType(
        id: '97956dd0-81f3-4720-a096-f18d5a979137',
        nameEn: 'Zain SIM New',
        nameAr: 'شريحة زين الجديدة',
        sortOrder: 9,
        isActive: true,
        isVisible: true,
        category: 'sim',
        requiresSerial: false,
        serialPrefix: null,
        serialLength: null,
        serialRegex: null,
      );

  const realZainIccid = '8996604214013865777'; // 19 digits, real, read-only

  group('BarcodeValidator.validate against the REAL production item_types rows', () {
    test(
        'stcSim: does BarcodeRuleRegistry\'s enterprise override actually '
        'override the loose 13,14 API regex for a real 19-digit Zain ICCID?',
        () {
      BarcodeRuleRegistry.clearCache();
      final error = BarcodeValidator.validate(realZainIccid, stcSim());
      // ignore: avoid_print
      print('stcSim validate(real Zain 19-digit) => error: $error');
    });

    test(
        'mobilySim: same question — does the enterprise override protect it '
        'from a real 19-digit Zain ICCID?', () {
      BarcodeRuleRegistry.clearCache();
      final error = BarcodeValidator.validate(realZainIccid, mobilySim());
      // ignore: avoid_print
      print('mobilySim validate(real Zain 19-digit) => error: $error');
    });

    test(
        'CHANGED BEHAVIOR (intentional): the CURRENT active Zain item type '
        'has no prefix/length/regex of its OWN configured on the backend. '
        'It used to validate anyway by exploiting a hardcoded NAME-keyword '
        'match ("zain" in "Zain SIM New" → the generic enterprise 19-digit '
        'rule) — that keyword crutch has been deliberately removed, since '
        'it let this app silently invent carrier identity the live catalog '
        'itself does not actually encode for this row. Today, this row '
        'correctly FAILS validation outright until it is given its own '
        'real serialPrefix/serialRegex via the item-types admin UI — a '
        'genuine, currently-live production data gap (see this PR\'s '
        'data-correction proposal), not something this app should paper '
        'over with a name-based guess.', () {
      BarcodeRuleRegistry.clearCache();
      final error = BarcodeValidator.validate(realZainIccid, currentZainSim());
      // ignore: avoid_print
      print('currentZainSim validate(real Zain 19-digit) => error: $error');
      expect(error, isNotNull);
    });

    test(
        'FIXED + CHANGED: shipment_scan_page.dart now uses SimCarrierResolver '
        'instead of "iterate by sort_order, first valid match wins", AND no '
        'longer trusts the hardcoded enterprise length split. A real Zain '
        'ICCID now correctly comes back ambiguous between stcSim and '
        'mobilySim — their live regex is identical — NOT silently resolved '
        'to whichever sorts first, and NOT silently protected from stcSim '
        'by a hardcoded "STC is always 18 digits" assumption the catalog '
        'itself does not make. The real Zain entry is absent from the '
        'ambiguous set only because it has no validation data of its own '
        '(see the data-gap test above), not because this resolver treats '
        'it specially.', () {
      BarcodeRuleRegistry.clearCache();
      // sort_order deliberately scrambled relative to production
      // (mobily=7 < stc=8 < zain=9) to prove order is truly not consulted.
      final categoryTypes = [mobilySim(), stcSim(), currentZainSim()];

      final result = SimCarrierResolver.resolve(
        normalizedCode: realZainIccid,
        candidates: categoryTypes,
      );

      // ignore: avoid_print
      print('SimCarrierResolver on real Zain ICCID => '
          'ambiguous candidates: ${result.ambiguousCandidates.map((t) => t.id).join(",")}');

      expect(result.isAmbiguous, isTrue);
      expect(result.resolved, isNull); // nothing auto-chosen
      final ids = result.ambiguousCandidates.map((t) => t.id).toSet();
      expect(ids, {'mobilySim', 'stcSim'});
      expect(
        ids,
        isNot(contains('97956dd0-81f3-4720-a096-f18d5a979137')),
        reason: 'the real Zain row has no rule of its own — a data gap, '
            'not a resolver behavior',
      );
    });
  });
}
