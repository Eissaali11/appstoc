import '../../../../shared/models/item_type.dart';
import '../../../../shared/scanner/sim_carrier_resolver.dart'
    show carrierLabelForItemType;

class ScannedBatchItem {
  final String serialNumber;
  final String itemTypeId;
  final String itemTypeName;
  final bool isSim;
  final String? carrierName;

  ScannedBatchItem({
    required this.serialNumber,
    required this.itemTypeId,
    required this.itemTypeName,
    required this.isSim,
    this.carrierName,
  });

  /// The single place a batch item is composed from an explicit selection
  /// (used by BOTH manual entry and the camera/multi-scan batch).
  /// `itemTypeId` is always [type]'s own id. `carrierName` is only a LABEL
  /// (from the type's own name or a carrier the technician chose) — it is
  /// `null` when unknown, never defaulted, and never influences `itemTypeId`.
  factory ScannedBatchItem.fromSelection({
    required ItemType type,
    required String displaySerial,
    String? explicitCarrier,
  }) {
    final isSim = type.category == 'sim';
    return ScannedBatchItem(
      serialNumber: displaySerial,
      itemTypeId: type.id,
      itemTypeName: type.nameAr,
      isSim: isSim,
      carrierName: isSim ? carrierLabelForItemType(type, explicitCarrier) : null,
    );
  }
}

/// The exact body posted to `/api/serialized-items/batch-scan-in`. Each item
/// carries its OWN `itemTypeId`; `carrierName` is included only when a real
/// carrier value exists (never defaulted) and never influences `itemTypeId`.
Map<String, dynamic> buildBatchScanInBody(List<ScannedBatchItem> items) => {
      'items': items
          .map((item) => {
                'serialNumber': item.serialNumber,
                'itemTypeId': item.itemTypeId,
                if (item.isSim &&
                    item.carrierName != null &&
                    item.carrierName!.isNotEmpty)
                  'carrierName': item.carrierName,
              })
          .toList(),
    };
