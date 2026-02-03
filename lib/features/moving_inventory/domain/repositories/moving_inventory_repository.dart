import '../../../fixed_inventory/data/models/inventory_entry.dart';
import '../../data/models/warehouse_transfer.dart';
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
}
