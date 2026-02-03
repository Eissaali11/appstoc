import '../../data/models/inventory_entry.dart';
import '../../../../shared/models/item_type.dart';

abstract class FixedInventoryRepository {
  Future<List<InventoryEntry>> getFixedInventory(String technicianId);
  Future<List<ItemType>> getItemTypes();
  Future<void> updateFixedInventory(
    String technicianId,
    List<InventoryEntry> entries,
  );
}
