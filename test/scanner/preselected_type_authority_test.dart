import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/shared/models/item_type.dart';
import 'package:nuolipapp/shared/scanner/sim_carrier_resolver.dart';

/// Resolver-CONTRACT tests: when a caller passes an explicit `selectedType`
/// to [SimCarrierResolver], that type is validated against ITS OWN rule only
/// — never re-resolved, replaced, or backed up by other candidates.
///
/// NOTE (final decision): `shipment_scan_page.dart` no longer calls the
/// resolver at all — its `itemTypeId` comes straight from the explicit
/// dropdown selection via `classifyScan` (see
/// `explicit_selection_integration_test.dart`, which owns the page-level
/// proofs). The resolver contract below still matters for any remaining
/// caller that has a selection, and `carrierLabelForItemType` (also tested
/// here) is what the page uses for the carrier LABEL. The server half
/// (API → DB → admin search) is outside this Flutter repo (apps/api
/// branches).
void main() {
  ItemType sim(String id, String en, String ar,
          {String? regex, String? prefix}) =>
      ItemType(
        id: id,
        nameEn: en,
        nameAr: ar,
        sortOrder: 1,
        isActive: true,
        isVisible: true,
        category: 'sim',
        requiresSerial: regex != null,
        serialPrefix: prefix,
        serialRegex: regex,
      );

  ItemType device(String id, String prefix, int len, String regex) => ItemType(
        id: id,
        nameEn: id,
        nameAr: id,
        sortOrder: 1,
        isActive: true,
        isVisible: true,
        category: 'devices',
        requiresSerial: true,
        serialPrefix: prefix,
        serialLength: len,
        serialRegex: regex,
      );

  // Mirrors production: mobily + stc share the IDENTICAL live regex.
  final mobily = sim('mobilySim', 'Mobily SIM', 'شريحة موبايلي',
      regex: r'^89966[0-9]{13,14}$', prefix: '89966');
  final stc = sim('stcSim', 'STC SIM', 'شريحة STC',
      regex: r'^89966[0-9]{13,14}$', prefix: '89966');
  // Real active "Zain SIM New": no serialPrefix/serialRegex at all.
  final zainNew = sim('97956dd0-81f3-4720-a096-f18d5a979137', 'Zain SIM New',
      'شريحة زين الجديدة');
  // A carrier added later from the admin UI — no code change involved.
  final virgin = sim('virginSim', 'Virgin Mobile SIM', 'شريحة فيرجن',
      regex: r'^89966[0-9]{15}$', prefix: '89966');
  final n950 = device('n950', 'NCC,NCD', 12, r'^(NCC|NCD)[0-9]{9}$');

  final pool = [mobily, stc, zainNew, virgin, n950];

  /// Verbatim copy of how `_saveBatchToBackend` shapes each item.
  Map<String, dynamic> payloadFor(String serial, ItemType resolved) => {
        'serialNumber': serial,
        'itemTypeId': resolved.id,
      };

  const sharedShapeIccid = '8996609824123456789'; // valid for mobily AND stc

  group('pre-selected type is authoritative end to end', () {
    test(
        'the SAME code scanned under different dropdown selections yields '
        'exactly the selected id each time — a regex-identical sibling never '
        'steals or shares the result', () {
      for (final selected in [mobily, stc]) {
        final r = SimCarrierResolver.resolve(
          normalizedCode: sharedShapeIccid,
          candidates: pool,
          selectedType: selected,
        );
        expect(r.isResolved, isTrue, reason: '${selected.id} must resolve');
        expect(r.resolved!.id, selected.id);
        expect(r.isAmbiguous, isFalse); // no prompt when a type was picked
        expect(payloadFor(sharedShapeIccid, r.resolved!)['itemTypeId'],
            selected.id);
      }
    });

    test('device: pre-select N950 + matching serial → N950 in the payload',
        () {
      final r = SimCarrierResolver.resolve(
        normalizedCode: 'NCD100232013',
        candidates: pool,
        selectedType: n950,
      );
      expect(r.resolved!.id, 'n950');
      expect(payloadFor('NCD100232013', r.resolved!)['itemTypeId'], 'n950');
    });

    test(
        'a carrier added later from the item-types admin UI works with zero '
        'code change when pre-selected, and nothing else can claim its code',
        () {
      final code = '89966${'0' * 15}'; // 20 digits — only virgin's regex fits
      expect(code.length, 20);
      final r = SimCarrierResolver.resolve(
        normalizedCode: code,
        candidates: pool,
        selectedType: virgin,
      );
      expect(r.resolved!.id, 'virginSim');
      expect(payloadFor(code, r.resolved!)['itemTypeId'], 'virginSim');
    });

    test(
        'a batch of mixed pre-selections keeps each item\'s own id — no '
        'selection bleeds into the next item', () {
      final items = <Map<String, dynamic>>[];
      for (final entry in [
        (n950, 'NCD100232013'),
        (mobily, sharedShapeIccid),
        (stc, sharedShapeIccid),
      ]) {
        final r = SimCarrierResolver.resolve(
          normalizedCode: entry.$2,
          candidates: pool,
          selectedType: entry.$1,
        );
        items.add(payloadFor(entry.$2, r.resolved!));
      }
      expect(items.map((m) => m['itemTypeId']).toList(),
          ['n950', 'mobilySim', 'stcSim']);
    });
  });

  group('pre-selected type that cannot validate is rejected, never replaced',
      () {
    test(
        'catalog rule missing (the live "Zain SIM New" gap): rejected against '
        'Zain itself — not STC, not Mobily, no ambiguity prompt, no '
        'fall-through to the candidate pool', () {
      final r = SimCarrierResolver.resolve(
        normalizedCode: '8996604214013865777',
        candidates: pool,
        selectedType: zainNew,
      );
      expect(r.isResolved, isFalse);
      expect(r.isAmbiguous, isFalse);
      expect(r.isSelectedTypeRejected, isTrue);
      expect(r.rejectedSelectedType!.id, zainNew.id);
      expect(r.ambiguousCandidates, isEmpty);
    });

    test(
        'selected type\'s rule exists but the code does not match it, while a '
        'DIFFERENT candidate would match cleanly on its own → still '
        'rejected; no silent swap to the lone clean match', () {
      final r = SimCarrierResolver.resolve(
        normalizedCode: 'NCD100232013', // a valid N950 code
        candidates: [n950, mobily],
        selectedType: mobily, // technician picked a SIM type
      );
      expect(r.isResolved, isFalse);
      expect(r.isSelectedTypeRejected, isTrue);
      expect(r.rejectedSelectedType!.id, 'mobilySim');
    });
  });

  group('ambiguity handling is untouched for flows with NO prior selection',
      () {
    test('no selectedType + code valid for two types → still ambiguous, '
        'caller must ask', () {
      final r = SimCarrierResolver.resolve(
        normalizedCode: sharedShapeIccid,
        candidates: [mobily, stc],
      );
      expect(r.isAmbiguous, isTrue);
      expect(r.ambiguousCandidates.map((t) => t.id).toSet(),
          {'mobilySim', 'stcSim'});
      expect(r.isSelectedTypeRejected, isFalse);
    });
  });

  group('carrierName label never defaults to a carrier it does not know', () {
    test('SIM type whose name has no recognized carrier → null, not "STC"',
        () {
      final unknown = sim('virginSim', 'Virgin Mobile SIM', 'شريحة فيرجن');
      expect(carrierLabelForItemType(unknown, null), isNull);
    });

    test('an explicit technician carrier choice is honored when the type name '
        'itself says nothing', () {
      final unknown = sim('virginSim', 'Virgin Mobile SIM', 'شريحة فيرجن');
      expect(carrierLabelForItemType(unknown, 'Virgin Mobile'),
          'Virgin Mobile');
    });

    test('names that do identify a carrier still map as before, and are not '
        'affected by the explicit-carrier argument', () {
      expect(carrierLabelForItemType(stc, 'Zain'), 'STC');
      expect(carrierLabelForItemType(mobily, null), 'Mobily');
      expect(carrierLabelForItemType(zainNew, null), 'Zain');
    });

    test('when no carrier value exists the dropdown shows «غير محدد» (never '
        '"STC"), and that same state sends nothing (label is null)', () {
      expect(kCarrierNotSpecifiedLabel, 'غير محدد');
      expect(kCarrierNotSpecifiedLabel, isNot('STC'));
      final unknown = sim('virginSim', 'Virgin Mobile SIM', 'شريحة فيرجن');
      expect(carrierLabelForItemType(unknown, null), isNull);
    });

    test('non-SIM items never get a carrier label', () {
      expect(carrierLabelForItemType(n950, 'STC'), isNull);
    });
  });
}
