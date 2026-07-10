import '../../data/models/serialized_item.dart';

abstract class SerializedItemsRepository {
  /// Remote API: scan item into technician custody
  Future<SerializedItem> scanIn({
    required String serialNumber,
    required String itemTypeId,
    String? carrierName,
    String? simPackageType,
  });

  /// Remote API: deliver item from technician custody to customer
  Future<SerializedItem> scanOut({
    required String serialNumber,
    required String receiverName,
    required String orderNumber,
    double? latitude,
    double? longitude,
  });

  /// Remote API: look up serial status and history
  Future<SerializedItem?> lookup(String serialNumber);

  /// Local Cache: save intake draft offline
  Future<void> cacheScanInDraft(Map<String, dynamic> draft);

  /// Local Cache: get all offline intake drafts
  Future<List<Map<String, dynamic>>> getCachedScanInDrafts();

  /// Local Cache: save delivery draft offline
  Future<void> cacheScanOutDraft(Map<String, dynamic> draft);

  /// Local Cache: get all offline delivery drafts
  Future<List<Map<String, dynamic>>> getCachedScanOutDrafts();

  /// Local Cache: remove specific draft by serial number
  Future<void> removeDraft(String serialNumber, {required bool isScanIn});

  /// Local Cache: clear all drafts
  Future<void> clearAllDrafts();
}
