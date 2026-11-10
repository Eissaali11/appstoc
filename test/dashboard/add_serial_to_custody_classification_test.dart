import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/shared/scanner/barcode_rule_registry.dart';

/// Regression test for the item-type classification fix in
/// `DashboardController.addSerialToCustody` (the "quick add for a
/// not-found serial" path on the dashboard's generic custody-search card).
///
/// Root cause that was fixed: this method used to hardcode
/// `isSim ? 'sim_stc' : 'n950'` for ANY 89-prefixed code, regardless of its
/// actual length — a real 19-digit Zain/Mobily/Lebara/Repara ICCID was
/// silently mislabeled as an 18-digit STC ICCID every time, purely because
/// both happen to start with the same digits. The fix matches the code
/// against the real [BarcodeRuleRegistry] rules (which differ by exact
/// digit count) instead.
///
/// These tests exercise the SAME registry lookup the fixed method now
/// performs, proving the classification decision itself is correct. The
/// method's own file (`dashboard_controller.dart`) cannot be unit-tested in
/// isolation here without a full GetX/Dio widget harness, matching this
/// codebase's established pattern (see `sim_carrier_classification_test.dart`,
/// which tests the same underlying registry match for the same reason).
void main() {
  group('addSerialToCustody classification — registry match, not a length-blind guess', () {
    String? classifyLikeFixedMethod(String clean) {
      BarcodeRule? matched;
      for (final rule in BarcodeRuleRegistry.fallbackRules) {
        if (rule.matches(clean)) {
          matched = rule;
          break;
        }
      }
      final looksLikeSim = clean.startsWith('89966') || clean.startsWith('89');
      return matched?.id ?? (looksLikeSim ? 'sim_stc' : 'n950');
    }

    test('a real 19-digit Zain/Mobily/Lebara/Repara ICCID classifies as '
        'sim_89966_19, never the old hardcoded sim_stc', () {
      const realZainIccid = '8996604214013865777';
      expect(realZainIccid.length, 19);
      expect(classifyLikeFixedMethod(realZainIccid), 'sim_89966_19');
      expect(classifyLikeFixedMethod(realZainIccid), isNot('sim_stc'));
    });

    test('a real 18-digit STC ICCID still classifies correctly as sim_stc',
        () {
      const realStcIccid = '899660110003457765';
      expect(realStcIccid.length, 18);
      expect(classifyLikeFixedMethod(realStcIccid), 'sim_stc');
    });

    test('classifying one family never flips the other — both resolve '
        'independently from the same loop', () {
      const realZainIccid = '8996604214013865777';
      const realStcIccid = '899660110003457765';
      expect(classifyLikeFixedMethod(realZainIccid), 'sim_89966_19');
      expect(classifyLikeFixedMethod(realStcIccid), 'sim_stc');
    });

    test('a non-SIM-shaped code still falls back to the device default, '
        'unchanged from before the fix', () {
      expect(classifyLikeFixedMethod('NCD999999999'), 'n950');
    });
  });
}
