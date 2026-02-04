import 'api_config.dart';

class ApiEndpoints {
  /// عنوان الـ API (يُعيَّن عند بدء التطبيق من ApiConfig، ولا يُعدّل في الكود عند تغيير الدومين)
  static String _baseUrl = ApiConfig.defaultBaseUrl;

  static String get baseUrl => _baseUrl;
  static set baseUrl(String value) {
    _baseUrl = value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  // Authentication
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String currentUser = '/api/auth/me';

  // Fixed Inventory
  static String fixedInventory(String technicianId) =>
      '/api/technician-fixed-inventory/$technicianId';
  static String fixedInventoryEntries(String technicianId) =>
      '/api/technicians/$technicianId/fixed-inventory-entries';
  static const String myFixedInventory = '/api/my-fixed-inventory';

  // Moving Inventory
  static String movingInventory(String technicianId) =>
      '/api/technicians/$technicianId';
  static String movingInventoryEntries(String technicianId) =>
      '/api/technicians/$technicianId/moving-inventory-entries';
  static const String myMovingInventory = '/api/my-moving-inventory';

  // Warehouse Transfers
  static const String warehouseTransfers = '/api/warehouse-transfers';
  static String acceptTransfer(String transferId) =>
      '/api/warehouse-transfers/$transferId/accept';
  static String rejectTransfer(String transferId) =>
      '/api/warehouse-transfers/$transferId/reject';
  static const String acceptMultipleTransfers =
      '/api/warehouse-transfer-batches/by-ids/accept';
  static const String rejectMultipleTransfers =
      '/api/warehouse-transfer-batches/by-ids/reject';

  // Inventory Requests
  static const String inventoryRequests = '/api/inventory-requests';
  static const String myInventoryRequests = '/api/inventory-requests/my';

  // Stock Transfer
  static const String stockTransfer = '/api/stock-transfer';
  static const String stockMovements = '/api/stock-movements';

  // Received Devices
  static const String receivedDevices = '/api/received-devices';
  static const String receivedDevicesPendingCount =
      '/api/received-devices/pending/count';
  static String receivedDevice(String id) => '/api/received-devices/$id';
  static String updateReceivedDeviceStatus(String id) =>
      '/api/received-devices/$id/status';

  // Item Types
  static const String activeItemTypes = '/api/item-types/active';
}
