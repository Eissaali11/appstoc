import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/shared/models/item_type.dart';
import 'package:nuolipapp/shared/scanner/barcode_candidate_selector.dart';
import 'package:nuolipapp/shared/scanner/barcode_rule_registry.dart';
import 'package:nuolipapp/shared/scanner/duplicate_scanner_guard.dart';
import 'package:nuolipapp/shared/scanner/identifier_normalization_service.dart';
import 'package:nuolipapp/shared/scanner/scanner_context.dart';
import 'package:nuolipapp/shared/scanner/scanner_session_manager.dart';
import 'package:nuolipapp/shared/scanner/success_feedback_service.dart';
import 'package:nuolipapp/shared/utils/barcode_validation_engine.dart';

void main() {
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

  ScannerContext ctxFor(ItemType t, {Iterable<String> existing = const []}) {
    return ScannerContext.create(
      sessionId: 'test',
      itemType: t,
      itemTypeId: t.id,
      existingValues: existing,
    );
  }

  group('IdentifierNormalizationService', () {
    test('trim / upper / newlines — never strips NCD/NCC letter prefixes', () {
      expect(
        IdentifierNormalizationService.normalize('  ncd100229213\n'),
        'NCD100229213',
      );
      expect(
        IdentifierNormalizationService.normalize('NCD100229213'),
        'NCD100229213',
      );
    });

    test('Lebara spaced ICCID 19 — strip spaces to contiguous digits', () {
      const spaced = '8996 6060 9902 0514 950';
      const expected = '8996606099020514950';
      expect(expected.length, 19);
      expect(
        IdentifierNormalizationService.normalize(spaced),
        expected,
      );
      expect(
        IdentifierNormalizationService.normalize('89966-06099-02051-4950'),
        expected,
      );
    });

    test('STC spaced ICCID 18 — strip spaces', () {
      const spaced = '8996 6060 9902 0521 80';
      const expected = '899660609902052180';
      expect(expected.length, 18);
      expect(
        IdentifierNormalizationService.normalize(spaced),
        expected,
      );
    });
  });

  group('BarcodeRuleRegistry fallback table', () {
    test('N950 / i9100 / i9000S / SIM lengths', () {
      expect(BarcodeRuleRegistry.resolve(itemTypeId: 'n950')!.fullLength, 12);
      expect(BarcodeRuleRegistry.resolve(itemTypeId: 'i9100')!.prefixes, ['SAW']);
      expect(BarcodeRuleRegistry.resolve(itemTypeId: 'i9000s')!.prefixes, ['SAS']);
      expect(BarcodeRuleRegistry.resolve(hintName: 'STC')!.fullLength, 18);
      expect(BarcodeRuleRegistry.resolve(hintName: 'Zain')!.fullLength, 19);
      expect(BarcodeRuleRegistry.resolve(hintName: 'Mobily')!.fullLength, 19);
      expect(BarcodeRuleRegistry.resolve(hintName: 'Repara')!.fullLength, 19);
      expect(BarcodeRuleRegistry.resolve(hintName: 'Lebara')!.fullLength, 19);
      expect(BarcodeRuleRegistry.resolve(hintName: 'ليبارا')!.fullLength, 19);
      expect(BarcodeRuleRegistry.resolve(itemTypeId: 'lebara_sim')!.fullLength, 19);
      expect(BarcodeRuleRegistry.resolve(itemTypeId: 'i9100')!.regex.pattern,
          r'^SAW[0-9]{8}$');
      expect(BarcodeRuleRegistry.resolve(itemTypeId: 'i9000s')!.regex.pattern,
          r'^SAS[0-9]{8}$');
    });

    test('enterprise rules win over loose API alphanumeric regex', () {
      final loose = ItemType(
        id: 'uuid-i9100',
        nameEn: 'Urovo i9100',
        nameAr: 'i9100',
        sortOrder: 1,
        isActive: true,
        isVisible: true,
        category: 'devices',
        requiresSerial: true,
        serialPrefix: 'SAW',
        serialLength: 11,
        serialRegex: r'^SAW[A-Z0-9]{8}$', // loose — must NOT be used
      );
      final rule = BarcodeRuleRegistry.fromItemType(loose)!;
      expect(rule.regex.pattern, r'^SAW[0-9]{8}$');
      expect(rule.matches('SAW12345678'), isTrue);
      expect(rule.matches('SAW12AB5678'), isFalse);
    });

    test('unknown type fail closed', () {
      expect(BarcodeRuleRegistry.resolve(itemTypeId: 'unknown-xyz'), isNull);
    });
  });

  group('Smart Scanner V2 — Tests 1–7', () {
    test('Test 1 — N950 carton: accept only NCD serial; ignore GTIN/PN', () {
      final ctx = ctxFor(n950);
      final selector = BarcodeCandidateSelector();
      final result = selector.selectRaw(
        const [
          '6972910590206',
          '58NCB-GC8LBE5651100',
          'NCB-GC8LBE5651',
          'NCD100229213',
        ],
        context: ctx,
        confidence: 1.0,
      );

      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, 'NCD100229213');

      // Proof GTIN / PN ignored by engine against N950 context
      expect(
        BarcodeValidationEngine.validate('6972910590206', context: ctx).isValid,
        isFalse,
      );
      expect(
        BarcodeValidationEngine.validate('58NCB-GC8LBE5651100', context: ctx)
            .isValid,
        isFalse,
      );
      expect(
        BarcodeValidationEngine.validate('NCB-GC8LBE5651', context: ctx).isValid,
        isFalse,
      );
      expect(
        BarcodeValidationEngine.validate('NCD100229213', context: ctx).isValid,
        isTrue,
      );
      expect(
        BarcodeValidationEngine.validate('NCD100229213', context: ctx).normalized,
        'NCD100229213',
      );
    });

    test('Test 1b — single GTIN frame alone: silent noMatch (never accept)', () {
      final ctx = ctxFor(n950);
      final result = BarcodeCandidateSelector().selectRaw(
        const ['6972910590206'],
        context: ctx,
        confidence: 1.0,
      );
      expect(result.status, CandidateStatus.noMatch);
      expect(result.selected, isNull);
    });

    test('Test 1c — fail closed when type unknown / no rules', () {
      final unknown = ItemType(
        id: 'unknown-xyz',
        nameEn: 'Unknown',
        nameAr: 'غير معروف',
        sortOrder: 99,
        isActive: true,
        isVisible: true,
        category: 'devices',
        requiresSerial: true,
      );
      final ctx = ScannerContext.create(
        sessionId: 'x',
        itemType: unknown,
        itemTypeId: unknown.id,
      );
      expect(ctx.hasTrustedRules, isFalse);
      expect(ctx.effectiveRules, isEmpty);
      final result = BarcodeCandidateSelector().selectRaw(
        const ['NCD100229213', '6972910590206'],
        context: ctx,
        confidence: 1.0,
      );
      expect(result.status, CandidateStatus.noMatch);
    });

    test('Test 2 — wrong type serial (SAW) ignored for N950', () {
      final ctx = ctxFor(n950);
      final result = BarcodeCandidateSelector().selectRaw(
        const ['SAW12345678'],
        context: ctx,
        confidence: 1.0,
      );
      expect(result.status, CandidateStatus.noMatch);
      expect(result.selected, isNull);
      expect(
        BarcodeValidationEngine.validate('SAW12345678', context: ctx).isValid,
        isFalse,
      );
    });

    test('Test 3 — same serial across 10 frames: session accepts once + beep once',
        () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SuccessFeedbackService.audioEnabled = false;
      final session = ScannerSessionManager();
      final feedback = SuccessFeedbackService();
      session.markScanning();

      var accepts = 0;
      for (var i = 0; i < 10; i++) {
        if (!session.isOpen || session.isLocked) continue;
        final ctx = ctxFor(n950);
        final pick = BarcodeCandidateSelector().selectRaw(
          const ['NCD100229213'],
          context: ctx,
          confidence: 1.0,
        );
        if (pick.status != CandidateStatus.singleMatch) continue;
        // Lock BEFORE any await (mirrors widget contract).
        if (!session.tryLock()) continue;
        session.accept(pick.selected!);
        accepts++;
        await feedback.fire();
        session.close();
      }

      expect(accepts, 1);
      expect(session.successCount, 1);
      expect(feedback.hasFired, isTrue);
      await feedback.fire(); // no-op
      expect(feedback.hasFired, isTrue);
      expect(session.state, ScannerState.closed);
      await feedback.dispose();
    });

    test('Test 4 — multiple valid serials in scene: no random pick', () {
      final ctx = ctxFor(n950);
      final result = BarcodeCandidateSelector().selectRaw(
        const ['NCD100229213', 'NCC100229214'],
        context: ctx,
        confidence: 1.0,
      );
      expect(result.status, CandidateStatus.ambiguous);
      expect(result.selected, isNull);
      expect(result.guidanceMessage, contains('الإطار'));
    });

    test('Test 5 — duplicate in form: toast path, no success', () {
      final guard = DuplicateScannerGuard()
        ..seedExisting(const ['NCD100229213']);
      expect(guard.isDuplicate('NCD100229213'), isTrue);
      expect(guard.shouldShowToast(), isTrue);
      expect(guard.shouldShowToast(), isFalse); // cooldown
      expect(DuplicateScannerGuard.duplicateMessage,
          'تمت إضافة هذا الرقم مسبقًا.');

      final session = ScannerSessionManager()..markScanning();
      // Duplicate handling must NOT lock/accept
      expect(session.isLocked, isFalse);
      expect(session.successCount, 0);
    });

    test('Test 6 — i9100 accepts SAW only; ignores NCD', () {
      final ctx = ctxFor(i9100);
      final result = BarcodeCandidateSelector().selectRaw(
        const ['SAW12345678', 'NCD100229213'],
        context: ctx,
        confidence: 1.0,
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, 'SAW12345678');
      expect(
        BarcodeValidationEngine.validate('NCD100229213', context: ctx).isValid,
        isFalse,
      );
    });

    test('Test 7 — STC: reject 19-digit 89966; accept 18-digit', () {
      final ctx = ctxFor(stc);
      const iccid19 = '8996606099020521804'; // 19
      const iccid18 = '899660609902052180'; // 18

      expect(iccid19.length, 19);
      expect(iccid18.length, 18);

      expect(
        BarcodeValidationEngine.validate(iccid19, context: ctx).isValid,
        isFalse,
      );
      final reject = BarcodeCandidateSelector().selectRaw(
        const [iccid19],
        context: ctx,
        confidence: 1.0,
      );
      expect(reject.status, CandidateStatus.noMatch);

      final accept = BarcodeCandidateSelector().selectRaw(
        const [iccid18],
        context: ctx,
        confidence: 1.0,
      );
      expect(accept.status, CandidateStatus.singleMatch);
      expect(accept.selected, iccid18);
    });
  });

  group('Smart Scanner V2 — all types carton multi-barcode', () {
    const gtin = '6972910590206';
    const pn = '58NCB-GC8LBE5651100';
    const n950Serial = 'NCD100229213';
    const saw = 'SAW12345678';
    const sas = 'SAS87654321';
    const iccid19 = '8996606099020521804';
    const iccid18 = '899660609902052180';

    test('i9100 carton: accept SAW only; ignore GTIN/PN/NCD/SAS/SIM', () {
      final ctx = ctxFor(i9100);
      final result = BarcodeCandidateSelector().selectRaw(
        const [gtin, pn, n950Serial, sas, iccid19, saw],
        context: ctx,
        confidence: 1.0,
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, saw);
      expect(result.selected!.startsWith('SAW'), isTrue);
      expect(
        BarcodeValidationEngine.validate(n950Serial, context: ctx).isValid,
        isFalse,
      );
      expect(
        BarcodeValidationEngine.validate(sas, context: ctx).isValid,
        isFalse,
      );
    });

    test('i9000S carton: accept SAS only; ignore SAW/NCD/GTIN/SIM', () {
      final ctx = ctxFor(i9000s);
      final result = BarcodeCandidateSelector().selectRaw(
        const [gtin, pn, n950Serial, saw, iccid18, sas],
        context: ctx,
        confidence: 1.0,
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, sas);
      expect(
        BarcodeValidationEngine.validate(saw, context: ctx).isValid,
        isFalse,
      );
      expect(
        BarcodeValidationEngine.validate('SAS12AB5678', context: ctx).isValid,
        isFalse,
      );
    });

    test('Zain 19 carton: accept 19 ICCID; ignore 18/GTIN/NCD/SAW', () {
      final ctx = ctxFor(zain);
      final result = BarcodeCandidateSelector().selectRaw(
        const [gtin, n950Serial, saw, iccid18, iccid19],
        context: ctx,
        confidence: 1.0,
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, iccid19);
      expect(result.selected!.length, 19);
      expect(
        BarcodeValidationEngine.validate(iccid18, context: ctx).isValid,
        isFalse,
      );
    });

    test('Mobily 19 carton: same rule as Zain', () {
      final ctx = ctxFor(mobily);
      final result = BarcodeCandidateSelector().selectRaw(
        const [gtin, iccid18, pn, iccid19],
        context: ctx,
        confidence: 1.0,
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, iccid19);
    });

    test('Repara 19 carton: same rule as Zain', () {
      final ctx = ctxFor(repara);
      final result = BarcodeCandidateSelector().selectRaw(
        const [n950Serial, iccid18, iccid19],
        context: ctx,
        confidence: 1.0,
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, iccid19);
    });

    test('Lebara 19 spaced ICCID accepted after normalize', () {
      final ctx = ctxFor(lebara);
      const spaced = '8996 6060 9902 0514 950';
      const expected = '8996606099020514950';
      expect(expected.length, 19);

      final engine = BarcodeValidationEngine.validate(spaced, context: ctx);
      expect(engine.isValid, isTrue);
      expect(engine.normalized, expected);

      final result = BarcodeCandidateSelector().selectRaw(
        const [spaced, gtin, n950Serial],
        context: ctx,
        confidence: 1.0,
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, expected);
    });

    test('STC 18 spaced ICCID accepted after normalize', () {
      final ctx = ctxFor(stc);
      const spaced = '8996 6060 9902 0521 80';
      const expected = '899660609902052180';
      expect(expected.length, 18);
      final engine = BarcodeValidationEngine.validate(spaced, context: ctx);
      expect(engine.isValid, isTrue);
      expect(engine.normalized, expected);
    });

    test('SIM union: STC selected still accepts Lebara 19 via allowed types', () {
      final ctx = ScannerContext.create(
        sessionId: 'union_sim',
        itemType: stc,
        itemTypeId: stc.id,
        allowedItemTypes: [stc, lebara, zain],
        categoryHint: 'sim',
      );
      const lebaraIccid = '8996606099020514950';
      expect(lebaraIccid.length, 19);
      expect(
        BarcodeValidationEngine.validate(lebaraIccid, context: ctx).isValid,
        isTrue,
      );
      expect(
        BarcodeValidationEngine.validate(iccid18, context: ctx).isValid,
        isTrue,
      );
    });

    test('STC 18 carton: accept 18 ICCID; ignore 19/GTIN/device serials', () {
      final ctx = ctxFor(stc);
      final result = BarcodeCandidateSelector().selectRaw(
        const [gtin, n950Serial, saw, iccid19, iccid18],
        context: ctx,
        confidence: 1.0,
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, iccid18);
      expect(result.selected!.length, 18);
      expect(
        BarcodeValidationEngine.validate(iccid19, context: ctx).isValid,
        isFalse,
      );
    });

    test('opaque prefix preserved for SAW/SAS/ICCID', () {
      expect(
        BarcodeValidationEngine.validate(saw, context: ctxFor(i9100))
            .normalized,
        saw,
      );
      expect(
        BarcodeValidationEngine.validate(sas, context: ctxFor(i9000s))
            .normalized,
        sas,
      );
      expect(
        BarcodeValidationEngine.validate(iccid19, context: ctxFor(zain))
            .normalized,
        iccid19,
      );
    });

    test('bare digits rejected for i9100 / i9000S (no auto-prepend)', () {
      expect(
        BarcodeValidationEngine.validate('12345678', context: ctxFor(i9100))
            .isValid,
        isFalse,
      );
      expect(
        BarcodeValidationEngine.validate('87654321', context: ctxFor(i9000s))
            .isValid,
        isFalse,
      );
    });
  });

  group('Session lock before await', () {
    test('tryLock then accept is synchronous; closed rejects further locks', () {
      final session = ScannerSessionManager()..markScanning();
      expect(session.tryLock(), isTrue);
      session.accept('NCD100229213');
      expect(session.state, ScannerState.accepted);
      expect(session.tryLock(), isFalse);
      session.close();
      expect(session.state, ScannerState.closed);
      expect(session.tryLock(), isFalse);
    });
  });

  group('Opaque serial policy', () {
    test('bare digits REJECT for N950 (no auto-prepend)', () {
      final ctx = ctxFor(n950);
      final r =
          BarcodeValidationEngine.validate('100232013', context: ctx);
      expect(r.isValid, isFalse);
      expect(r.normalized, '100232013');
    });

    test('never strips alphabetic prefix', () {
      expect(
        BarcodeValidationEngine.normalize('NCD100229213'),
        'NCD100229213',
      );
      expect(
        BarcodeValidationEngine.validate('NCC100229213', context: ctxFor(n950))
            .normalized,
        'NCC100229213',
      );
    });
  });
}
