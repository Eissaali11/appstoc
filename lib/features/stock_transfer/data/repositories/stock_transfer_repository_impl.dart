import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/repositories/stock_transfer_repository.dart';
import '../../../../shared/models/stock_movement.dart';
import '../../../../shared/models/technician_inventory.dart';

class StockTransferRepositoryImpl implements StockTransferRepository {
  final ApiClient apiClient;

  StockTransferRepositoryImpl(this.apiClient);

  @override
  Future<TechnicianInventory?> getMyFixedInventory() async {
    try {
      final response = await apiClient.get(ApiEndpoints.myFixedInventory);
      if (response.data == null) return null;
      return TechnicianInventory.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('فشل جلب المخزون الثابت: ${e.toString()}');
    }
  }

  @override
  Future<TechnicianInventory?> getMyMovingInventory() async {
    try {
      final response = await apiClient.get(ApiEndpoints.myMovingInventory);
      if (response.data == null) return null;
      return TechnicianInventory.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('فشل جلب المخزون المتحرك: ${e.toString()}');
    }
  }

  @override
  Future<void> transferStock({
    required String technicianId,
    required String itemType,
    required String packagingType,
    required int quantity,
    required String fromInventory,
    required String toInventory,
    String? reason,
    String? notes,
  }) async {
    try {
      await apiClient.post(
        ApiEndpoints.stockTransfer,
        data: {
          'technicianId': technicianId,
          'itemType': itemType,
          'packagingType': packagingType,
          'quantity': quantity,
          'fromInventory': fromInventory,
          'toInventory': toInventory,
          if (reason != null) 'reason': reason,
          if (notes != null) 'notes': notes,
        },
      );
    } catch (e) {
      throw Exception('فشل نقل المخزون: ${e.toString()}');
    }
  }

  @override
  Future<List<StockMovement>> getStockMovements() async {
    try {
      final response = await apiClient.get(ApiEndpoints.stockMovements);
      if (response.data is List) {
        return (response.data as List)
            .map((json) => StockMovement.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('فشل جلب حركات المخزون: ${e.toString()}');
    }
  }
}
