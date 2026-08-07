import '../../../fixed_inventory/data/models/inventory_entry.dart';
import '../../data/models/warehouse_transfer.dart';
import '../../data/models/serialized_item.dart';
import '../../../../shared/models/item_type.dart';

abstract class MovingInventoryRepository {
  Future<List<InventoryEntry>> getMovingInventory(String technicianId);
  Future<List<WarehouseTransfer>> getPendingTransfers(String technicianId);
  Future<List<ItemType>> getItemTypes();
  Future<void> updateMovingInventory(
    String technicianId,
    List<InventoryEntry> entries,
  );
  Future<void> acceptTransfer(String transferId);
  Future<void> rejectTransfer(String transferId, {String? reason});

  /// Remote API: fetch all serialized devices/SIMs currently in the technician's custody
  Future<List<SerializedItem>> getMyCustody();

  /// Remote API: register a batch of scanned devices/SIMs into custody at once
  Future<Map<String, dynamic>> batchScanIn(List<Map<String, dynamic>> items);
}
