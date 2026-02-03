import '../../../moving_inventory/data/models/warehouse_transfer.dart';

abstract class NotificationsRepository {
  Future<List<WarehouseTransfer>> getPendingTransfers(String technicianId);
  Future<void> acceptTransfer(String transferId);
  Future<void> rejectTransfer(String transferId, {String? reason});
}
