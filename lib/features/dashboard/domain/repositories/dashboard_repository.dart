import '../entities/dashboard_data.dart';

abstract class DashboardRepository {
  Future<DashboardData> getDashboardData(String userId);
  Future<void> acceptTransfer(String transferId);
  Future<void> rejectTransfer(String transferId, {String? reason});
  Future<void> confirmTransferReceipt(String transferId, List<String> serials);

  // v3.0: Real-time single serial scan — creates the serial if it doesn't exist
  Future<Map<String, dynamic>> scanSingleSerial(String transferId, String serialNumber);

  // v3.0: Fetch all serialized items currently in the technician's active custody
  Future<List<Map<String, dynamic>>> fetchMySerializedItems(String technicianId);

  // v3.0: Fetch delivered serialized items (custody_movements DELIVERED)
  Future<List<Map<String, dynamic>>> fetchDeliveredItems(
    String technicianId, {
    String? itemTypeId,
  });
}
