import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/repositories/inventory_request_repository.dart';
import '../../../../shared/models/inventory_request.dart';
import '../../../fixed_inventory/data/models/inventory_entry.dart';

class InventoryRequestRepositoryImpl implements InventoryRequestRepository {
  @override
  Future<InventoryRequest> createInventoryRequestWithEntries({
    required List<InventoryEntry> entries,
    String? notes,
  }) async {
    try {
      final dio = Get.find<Dio>();
      
      // Filter out entries with zero quantities
      final validEntries = entries
          .where((e) => e.boxes > 0 || e.units > 0)
          .map((e) => e.toJson())
          .toList();
      
      if (validEntries.isEmpty) {
        throw Exception('يجب إدخال كمية لصنف واحد على الأقل');
      }
      
      final response = await dio.post(
        ApiEndpoints.inventoryRequests,
        data: {
          'entries': validEntries,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return InventoryRequest.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('فشل إنشاء طلب المخزون: ${e.toString()}');
    }
  }

  @override
  Future<InventoryRequest> createInventoryRequest({
    int n950Boxes = 0,
    int n950Units = 0,
    int i9000sBoxes = 0,
    int i9000sUnits = 0,
    int i9100Boxes = 0,
    int i9100Units = 0,
    int rollPaperBoxes = 0,
    int rollPaperUnits = 0,
    int stickersBoxes = 0,
    int stickersUnits = 0,
    int newBatteriesBoxes = 0,
    int newBatteriesUnits = 0,
    int mobilySimBoxes = 0,
    int mobilySimUnits = 0,
    int stcSimBoxes = 0,
    int stcSimUnits = 0,
    int zainSimBoxes = 0,
    int zainSimUnits = 0,
    String? notes,
  }) async {
    try {
      final dio = Get.find<Dio>();
      final response = await dio.post(
        ApiEndpoints.inventoryRequests,
        data: {
          'n950Boxes': n950Boxes,
          'n950Units': n950Units,
          'i9000sBoxes': i9000sBoxes,
          'i9000sUnits': i9000sUnits,
          'i9100Boxes': i9100Boxes,
          'i9100Units': i9100Units,
          'rollPaperBoxes': rollPaperBoxes,
          'rollPaperUnits': rollPaperUnits,
          'stickersBoxes': stickersBoxes,
          'stickersUnits': stickersUnits,
          'newBatteriesBoxes': newBatteriesBoxes,
          'newBatteriesUnits': newBatteriesUnits,
          'mobilySimBoxes': mobilySimBoxes,
          'mobilySimUnits': mobilySimUnits,
          'stcSimBoxes': stcSimBoxes,
          'stcSimUnits': stcSimUnits,
          'zainSimBoxes': zainSimBoxes,
          'zainSimUnits': zainSimUnits,
          if (notes != null) 'notes': notes,
        },
      );
      return InventoryRequest.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('فشل إنشاء طلب المخزون: ${e.toString()}');
    }
  }

  @override
  Future<List<InventoryRequest>> getMyInventoryRequests() async {
    try {
      final dio = Get.find<Dio>();
      final response = await dio.get(ApiEndpoints.myInventoryRequests);
      if (response.data is List) {
        return (response.data as List)
            .map((json) => InventoryRequest.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('فشل جلب طلبات المخزون: ${e.toString()}');
    }
  }
}
