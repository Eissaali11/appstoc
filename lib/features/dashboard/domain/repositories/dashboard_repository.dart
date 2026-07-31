import '../entities/dashboard_data.dart';

/// TEMPORARY FEATURE — remove or disable after final customer handover.
/// Thrown when deleting a device/SIM from the technician's own custody fails,
/// carrying the backend's machine-readable `code` (e.g. ITEM_NOT_IN_YOUR_CUSTODY,
/// ITEM_HAS_ACTIVE_RELATIONS) so the UI can react precisely.
class CustodyDeleteException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  CustodyDeleteException(this.message, {this.code, this.statusCode});

  @override
  String toString() => message;
}

abstract class DashboardRepository {
  Future<DashboardData> getDashboardData(String userId);
  Future<void> acceptTransfer(String transferId);
  Future<void> rejectTransfer(String transferId, {String? reason});
  Future<void> confirmTransferReceipt(String transferId, List<String> serials);

  // v3.0: Real-time single serial scan — creates the serial if it doesn't exist
  Future<Map<String, dynamic>> scanSingleSerial(String transferId, String serialNumber);

  // v3.0: Fetch all serialized items currently in the technician's active custody
  Future<List<Map<String, dynamic>>> fetchMySerializedItems(
    String technicianId, {
    String? itemTypeId,
  });

  // v3.0: Fetch delivered serialized items (custody_movements DELIVERED)
  Future<List<Map<String, dynamic>>> fetchDeliveredItems(
    String technicianId, {
    String? itemTypeId,
  });

  /// TEMPORARY FEATURE — remove or disable after final customer handover.
  /// Permanently deletes [serialNumber] from the authenticated technician's own
  /// active custody. [itemType] must be exactly 'DEVICE' or 'SIM'. [confirmation]
  /// must match [serialNumber] exactly (enforced again server-side). Throws
  /// [CustodyDeleteException] on failure.
  Future<Map<String, dynamic>> deleteSerialFromMyCustody(
    String itemType,
    String serialNumber, {
    required String confirmation,
  });
}
