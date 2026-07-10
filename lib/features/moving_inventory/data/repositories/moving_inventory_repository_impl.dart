import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/repositories/moving_inventory_repository.dart';
import '../../../fixed_inventory/data/models/inventory_entry.dart';
import '../models/warehouse_transfer.dart';
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
      
      if (response.data is List) {
        return (response.data as List)
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
}
