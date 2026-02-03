import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../../moving_inventory/data/models/warehouse_transfer.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  @override
  Future<List<WarehouseTransfer>> getPendingTransfers(String technicianId) async {
    try {
      final dio = Get.find<Dio>();
      final response = await dio.get(ApiEndpoints.warehouseTransfers);
      
      if (response.data is List) {
        return (response.data as List)
            .where((t) => t['technicianId'] == technicianId && t['status'] == 'pending')
            .map((e) => WarehouseTransfer.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      throw Exception('فشل جلب الإشعارات: ${e.toString()}');
    }
  }

  @override
  Future<void> acceptTransfer(String transferId) async {
    try {
      final dio = Get.find<Dio>();
      await dio.post(ApiEndpoints.acceptTransfer(transferId));
    } catch (e) {
      throw Exception('فشل قبول طلب النقل: ${e.toString()}');
    }
  }

  @override
  Future<void> rejectTransfer(String transferId, {String? reason}) async {
    try {
      final dio = Get.find<Dio>();
      await dio.post(
        ApiEndpoints.rejectTransfer(transferId),
        data: reason != null ? {'reason': reason} : null,
      );
    } catch (e) {
      throw Exception('فشل رفض طلب النقل: ${e.toString()}');
    }
  }
}
