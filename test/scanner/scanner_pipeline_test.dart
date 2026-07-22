import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/shared/models/item_type.dart';
import 'package:nuolipapp/shared/scanner/barcode_candidate_selector.dart';
import 'package:nuolipapp/shared/scanner/duplicate_scanner_guard.dart';
import 'package:nuolipapp/shared/scanner/scanner_context.dart';
import 'package:nuolipapp/shared/scanner/scanner_session_manager.dart';
import 'package:nuolipapp/shared/utils/barcode_validation_engine.dart';

// ---------------------------------------------------------------------------
// ItemType fixtures
// ---------------------------------------------------------------------------

/// Newland N950 — full API config present: prefix/length/regex all set.
final _n950 = ItemType(
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

/// Urovo i9100 — SAW prefix only.
final _i9100 = ItemType(
  id: 'i9100',
  nameEn: 'Urovo i9100',
  nameAr: 'Urovo i9100',
  sortOrder: 2,
  isActive: true,
  isVisible: true,
  category: 'devices',
  requiresSerial: true,
  serialPrefix: 'SAW',
  serialLength: 11,
  serialRegex: r'^SAW[A-Z0-9]{8}$', // loose API — enterprise digits-only wins
);

/// Urovo i9000S — SAS prefix only.
final _i9000s = ItemType(
  id: 'i9000s',
  nameEn: 'Urovo i9000S',
  nameAr: 'Urovo i9000S',
  sortOrder: 3,
  isActive: true,
  isVisible: true,
  category: 'devices',
  requiresSerial: true,
  serialPrefix: 'SAS',
  serialLength: 11,
  serialRegex: r'^SAS[A-Z0-9]{8}$',
);

/// STC SIM — serialLength=null triggers fallback lookup by id ('stc' → sim_stc = 18-digit rule).
final _stcSim = ItemType(
  id: 'stc_sim',
  nameEn: 'STC SIM',
  nameAr: 'شريحة STC',
  sortOrder: 4,
  isActive: true,
  isVisible: true,
  category: 'sim',
  requiresSerial: true,
  serialPrefix: '89966',
  serialLength: null,
  serialRegex: r'^89966[0-9]{13,14}$',
);

/// Zain SIM — id 'zain_sim' triggers fallback lookup 'zain' → sim_89966_19 (19-digit rule).
final _zainSim = ItemType(
  id: 'zain_sim',
  nameEn: 'Zain SIM',
  nameAr: 'شريحة زين',
  sortOrder: 5,
  isActive: true,
  isVisible: true,
  category: 'sim',
  requiresSerial: true,
  serialPrefix: '89966',
  serialLength: null,
  serialRegex: r'^89966[0-9]{13,14}$',
);

/// Mobily SIM — 19-digit same as Zain.
final _mobilySim = ItemType(
  id: 'mobily_sim',
  nameEn: 'Mobily SIM',
  nameAr: 'شريحة موبايلي',
  sortOrder: 6,
  isActive: true,
  isVisible: true,
  category: 'sim',
  requiresSerial: true,
  serialPrefix: '89966',
  serialLength: 19,
  serialRegex: r'^89966[0-9]{14}$',
);

/// Repara SIM — 19-digit same as Zain.
final _reparaSim = ItemType(
  id: 'repara_sim',
  nameEn: 'Repara SIM',
  nameAr: 'شريحة ريبارا',
  sortOrder: 7,
  isActive: true,
  isVisible: true,
  category: 'sim',
  requiresSerial: true,
  serialPrefix: '89966',
  serialLength: 19,
  serialRegex: r'^89966[0-9]{14}$',
);

/// Lebara SIM — 19-digit 89966 (same family as Zain/Mobily/Repara).
final _lebaraSim = ItemType(
  id: 'lebara_sim',
  nameEn: 'Lebara SIM',
  nameAr: 'شريحة ليبارا',
  sortOrder: 8,
  isActive: true,
  isVisible: true,
  category: 'sim',
  requiresSerial: true,
  serialPrefix: '89966',
  serialLength: 19,
  serialRegex: r'^89966[0-9]{14}$',
);

// ---------------------------------------------------------------------------
// Helper: build a context for a given item type.
// ---------------------------------------------------------------------------

ScannerContext _ctx(ItemType itemType) => ScannerContext.create(
      sessionId: 'test',
      itemType: itemType,
    );

// ---------------------------------------------------------------------------
// Test 1 — N950 carton: 4 barcodes in frame, only device serial accepted
// ---------------------------------------------------------------------------
void main() {
  group('Test 1 — N950 carton: 4 barcodes, exactly 1 valid N950', () {
    test('selects NCD100232013 and ignores SIM, carton, and noise', () {
      final sel = BarcodeCandidateSelector();
      final result = sel.selectRaw(
        ['NCD100232013', '8996606099020521804', 'RANDOM-XYZ', 'BOX-2024-001'],
        context: _ctx(_n950),
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, 'NCD100232013');
    });

    test('lowercase ncd100232013 normalizes to NCD100232013', () {
      final sel = BarcodeCandidateSelector();
      final result = sel.selectRaw(
        ['ncd100232013', 'JUNK', 'BOX-9'],
        context: _ctx(_n950),
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, 'NCD100232013');
    });

    test('NCC prefix variant also accepted', () {
      final sel = BarcodeCandidateSelector();
      final result = sel.selectRaw(['NCC100232013'], context: _ctx(_n950));
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, 'NCC100232013');
    });
  });

  // -------------------------------------------------------------------------
  // Test 2 — Wrong-type reject: wrong prefix in context
  // -------------------------------------------------------------------------
  group('Test 2 — Wrong-type reject', () {
    test('SAW serial → noMatch in N950 context', () {
      final sel = BarcodeCandidateSelector();
      final result = sel.selectRaw(['SAW12345678'], context: _ctx(_n950));
      expect(result.status, CandidateStatus.noMatch);
      expect(result.selected, isNull);
    });

    test('NCD serial → noMatch in i9100 context', () {
      final sel = BarcodeCandidateSelector();
      final result = sel.selectRaw(['NCD100232013'], context: _ctx(_i9100));
      expect(result.status, CandidateStatus.noMatch);
    });

    test('SIM ICCID → noMatch in N950 context (length mismatch)', () {
      final sel = BarcodeCandidateSelector();
      final result = sel.selectRaw(['8996606099020521804'], context: _ctx(_n950));
      expect(result.status, CandidateStatus.noMatch);
    });
  });

  // -------------------------------------------------------------------------
  // Test 3 — Session lock: 10 consecutive frames → exactly one accept
  // -------------------------------------------------------------------------
  group('Test 3 — ScannerSessionManager: 10-frame single accept', () {
    test('tryLock grants once, then blocks all 9 subsequent calls', () {
      final session = ScannerSessionManager();
      expect(session.tryLock(), isTrue);  // transitions to validating
      session.accept('NCD100232013');      // transitions to accepted

      for (int i = 0; i < 9; i++) {
        expect(session.tryLock(), isFalse,
            reason: 'frame ${i + 2}: session already accepted');
      }
    });

    test('isOpen is false after accept', () {
      final session = ScannerSessionManager();
      session.tryLock();
      session.accept('NCD100232013');
      expect(session.isOpen, isFalse);
    });

    test('resetForNextScan restores lock availability for multi-scan', () {
      final session = ScannerSessionManager();
      session.tryLock();
      session.accept('NCD100232013');
      session.resetForNextScan();
      expect(session.tryLock(), isTrue);
    });

    test('close() makes isOpen false and prevents any future lock', () {
      final session = ScannerSessionManager();
      session.close();
      expect(session.isOpen, isFalse);
      expect(session.tryLock(), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Test 4 — Ambiguous: two distinct valid N950 serials in same frame
  // -------------------------------------------------------------------------
  group('Test 4 — Ambiguous frame: two valid N950 serials → refuse to pick', () {
    test('two distinct valid N950 → ambiguous, selected is null', () {
      final sel = BarcodeCandidateSelector();
      final result = sel.selectRaw(
        ['NCD100232013', 'NCC987654321'],
        context: _ctx(_n950),
      );
      expect(result.status, CandidateStatus.ambiguous);
      expect(result.selected, isNull);
    });

    test('same serial decoded twice in one frame → singleMatch (deduped)', () {
      // Camera sometimes emits the same label twice per capture.
      final sel = BarcodeCandidateSelector();
      final result = sel.selectRaw(
        ['NCD100232013', 'NCD100232013'],
        context: _ctx(_n950),
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, 'NCD100232013');
    });
  });

  // -------------------------------------------------------------------------
  // Test 5 — Duplicate guard with 2-second toast cooldown
  // -------------------------------------------------------------------------
  group('Test 5 — DuplicateScannerGuard', () {
    test('isDuplicate false before markAccepted', () {
      final guard = DuplicateScannerGuard();
      expect(guard.isDuplicate('NCD100232013'), isFalse);
    });

    test('isDuplicate true after markAccepted', () {
      final guard = DuplicateScannerGuard();
      guard.markAccepted('NCD100232013');
      expect(guard.isDuplicate('NCD100232013'), isTrue);
    });

    test('isDuplicate is case-insensitive (normalises to upper)', () {
      final guard = DuplicateScannerGuard();
      guard.markAccepted('ncd100232013');
      expect(guard.isDuplicate('NCD100232013'), isTrue);
    });

    test('shouldShowToast returns true on first call', () {
      final guard = DuplicateScannerGuard();
      expect(guard.shouldShowToast(), isTrue);
    });

    test('shouldShowToast throttled within 2s cooldown', () {
      final guard = DuplicateScannerGuard();
      guard.shouldShowToast(); // records now
      expect(guard.shouldShowToast(), isFalse); // within cooldown
    });

    test('different serials are independent', () {
      final guard = DuplicateScannerGuard();
      guard.markAccepted('NCD100232013');
      expect(guard.isDuplicate('NCC987654321'), isFalse);
    });

    test('remove() restores isDuplicate to false', () {
      final guard = DuplicateScannerGuard();
      guard.markAccepted('NCD100232013');
      guard.remove('NCD100232013');
      expect(guard.isDuplicate('NCD100232013'), isFalse);
    });

    test('seedExisting: existing values count as duplicates', () {
      final guard = DuplicateScannerGuard();
      guard.seedExisting(['NCD100232013', 'NCC000000001']);
      expect(guard.isDuplicate('NCD100232013'), isTrue);
      expect(guard.isDuplicate('NCC000000001'), isTrue);
      expect(guard.isDuplicate('NCC999999999'), isFalse);
    });

    test('clear() resets all accepted state', () {
      final guard = DuplicateScannerGuard();
      guard.markAccepted('NCD100232013');
      guard.clear();
      expect(guard.isDuplicate('NCD100232013'), isFalse);
      expect(guard.count, 0);
    });
  });

  // -------------------------------------------------------------------------
  // Test 6 — i9100 context: SAW prefix required, others rejected
  // -------------------------------------------------------------------------
  group('Test 6 — i9100 context: SAW-only acceptance', () {
    test('SAW serial accepted under i9100', () {
      final sel = BarcodeCandidateSelector();
      final result = sel.selectRaw(['SAW12345678'], context: _ctx(_i9100));
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, 'SAW12345678');
    });

    test('NCD serial rejected under i9100', () {
      final sel = BarcodeCandidateSelector();
      expect(
        sel.selectRaw(['NCD100232013'], context: _ctx(_i9100)).status,
        CandidateStatus.noMatch,
      );
    });

    test('SAS serial rejected under i9100 (SAW-only)', () {
      final sel = BarcodeCandidateSelector();
      expect(
        sel.selectRaw(['SAS12345678'], context: _ctx(_i9100)).status,
        CandidateStatus.noMatch,
      );
    });

    test('bare digits rejected for i9100 (no auto-prepend)', () {
      final sel = BarcodeCandidateSelector();
      expect(
        sel.selectRaw(['12345678'], context: _ctx(_i9100)).status,
        CandidateStatus.noMatch,
      );
    });

    test('i9100 carton multi-barcode: SAW wins over GTIN/NCD/SIM', () {
      final sel = BarcodeCandidateSelector();
      final result = sel.selectRaw(
        [
          '6972910590206',
          'NCD100232013',
          '8996606099020521804',
          'SAW12345678',
        ],
        context: _ctx(_i9100),
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, 'SAW12345678');
    });
  });

  // -------------------------------------------------------------------------
  // Test 6b — i9000S context: SAS-only
  // -------------------------------------------------------------------------
  group('Test 6b — i9000S context: SAS-only acceptance', () {
    test('SAS serial accepted under i9000S', () {
      final sel = BarcodeCandidateSelector();
      final result = sel.selectRaw(['SAS87654321'], context: _ctx(_i9000s));
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, 'SAS87654321');
    });

    test('SAW rejected under i9000S', () {
      final sel = BarcodeCandidateSelector();
      expect(
        sel.selectRaw(['SAW12345678'], context: _ctx(_i9000s)).status,
        CandidateStatus.noMatch,
      );
    });

    test('i9000S carton: SAS wins over SAW/NCD/GTIN', () {
      final sel = BarcodeCandidateSelector();
      final result = sel.selectRaw(
        ['SAW12345678', 'NCD100232013', '6972910590206', 'SAS87654321'],
        context: _ctx(_i9000s),
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, 'SAS87654321');
    });
  });

  // -------------------------------------------------------------------------
  // Test 7 — SIM lengths: 18-digit (STC) and 19-digit (Zain/Mobily/Repara)
  // -------------------------------------------------------------------------
  group('Test 7 — STC/Zain/Mobily/Repara SIM: 18 vs 19 ICCIDs', () {
    // Engine-level acceptance (always true for both lengths)
    test('19-digit ICCID valid in engine registry', () {
      const iccid19 = '8996606099020521804';
      final r = BarcodeValidationEngine.validate(iccid19);
      expect(r.isValid, isTrue);
      expect(r.normalized, iccid19);
    });

    test('18-digit ICCID valid in engine registry', () {
      const iccid18 = '899660609902052180';
      final r = BarcodeValidationEngine.validate(iccid18);
      expect(r.isValid, isTrue);
    });

    // Context-level: stcSim → sim_stc fallback rule → 18-digit
    test('18-digit ICCID accepted by stcSim context (sim_stc rule)', () {
      final sel = BarcodeCandidateSelector();
      const iccid18 = '899660609902052180';
      final result = sel.selectRaw([iccid18], context: _ctx(_stcSim));
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, iccid18);
    });

    // Context-level: zainSim → sim_89966_19 fallback rule → 19-digit
    test('19-digit ICCID accepted by zainSim context (sim_89966_19 rule)', () {
      final sel = BarcodeCandidateSelector();
      const iccid19 = '8996606099020521804';
      final result = sel.selectRaw([iccid19], context: _ctx(_zainSim));
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, iccid19);
    });

    test('Mobily carton: 19 accepted; 18/GTIN/NCD ignored', () {
      final sel = BarcodeCandidateSelector();
      const iccid19 = '8996606099020521804';
      const iccid18 = '899660609902052180';
      final result = sel.selectRaw(
        ['6972910590206', 'NCD100232013', iccid18, iccid19],
        context: _ctx(_mobilySim),
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, iccid19);
    });

    test('Repara carton: 19 accepted; 18 ignored', () {
      final sel = BarcodeCandidateSelector();
      const iccid19 = '8996606099020521804';
      const iccid18 = '899660609902052180';
      final result = sel.selectRaw(
        [iccid18, iccid19],
        context: _ctx(_reparaSim),
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, iccid19);
    });

    test('Lebara spaced 19 ICCID accepted; N950 preserved', () {
      final sel = BarcodeCandidateSelector();
      const spaced = '8996 6060 9902 0514 950';
      const expected = '8996606099020514950';
      expect(expected.length, 19);
      final result = sel.selectRaw(
        [spaced, 'NCD100232013'],
        context: _ctx(_lebaraSim),
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, expected);

      // N950 excellence: letter prefix never stripped / still matches device rule.
      final n950 = sel.selectRaw(
        ['NCD100232013'],
        context: _ctx(_n950),
      );
      expect(n950.status, CandidateStatus.singleMatch);
      expect(n950.selected, 'NCD100232013');
    });

    test('STC spaced 18 ICCID accepted', () {
      final sel = BarcodeCandidateSelector();
      const spaced = '8996 6060 9902 0521 80';
      const expected = '899660609902052180';
      expect(expected.length, 18);
      final result = sel.selectRaw([spaced], context: _ctx(_stcSim));
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, expected);
    });

    test('STC carton: 18 accepted; 19/device serials ignored', () {
      final sel = BarcodeCandidateSelector();
      const iccid19 = '8996606099020521804';
      const iccid18 = '899660609902052180';
      final result = sel.selectRaw(
        ['NCD100232013', 'SAW12345678', iccid19, iccid18],
        context: _ctx(_stcSim),
      );
      expect(result.status, CandidateStatus.singleMatch);
      expect(result.selected, iccid18);
    });

    test('non-89966 prefix rejected in both SIM contexts', () {
      final sel = BarcodeCandidateSelector();
      const wrong = '79966060990205218';
      expect(
        sel.selectRaw([wrong], context: _ctx(_stcSim)).status,
        CandidateStatus.noMatch,
      );
      expect(
        sel.selectRaw([wrong], context: _ctx(_zainSim)).status,
        CandidateStatus.noMatch,
      );
    });
  });

  // -------------------------------------------------------------------------
  // Opaque serial contract — prefixes must NEVER be stripped
  // -------------------------------------------------------------------------
  group('Opaque serial contract', () {
    test('NCD prefix preserved end-to-end through selector', () {
      final sel = BarcodeCandidateSelector();
      final result = sel.selectRaw(['NCD100232013'], context: _ctx(_n950));
      expect(result.selected, startsWith('NCD'));
      expect(result.selected, 'NCD100232013',
          reason: 'NCD prefix must NEVER be stripped');
    });

    test('bare digits 100232013 rejected — no auto-prepend NCD/NCC', () {
      final sel = BarcodeCandidateSelector();
      final result = sel.selectRaw(['100232013'], context: _ctx(_n950));
      expect(result.status, CandidateStatus.noMatch,
          reason: 'bare digits must not be silently accepted as N950');
    });

    test('SAW prefix preserved for i9100', () {
      final sel = BarcodeCandidateSelector();
      final result = sel.selectRaw(['SAW12345678'], context: _ctx(_i9100));
      expect(result.selected, startsWith('SAW'));
    });
  });
}
