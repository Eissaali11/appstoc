import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/shared/models/item_type.dart';
import 'package:nuolipapp/shared/scanner/barcode_rule_registry.dart';
import 'package:nuolipapp/shared/scanner/sim_carrier_resolver.dart';

/// Standing invariant: every `itemTypeId` this app can resolve/assign to a
/// scanned or manually-entered serial must be a real id present in the live
/// catalog — never a bespoke label invented by app code (the exact bug this
/// test guards against: `dashboard_controller.dart`'s `addSerialToCustody`
/// used to assign `itemTypeId: "sim_89966_19"`, an internal
/// `BarcodeRuleRegistry` fallback-table label that is NOT and has never been
/// a real `item_types.id` in production, confirmed by direct read-only
/// query).
///
/// This is proven here at the [SimCarrierResolver] level — the single
/// mechanism every scan/manual-entry/custody-add call site in this app now
/// goes through — rather than re-proven per call site, since
/// [SimCarrierResolver.resolve] is structurally incapable of returning
/// anything other than one of the [ItemType] objects it was given as
/// candidates (its return type is `ItemType?`, never a raw string): if this
/// invariant ever held for the resolver, it holds for every caller.
void main() {
  // A realistic catalog fixture mirroring the REAL production item_types
  // shape (read-only query, confirmed), including the exact rows whose
  // ambiguity motivated this PR.
  List<ItemType> realisticCatalog() => [
        ItemType(
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
          serialRegex: r'^(NCC|NCD)[0-9]{9}$',
        ),
        ItemType(
          id: 'i9000s',
          nameEn: 'I9000S',
          nameAr: 'I9000S',
          sortOrder: 2,
          isActive: true,
          isVisible: true,
          category: 'devices',
          requiresSerial: true,
          serialPrefix: 'SAS',
          serialLength: 14,
          serialRegex: r'^SAS[0-9]{11}$',
        ),
        ItemType(
          id: 'A960',
          nameEn: 'A960',
          nameAr: 'A960',
          sortOrder: 3,
          isActive: true,
          isVisible: true,
          category: 'devices',
          requiresSerial: true,
          serialLength: 10,
          serialRegex: r'^[0-9]{10}$',
        ),
        ItemType(
          id: 'mobilySim',
          nameEn: 'Mobily SIM',
          nameAr: 'شريحة موبايلي',
          sortOrder: 7,
          isActive: true,
          isVisible: true,
          category: 'sim',
          requiresSerial: true,
          serialPrefix: '89966',
          serialRegex: r'^89966[0-9]{13,14}$',
        ),
        ItemType(
          id: 'stcSim',
          nameEn: 'STC SIM',
          nameAr: 'شريحة STC',
          sortOrder: 8,
          isActive: true,
          isVisible: true,
          category: 'sim',
          requiresSerial: true,
          serialPrefix: '89966',
          serialRegex: r'^89966[0-9]{13,14}$',
        ),
        // Active but with no validation data of its own — the real,
        // currently-live "Zain SIM New" production row.
        ItemType(
          id: '97956dd0-81f3-4720-a096-f18d5a979137',
          nameEn: 'Zain SIM New',
          nameAr: 'شريحة زين الجديدة',
          sortOrder: 9,
          isActive: true,
          isVisible: true,
          category: 'sim',
          requiresSerial: false,
        ),
        // Hidden — must never be offered as a candidate by a caller.
        ItemType(
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
        ),
      ];

  final catalogIds = realisticCatalog().map((t) => t.id).toSet();

  // A battery of real and realistic-shaped codes exercised against the full
  // visible+active candidate pool, mirroring what addSerialToCustody now
  // builds. For every code, whatever the resolver returns (or doesn't) must
  // be invariant-safe.
  final probeCodes = <String>[
    '899660609902052180', // 18-digit, real STC-shaped
    '8996604214013865777', // 19-digit, real Zain-shaped
    'NCD100232013', // N950 device
    'SAS12345678901', // i9000s device
    '1234567890', // A960 device
    'GARBAGE123', // unrecognizable
  ];

  test(
      'every itemTypeId SimCarrierResolver can possibly return is a real row '
      'in the catalog it was given — never an internal rule-table label '
      '(the exact bug: "sim_89966_19" used to leak into saved custody data)',
      () {
    final candidates = realisticCatalog()
        .where((t) => t.isActive && t.isVisible)
        .toList();

    for (final code in probeCodes) {
      final result = SimCarrierResolver.resolve(
        normalizedCode: code,
        candidates: candidates,
      );

      if (result.isResolved) {
        expect(
          catalogIds.contains(result.resolved!.id),
          isTrue,
          reason: '"${result.resolved!.id}" resolved for "$code" is not a '
              'real catalog id',
        );
      }
      for (final candidate in result.ambiguousCandidates) {
        expect(
          catalogIds.contains(candidate.id),
          isTrue,
          reason: '"${candidate.id}" offered as an ambiguous candidate for '
              '"$code" is not a real catalog id',
        );
      }
    }
  });

  test(
      'specifically: none of BarcodeRuleRegistry\'s internal fallback-table '
      'ids (n950/i9100/i9000s/a960/sim_89966_19/sim_stc) can ever be '
      'returned as a resolved itemTypeId unless that exact id is also a '
      'real catalog row — "sim_89966_19" and "sim_stc" specifically are '
      'NOT real production item_types.id values and must never leak out',
      () {
    final internalOnlyIds = BarcodeRuleRegistry.fallbackRules
        .map((r) => r.id)
        .where((id) => !catalogIds.contains(id))
        .toSet();
    // Sanity: this fixture deliberately does NOT define rows for these ids,
    // same as real production — confirms the test is actually exercising
    // the regression it claims to.
    expect(internalOnlyIds, containsAll(['sim_89966_19', 'sim_stc']));

    final candidates = realisticCatalog()
        .where((t) => t.isActive && t.isVisible)
        .toList();

    for (final code in probeCodes) {
      final result = SimCarrierResolver.resolve(
        normalizedCode: code,
        candidates: candidates,
      );
      if (result.isResolved) {
        expect(internalOnlyIds.contains(result.resolved!.id), isFalse);
      }
    }
  });
}
