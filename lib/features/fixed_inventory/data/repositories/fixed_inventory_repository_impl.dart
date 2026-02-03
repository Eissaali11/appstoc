import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/repositories/fixed_inventory_repository.dart';
import '../models/inventory_entry.dart';
import '../../../../shared/models/item_type.dart';

class FixedInventoryRepositoryImpl implements FixedInventoryRepository {
  @override
  Future<List<InventoryEntry>> getFixedInventory(String technicianId) async {
    try {
      final dio = Get.find<Dio>();
      final response = await dio.get(
        ApiEndpoints.fixedInventoryEntries(technicianId),
      );
      
      if (response.data is List) {
        return (response.data as List)
            .map((e) => InventoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('فشل جلب المخزون الثابت: ${e.toString()}');
    }
  }

  @override
  Future<List<ItemType>> getItemTypes() async {
    try {
      final dio = Get.find<Dio>();
      final response = await dio.get(ApiEndpoints.activeItemTypes);
      
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
  Future<void> updateFixedInventory(
    String technicianId,
    List<InventoryEntry> entries,
  ) async {
    try {
      final dio = Get.find<Dio>();
      await dio.put(
        ApiEndpoints.fixedInventoryEntries(technicianId),
        data: {
          'entries': entries.map((e) => e.toJson()).toList(),
        },
      );
    } catch (e) {
      throw Exception('فشل تحديث المخزون الثابت: ${e.toString()}');
    }
  }
}
