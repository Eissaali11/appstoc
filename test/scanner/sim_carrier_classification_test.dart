import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/shared/scanner/barcode_rule_registry.dart';

/// Regression test for a real classification bug: `DashboardController
/// .addSerialToCustody`'s "quick add for a not-found serial" path (the
/// generic/unscoped custody-search card in `dashboard_page.dart`, which has
/// no section/item-type context to rely on) used to hardcode ANY
/// 89-prefixed serial straight to `'sim_stc'`, regardless of its actual
/// length — a real 19-digit Zain/Mobily/Lebara/Repara ICCID was silently
/// mislabeled as an 18-digit STC ICCID every time.
///
/// The fix reuses this exact registry match (see
/// `dashboard_controller.dart`'s `addSerialToCustody`) instead of a
/// hand-rolled guess, so this file pins the registry's own real behavior
/// against two REAL serials (one confirmed-Zain, one confirmed-STC, both
/// pulled read-only from production — never written back) as the direct
/// regression proof for the fix.
void main() {
  group('SIM carrier classification — length is NOT ambiguous between families', () {
    test('a real 19-digit Zain/Mobily/Lebara/Repara ICCID matches sim_89966_19, '
        'never sim_stc', () {
      const realZainIccid = '8996604214013865777';
      expect(realZainIccid.length, 19);

      BarcodeRule? matched;
      for (final rule in BarcodeRuleRegistry.fallbackRules) {
        if (rule.matches(realZainIccid)) {
          matched = rule;
          break;
        }
      }

      expect(matched, isNotNull, reason: 'a real, previously-scanned ICCID must match a rule');
      expect(matched!.id, 'sim_89966_19');
      expect(matched.id, isNot('sim_stc'));
    });

    test('a real 18-digit STC ICCID matches sim_stc, never sim_89966_19', () {
      const realStcIccid = '899660110003457765';
      expect(realStcIccid.length, 18);

      BarcodeRule? matched;
      for (final rule in BarcodeRuleRegistry.fallbackRules) {
        if (rule.matches(realStcIccid)) {
          matched = rule;
          break;
        }
      }

      expect(matched, isNotNull, reason: 'a real, previously-scanned ICCID must match a rule');
      expect(matched!.id, 'sim_stc');
      expect(matched.id, isNot('sim_89966_19'));
    });

    test('both real serials are classified independently — fixing one family '
        'never flips the other', () {
      const realZainIccid = '8996604214013865777';
      const realStcIccid = '899660110003457765';

      String? classify(String serial) {
        for (final rule in BarcodeRuleRegistry.fallbackRules) {
          if (rule.matches(serial)) return rule.id;
        }
        return null;
      }

      expect(classify(realZainIccid), 'sim_89966_19');
      expect(classify(realStcIccid), 'sim_stc');
    });

    test('the sim_89966_19 rule genuinely accepts 19 digits and only 19 digits '
        '(so it can never widen to match an 18-digit STC ICCID)', () {
      final rule = BarcodeRuleRegistry.fallbackRules
          .firstWhere((r) => r.id == 'sim_89966_19');
      expect(rule.fullLength, 19);
      expect(rule.matches('899660110003457765'), isFalse); // real STC, 18 digits
    });

    test('the sim_stc rule genuinely accepts 18 digits and only 18 digits '
        '(so it can never widen to match a 19-digit Zain-family ICCID)', () {
      final rule =
          BarcodeRuleRegistry.fallbackRules.firstWhere((r) => r.id == 'sim_stc');
      expect(rule.fullLength, 18);
      expect(rule.matches('8996604214013865777'), isFalse); // real Zain, 19 digits
    });

    test('n950 / i9100 / i9000s / a960 device rules are unaffected by either '
        'SIM serial', () {
      const realZainIccid = '8996604214013865777';
      const realStcIccid = '899660110003457765';
      for (final deviceRuleId in ['n950', 'i9100', 'i9000s', 'a960']) {
        final rule =
            BarcodeRuleRegistry.fallbackRules.firstWhere((r) => r.id == deviceRuleId);
        expect(rule.matches(realZainIccid), isFalse);
        expect(rule.matches(realStcIccid), isFalse);
      }
    });
  });
}
