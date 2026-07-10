import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/storage/local_cache.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../../moving_inventory/data/models/warehouse_transfer.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final ApiClient apiClient;

  NotificationsRepositoryImpl(this.apiClient);

  @override
  Future<List<WarehouseTransfer>> getPendingTransfers(String technicianId) async {
    try {
      final response = await apiClient.get(ApiEndpoints.warehouseTransfers);
      
      if (response.data is List) {
        final transfersJson = (response.data as List)
            .where((t) => t['technicianId'] == technicianId && t['status'] == 'pending')
            .toList();
        
        try {
          final box = await LocalCache.getInventoryBox();
          await box.put('pending_transfers_$technicianId', transfersJson);
        } catch (cacheError) {
          // Ignore cache errors
        }

        return transfersJson
            .map((e) => WarehouseTransfer.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return [];
    } catch (e) {
      try {
        final box = await LocalCache.getInventoryBox();
        final cachedData = box.get('pending_transfers_$technicianId');
        if (cachedData is List) {
          return cachedData
              .map((e) => WarehouseTransfer.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } catch (cacheError) {
        // Ignore cache read errors
      }
      throw Exception('فشل جلب الإشعارات: ${e.toString()}');
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
