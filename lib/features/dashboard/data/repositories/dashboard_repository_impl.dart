import '../../domain/entities/dashboard_data.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../fixed_inventory/data/models/inventory_entry.dart';
import '../../../moving_inventory/data/models/warehouse_transfer.dart';
import '../../../../shared/models/item_type.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final ApiClient apiClient;

  DashboardRepositoryImpl(this.apiClient);

  @override
  Future<DashboardData> getDashboardData(String userId) async {
    try {
      // Get fixed inventory via injected ApiClient
      final fixedResponse = await apiClient.get(
        ApiEndpoints.fixedInventoryEntries(userId),
      );
      final fixedEntries = (fixedResponse.data as List)
          .map((e) => InventoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      int fixedBoxes = 0;
      int fixedUnits = 0;
      for (var entry in fixedEntries) {
        fixedBoxes += entry.boxes;
        fixedUnits += entry.units;
      }

      // Get moving inventory via injected ApiClient
      final movingResponse = await apiClient.get(
        ApiEndpoints.movingInventoryEntries(userId),
      );
      final movingEntries = (movingResponse.data as List)
          .map((e) => InventoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      int movingBoxes = 0;
      int movingUnits = 0;
      for (var entry in movingEntries) {
        movingBoxes += entry.boxes;
        movingUnits += entry.units;
      }

      // Get pending and accepted transfers via injected ApiClient
      final transfersResponse = await apiClient.get(ApiEndpoints.warehouseTransfers);
      final allTransfers = (transfersResponse.data as List)
          .map((t) => WarehouseTransfer.fromJson(t as Map<String, dynamic>))
          .where((t) => t.technicianId == userId && (t.status == 'pending' || t.status == 'accepted'))
          .toList();

      final pendingTransfers = allTransfers.where((t) => t.status == 'pending').toList();

      // Get item types via injected ApiClient
      final itemTypesResponse = await apiClient.get(ApiEndpoints.activeItemTypes);
      final itemTypes = (itemTypesResponse.data as List)
          .map((e) => ItemType.fromJson(e as Map<String, dynamic>))
          .toList();

      return DashboardData(
        fixedBoxes: fixedBoxes,
        fixedUnits: fixedUnits,
        movingBoxes: movingBoxes,
        movingUnits: movingUnits,
        pendingTransfersCount: pendingTransfers.length,
        fixedInventory: fixedEntries,
        movingInventory: movingEntries,
        pendingTransfers: allTransfers,
        itemTypes: itemTypes,
      );
    } catch (e) {
      throw Exception('فشل جلب بيانات لوحة التحكم: ${e.toString()}');
    }
  }

  @override
  Future<void> acceptTransfer(String transferId) async {
    try {
      await apiClient.post(ApiEndpoints.acceptTransfer(transferId));
    } catch (e) {
      throw Exception('فشل قبول طلب النقل: ${e.toString()}');
    }
  }

  @override
  Future<void> rejectTransfer(String transferId, {String? reason}) async {
    try {
      await apiClient.post(
        ApiEndpoints.rejectTransfer(transferId),
        data: reason != null ? {'reason': reason} : null,
      );
    } catch (e) {
      throw Exception('فشل رفض طلب النقل: ${e.toString()}');
    }
  }

  @override
  Future<void> confirmTransferReceipt(String transferId, List<String> serials) async {
    try {
      // v3.0: confirm-receipt no longer requires serials in body
      // scanning is done one-by-one via scan-serial endpoint
      await apiClient.post(
        '${ApiEndpoints.warehouseTransfers}/$transferId/confirm-receipt',
      );
    } catch (e) {
      throw Exception('فشل تأكيد استلام الشحنة: ${e.toString()}');
    }
  }

  @override
  Future<Map<String, dynamic>> scanSingleSerial(String transferId, String serialNumber) async {
    try {
      final response = await apiClient.post(
        '${ApiEndpoints.warehouseTransfers}/$transferId/scan-serial',
        data: {'serialNumber': serialNumber},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('فشل مسح الرقم التسلسلي: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMySerializedItems(String technicianId) async {
    try {
      final response = await apiClient.get('/api/technicians/$technicianId/serialized-items');
      return (response.data as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('فشل جلب الأرقام التسلسلية: ${e.toString()}');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDeliveredItems(
    String technicianId, {
    String? itemTypeId,
  }) async {
    try {
      final query = itemTypeId != null && itemTypeId.isNotEmpty
          ? '?itemTypeId=${Uri.encodeQueryComponent(itemTypeId)}'
          : '';
      final response = await apiClient.get(
        '/api/technicians/$technicianId/delivered-items$query',
      );
      return (response.data as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw Exception('فشل جلب سجل التسليم: ${e.toString()}');
    }
  }
}
