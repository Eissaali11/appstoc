class ApiEndpoints {
  // Base URL للخادم على Replit
  static const String baseUrl =
      'https://fcf0121e-0593-4710-ad11-105d54ba692e-00-3cyb0wsnu78xa.janeway.replit.dev';

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

  // Item Types
  static const String activeItemTypes = '/api/item-types/active';
}
