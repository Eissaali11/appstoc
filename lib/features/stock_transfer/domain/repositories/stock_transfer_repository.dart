import '../../../../shared/models/stock_movement.dart';
import '../../../../shared/models/technician_inventory.dart';

abstract class StockTransferRepository {
  Future<TechnicianInventory?> getMyFixedInventory();
  Future<TechnicianInventory?> getMyMovingInventory();
  Future<void> transferStock({
    required String technicianId,
    required String itemType,
    required String packagingType,
    required int quantity,
    required String fromInventory,
    required String toInventory,
    String? reason,
    String? notes,
  });
  Future<List<StockMovement>> getStockMovements();
}
