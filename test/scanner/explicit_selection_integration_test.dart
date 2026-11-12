import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/features/moving_inventory/data/models/scanned_batch_item.dart';
import 'package:nuolipapp/shared/models/item_type.dart';
import 'package:nuolipapp/shared/scanner/explicit_selection_scan.dart';
import 'package:nuolipapp/shared/utils/barcode_validator.dart';

/// Six integration tests for the FINAL shipment-scan rule:
///
///   explicit dropdown selection is final for `itemTypeId`; validated ONLY
///   against the selected type's own rule; failure → error naming the
///   selected type, no fallback, no alternative offered; no explicit
///   selection (the auto-defaulted first item does not count) → the scan is
///   blocked and nothing is saved.
///
/// "Integration" here = the real shared code path the page uses end to end:
/// `explicitSelectedType` → `classifyScan` / `processScanBatch` →
/// `ScannedBatchItem.fromSelection` → `buildBatchScanInBody` (the exact JSON
/// posted to `/api/serialized-items/batch-scan-in`). The server half (API →
/// DB → admin search) is outside this Flutter repo and is NOT exercised here.
void main() {
  // ---- Fixtures shaped like the live production catalog (read-only query) --
  ItemType sim(String id, String en, String ar,
          {String? regex, String? prefix, int sort = 1}) =>
      ItemType(
        id: id,
        nameEn: en,
        nameAr: ar,
        sortOrder: sort,
        isActive: true,
        isVisible: true,
        category: 'sim',
        requiresSerial: regex != null,
        serialPrefix: prefix,
        serialRegex: regex,
      );

  ItemType device(String id, String prefix, int len, String regex,
          {int sort = 1}) =>
      ItemType(
        id: id,
        nameEn: id,
        nameAr: id,
        sortOrder: sort,
        isActive: true,
        isVisible: true,
        category: 'devices',
        requiresSerial: true,
        serialPrefix: prefix,
        serialLength: len,
        serialRegex: regex,
      );

  // Production: mobilySim and stcSim carry the IDENTICAL live regex.
  final mobily = sim('mobilySim', 'Mobily SIM', 'شريحة موبايلي',
      regex: r'^89966[0-9]{13,14}$', prefix: '89966', sort: 7);
  final stc = sim('stcSim', 'STC SIM', 'شريحة STC',
      regex: r'^89966[0-9]{13,14}$', prefix: '89966', sort: 8);
  // Production: the active "Zain SIM New" row has NO serialPrefix/serialRegex.
  final zainNew = sim('97956dd0-81f3-4720-a096-f18d5a979137', 'Zain SIM New',
      'شريحة زين الجديدة', sort: 9);
  // A carrier whose name says nothing recognizable (carrier label unknown).
  final virgin = sim('virginSim', 'Virgin Mobile SIM', 'شريحة فيرجن',
      regex: r'^89966[0-9]{15}$', prefix: '89966', sort: 20);

  final n950 = device('n950', 'NCC,NCD', 12, r'^(NCC|NCD)[0-9]{9}$', sort: 1);
  final i9000s = device('i9000s', 'SAS', 14, r'^SAS[0-9]{11}$', sort: 2);
  final a960 = device('A960', '', 10, r'^[0-9]{10}$', sort: 3);
  final i9100 = device('i9100', 'SAW', 14, r'^SAW[0-9]{11}$', sort: 4);
  final deviceCatalog = [n950, i9000s, a960, i9100]; // first = n950

  // 19-digit ICCID valid for BOTH mobilySim and stcSim rules.
  const sharedIccid = '8996609824123456789';

  // ==========================================================================
  group('1. Mobily explicitly selected + ICCID matching BOTH Mobily and STC',
      () {
    test(
        'validated against Mobily ONLY; itemTypeId stays mobilySim; no '
        'alternative is offered or searched', () {
      // Precondition proving the scenario is real: both rules accept it.
      expect(BarcodeValidator.validate(sharedIccid, mobily), isNull);
      expect(BarcodeValidator.validate(sharedIccid, stc), isNull);

      final outcome =
          classifyScan(rawCode: sharedIccid, explicitSelected: mobily);
      expect(outcome.isAccepted, isTrue);
      expect(outcome.type!.id, 'mobilySim');
      expect(outcome.error, isNull); // nothing to choose between, no prompt

      // Through the batch/camera path too — the only candidate ever reported
      // to the caller is the selected one.
      final accepted = <(ItemType, String)>[];
      final res = processScanBatch(
        codes: [sharedIccid],
        explicitSelected: mobily,
        isDuplicate: (_, _) => false,
        onAccepted: (t, s) => accepted.add((t, s)),
      );
      expect(res.added, 1);
      expect(accepted.map((a) => a.$1.id).toList(), ['mobilySim']);
    });

    test('the mirror case: STC explicitly selected + the same ICCID → '
        'stcSim, not Mobily', () {
      final outcome =
          classifyScan(rawCode: sharedIccid, explicitSelected: stc);
      expect(outcome.isAccepted, isTrue);
      expect(outcome.type!.id, 'stcSim');
    });
  });

  // ==========================================================================
  group('2. "Zain SIM New" selected + a non-matching number', () {
    test(
        'clear error NAMING Zain SIM New; no other type searched; nothing '
        'saved; selected itemTypeId unchanged', () {
      // A number that would be perfectly valid for STC/Mobily must still be
      // rejected — the selection is final, no alternative is considered.
      for (final code in [sharedIccid, 'NOT-A-SERIAL', '12345']) {
        final outcome = classifyScan(rawCode: code, explicitSelected: zainNew);
        expect(outcome.isAccepted, isFalse, reason: code);
        expect(outcome.kind, ScanOutcomeKind.rejectedBySelectedType);
        expect(outcome.type, isNull); // no type assigned, none substituted
        expect(outcome.error, contains('شريحة زين الجديدة'));
        // No alternative named or offered.
        expect(outcome.error, isNot(contains('STC')));
        expect(outcome.error, isNot(contains('موبايلي')));
      }

      // Batch path: nothing added, callbacks never invoked for an accept.
      var accepted = 0;
      final res = processScanBatch(
        codes: [sharedIccid, '12345'],
        explicitSelected: zainNew,
        isDuplicate: (_, _) => false,
        onAccepted: (_, _) => accepted++,
      );
      expect(res.added, 0);
      expect(accepted, 0);
      expect(res.firstError, contains('شريحة زين الجديدة'));

      // The selected type object itself is untouched.
      expect(zainNew.id, '97956dd0-81f3-4720-a096-f18d5a979137');
    });
  });

  // ==========================================================================
  group('3. default/first list item is NOT explicit → scan is blocked', () {
    test('attempting a scan without picking: blocked, prompts to select, '
        'nothing saved (manual + camera/batch)', () {
      // Page state right after init: first item auto-selected, flag false.
      final selected = explicitSelectedType(
        types: deviceCatalog,
        selectedItemTypeId: deviceCatalog.first.id, // the auto-default
        explicitlySelected: false,
      );
      expect(selected, isNull);

      // Manual entry of a perfectly valid N950 serial → blocked.
      final manual =
          classifyScan(rawCode: 'NCD100232013', explicitSelected: selected);
      expect(manual.isAccepted, isFalse);
      expect(manual.kind, ScanOutcomeKind.blockedNoExplicitSelection);
      expect(manual.error, kExplicitSelectionRequiredMessage);
      expect(manual.type, isNull);
      expect(manual.displaySerial, isNull);

      // Camera batch → whole batch blocked, nothing added, no duplicate
      // checks even attempted.
      var dupChecks = 0;
      var accepted = 0;
      final batch = processScanBatch(
        codes: ['NCD100232013', 'SAS12345678'],
        explicitSelected: selected,
        isDuplicate: (_, _) {
          dupChecks++;
          return false;
        },
        onAccepted: (_, _) => accepted++,
      );
      expect(batch.added, 0);
      expect(batch.firstError, kExplicitSelectionRequiredMessage);
      expect(dupChecks, 0);
      expect(accepted, 0);

      // An unchanged echo from the scanner screen does NOT promote the
      // auto-default to a deliberate pick…
      expect(
        explicitAfterScannerReturn(
            idBeforeScan: 'n950', returnedId: 'n950', currentlyExplicit: false),
        isFalse,
      );
      // …a CHANGED value does, and an explicit pick is never downgraded.
      expect(
        explicitAfterScannerReturn(
            idBeforeScan: 'n950', returnedId: 'i9100', currentlyExplicit: false),
        isTrue,
      );
      expect(
        explicitAfterScannerReturn(
            idBeforeScan: 'n950', returnedId: 'n950', currentlyExplicit: true),
        isTrue,
      );

      // After a deliberate pick the same scan is accepted as that type.
      final picked = explicitSelectedType(
        types: deviceCatalog,
        selectedItemTypeId: 'n950',
        explicitlySelected: true,
      );
      expect(classifyScan(rawCode: 'NCD100232013', explicitSelected: picked)
          .type!.id, 'n950');
    });
  });

  // ==========================================================================
  group('4. batch: type A scan, explicitly switch to B, scan again, ONE batch',
      () {
    test('each item keeps its own itemTypeId in the actual request payload',
        () {
      final items = <ScannedBatchItem>[];

      void scanManual(String raw, ItemType explicit, {String? carrier}) {
        final o = classifyScan(rawCode: raw, explicitSelected: explicit);
        expect(o.isAccepted, isTrue, reason: '$raw as ${explicit.id}');
        items.add(ScannedBatchItem.fromSelection(
          type: o.type!,
          displaySerial: o.displaySerial!,
          explicitCarrier: carrier,
        ));
      }

      scanManual('NCD100232013', n950); // type A (device)
      scanManual(sharedIccid, mobily); // explicitly switch → type B (SIM)
      scanManual('SAW12345678', i9100); // switch again → type C
      scanManual(sharedIccid.replaceFirst('9824', '9825'), stc); // type D

      // Camera batch under the CURRENT explicit selection adds more items
      // without disturbing the earlier ones.
      final res = processScanBatch(
        codes: ['SAS12345678', 'SAS12345679'],
        explicitSelected: i9000s,
        isDuplicate: (s, t) => items.any((i) => i.serialNumber == s),
        onAccepted: (t, s) => items.add(ScannedBatchItem.fromSelection(
            type: t, displaySerial: s, explicitCarrier: null)),
      );
      expect(res.added, 2);

      final body = buildBatchScanInBody(items); // exactly what is POSTed
      final sent = (body['items'] as List).cast<Map<String, dynamic>>();
      expect(sent.map((m) => m['itemTypeId']).toList(),
          ['n950', 'mobilySim', 'i9100', 'stcSim', 'i9000s', 'i9000s']);
      expect(sent.map((m) => m['serialNumber']).toList(), [
        'NCD100232013',
        sharedIccid,
        'SAW12345678',
        sharedIccid.replaceFirst('9824', '9825'),
        'SAS12345678',
        'SAS12345679',
      ]);
      // JSON round-trip (what Dio actually serializes) preserves it.
      final wire = jsonDecode(jsonEncode(body)) as Map<String, dynamic>;
      expect((wire['items'] as List).length, 6);
    });
  });

  // ==========================================================================
  group('5. same type + serial via the camera path and the manual path', () {
    test('identical validation result, itemTypeId and SENT serial', () {
      // Raw variants a scanner vs a human would produce for the same value.
      final cases = <(ItemType, List<String>)>[
        (n950, ['NCD100232013', ' ncd100232013 ']),
        (mobily, [sharedIccid, '8996 6098 2412 3456 789']),
      ];

      for (final (type, raws) in cases) {
        for (final raw in raws) {
          // Manual path: classifyScan directly.
          final manual = classifyScan(rawCode: raw, explicitSelected: type);

          // Camera path: one-code batch through processScanBatch.
          (ItemType, String)? viaCamera;
          processScanBatch(
            codes: [raw],
            explicitSelected: type,
            isDuplicate: (_, _) => false,
            onAccepted: (t, s) => viaCamera = (t, s),
          );

          expect(manual.isAccepted, isTrue, reason: raw);
          expect(viaCamera, isNotNull, reason: raw);
          expect(viaCamera!.$1.id, manual.type!.id);
          expect(viaCamera!.$2, manual.displaySerial); // identical sent serial

          // And the resulting request payloads are identical.
          final a = buildBatchScanInBody([
            ScannedBatchItem.fromSelection(
                type: manual.type!, displaySerial: manual.displaySerial!)
          ]);
          final b = buildBatchScanInBody([
            ScannedBatchItem.fromSelection(
                type: viaCamera!.$1, displaySerial: viaCamera!.$2)
          ]);
          expect(jsonEncode(a), jsonEncode(b));
        }
      }
    });

    test('identical REJECTION too: same failing value → same outcome and the '
        'same message on both paths', () {
      final manual = classifyScan(rawCode: 'WRONG1', explicitSelected: n950);
      final camera = processScanBatch(
        codes: ['WRONG1'],
        explicitSelected: n950,
        isDuplicate: (_, _) => false,
        onAccepted: (_, _) {},
      );
      expect(manual.isAccepted, isFalse);
      expect(camera.added, 0);
      expect(camera.firstError, manual.error);
    });
  });

  // ==========================================================================
  group('6. carrierName null/unavailable', () {
    test('itemTypeId unchanged and no silent "STC" anywhere in the payload',
        () {
      // SIM type whose own name says nothing; no carrier chosen anywhere.
      final o = classifyScan(
          rawCode: '89966${'0' * 15}', explicitSelected: virgin);
      expect(o.isAccepted, isTrue);

      final item = ScannedBatchItem.fromSelection(
          type: o.type!, displaySerial: o.displaySerial!); // no carrier given
      expect(item.carrierName, isNull);
      expect(item.itemTypeId, 'virginSim');

      final body = buildBatchScanInBody([item]);
      final sent = (body['items'] as List).single as Map<String, dynamic>;
      expect(sent.containsKey('carrierName'), isFalse); // nothing sent
      expect(sent['itemTypeId'], 'virginSim');
      expect(jsonEncode(body).toUpperCase(), isNot(contains('STC')));
    });

    test('a carrier the technician chose is only a label — it never changes '
        'itemTypeId', () {
      final o = classifyScan(
          rawCode: '89966${'0' * 15}', explicitSelected: virgin);
      final item = ScannedBatchItem.fromSelection(
          type: o.type!,
          displaySerial: o.displaySerial!,
          explicitCarrier: 'Zain'); // deliberately a different carrier name
      expect(item.carrierName, 'Zain');
      expect(item.itemTypeId, 'virginSim'); // still the selected type
    });

    test('a carrier derived from the selected type\'s OWN name is legitimate '
        '(not a default) and equally cannot alter itemTypeId', () {
      final item = ScannedBatchItem.fromSelection(
          type: stc, displaySerial: sharedIccid);
      expect(item.carrierName, 'STC'); // from the type name "STC SIM"
      expect(item.itemTypeId, 'stcSim');
    });
  });
}
