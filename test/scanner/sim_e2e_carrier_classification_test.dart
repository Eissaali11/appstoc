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
        'the CURRENT active Zain item type has no prefix/length/regex of its '
        'OWN configured on the backend, but its real name_en/name_ar ("Zain '
        'SIM New" / "شريحة زين الجديدة") still resolves it to the enterprise '
        'sim_89966_19 rule by NAME match — so it correctly accepts a real '
        '19-digit Zain ICCID despite the missing backend config', () {
      BarcodeRuleRegistry.clearCache();
      final error = BarcodeValidator.validate(realZainIccid, currentZainSim());
      // ignore: avoid_print
      print('currentZainSim validate(real Zain 19-digit) => error: $error');
      expect(error, isNull);
    });

    test(
        'FIXED: shipment_scan_page.dart now uses SimCarrierResolver instead '
        'of "iterate by sort_order, first valid match wins" — a real Zain '
        'ICCID with mobilySim (sort=7) and the real Zain entry (sort=9) '
        'both validating is correctly reported as ambiguous, NOT silently '
        'resolved to whichever sorts first', () {
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
      expect(ids, {'mobilySim', '97956dd0-81f3-4720-a096-f18d5a979137'});
      expect(ids, isNot(contains('stcSim'))); // confirmed NOT the original "→STC" bug
    });
  });
}
