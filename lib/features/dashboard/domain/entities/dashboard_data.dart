import '../../../fixed_inventory/data/models/inventory_entry.dart';
import '../../../moving_inventory/data/models/warehouse_transfer.dart';
import '../../../../shared/models/item_type.dart';

class DashboardData {
  final int fixedBoxes;
  final int fixedUnits;
  final int movingBoxes;
  final int movingUnits;
  final int pendingTransfersCount;
  final List<InventoryEntry> fixedInventory;
  final List<InventoryEntry> movingInventory;
  final List<WarehouseTransfer> pendingTransfers;
  final List<ItemType> itemTypes;

  const DashboardData({
    required this.fixedBoxes,
    required this.fixedUnits,
    required this.movingBoxes,
    required this.movingUnits,
    required this.pendingTransfersCount,
    required this.fixedInventory,
    required this.movingInventory,
    required this.pendingTransfers,
    required this.itemTypes,
  });
}
