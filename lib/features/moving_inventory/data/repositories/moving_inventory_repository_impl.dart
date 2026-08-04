import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/repositories/moving_inventory_repository.dart';
import '../../../fixed_inventory/data/models/inventory_entry.dart';
import '../models/warehouse_transfer.dart';
import '../models/serialized_item.dart';
import '../../../../shared/models/item_type.dart';

class MovingInventoryRepositoryImpl implements MovingInventoryRepository {
  final ApiClient apiClient;

  MovingInventoryRepositoryImpl(this.apiClient);

  @override
  Future<List<InventoryEntry>> getMovingInventory(String technicianId) async {
    try {
      final response = await apiClient.get(
        ApiEndpoints.movingInventoryEntries(technicianId),
      );
      
      if (response.data is List) {
        return (response.data as List)
            .map((e) => InventoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('فشل جلب المخزون المتحرك: ${e.toString()}');
    }
  }

  @override
  Future<List<WarehouseTransfer>> getPendingTransfers(String technicianId) async {
    try {
      final response = await apiClient.get(ApiEndpoints.warehouseTransfers);
      
      if (response.data is List) {
        return (response.data as List)
            .where((t) => t['technicianId'] == technicianId && t['status'] == 'pending')
            .map((e) => WarehouseTransfer.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('فشل جلب طلبات النقل: ${e.toString()}');
    }
  }

  @override
  Future<List<ItemType>> getItemTypes() async {
    try {
      final response = await apiClient.get(ApiEndpoints.activeItemTypes);

      final rawData = response.data is List
          ? response.data
          : (response.data is Map
              ? (response.data['data'] ?? response.data['items'])
              : null);

      if (rawData is List) {
        return rawData
            .map((e) => ItemType.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('فشل جلب أنواع العناصر: ${e.toString()}');
    }
  }

  @override
  Future<void> updateMovingInventory(
    String technicianId,
    List<InventoryEntry> entries,
  ) async {
    try {
      // Update each entry individually using POST
      for (var entry in entries) {
        await apiClient.post(
          ApiEndpoints.movingInventoryEntries(technicianId),
          data: {
            'itemTypeId': entry.itemTypeId,
            'boxes': entry.boxes,
            'units': entry.units,
          },
        );
      }
    } catch (e) {
      throw Exception('فشل تحديث المخزون المتحرك: ${e.toString()}');
    }
  }

  /// Update a single inventory entry
  Future<void> updateSingleEntry({
    required String technicianId,
    required String itemTypeId,
    required int boxes,
    required int units,
  }) async {
    try {
      await apiClient.post(
        ApiEndpoints.movingInventoryEntries(technicianId),
        data: {
          'itemTypeId': itemTypeId,
          'boxes': boxes,
          'units': units,
        },
      );
    } catch (e) {
      throw Exception('فشل تحديث عنصر المخزون: ${e.toString()}');
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
  Future<List<SerializedItem>> getMyCustody() async {
    try {
      final response = await apiClient.get(ApiEndpoints.mySerializedCustody);
      final rawList = response.data is List
          ? response.data
          : (response.data is Map
              ? (response.data['data'] ?? response.data['items'] ?? response.data['custody'])
              : null);
      if (rawList is List) {
        return rawList
            .map((e) => SerializedItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      // Fallback: resolve current user id, then fetch by technician id
      final token = apiClient.dio.options.headers['Authorization'];
      if (token == null) return [];

      final meResp = await apiClient.get(ApiEndpoints.currentUser);
      final userId = meResp.data?['id'] as String? ?? meResp.data?['user']?['id'] as String?;
      if (userId == null) return [];

      final resp2 = await apiClient.get(ApiEndpoints.technicianSerializedCustody(userId));
      final rawList2 = resp2.data is List
          ? resp2.data
          : (resp2.data is Map ? (resp2.data['data'] ?? resp2.data['items']) : null);
      if (rawList2 is List) {
        return rawList2
            .map((e) => SerializedItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> batchScanIn(List<Map<String, dynamic>> items) async {
    try {
      final response = await apiClient.post(
        ApiEndpoints.batchScanIn,
        data: {'items': items},
      );
      return response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
    } catch (e) {
      throw Exception('فشل تسجيل الأجهزة والشرائح دفعة واحدة: ${e.toString()}');
    }
  }
}
