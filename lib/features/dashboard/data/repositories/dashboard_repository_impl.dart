import '../../domain/repositories/dashboard_repository.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final ApiClient apiClient;

  DashboardRepositoryImpl(this.apiClient);

  @override
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final authController = Get.find<AuthController>();
      final userId = authController.user?.id;

      if (userId == null) {
        throw Exception('المستخدم غير مسجل دخول');
      }

      final dio = Get.find<Dio>();

      // Get fixed inventory
      final fixedResponse = await dio.get(
        ApiEndpoints.fixedInventoryEntries(userId),
      );
      final fixedEntries = (fixedResponse.data as List);
      int fixedBoxes = 0;
      int fixedUnits = 0;
      for (var entry in fixedEntries) {
        fixedBoxes += (entry['boxes'] ?? 0) as int;
        fixedUnits += (entry['units'] ?? 0) as int;
      }

      // Get moving inventory
      final movingResponse = await dio.get(
        ApiEndpoints.movingInventoryEntries(userId),
      );
      final movingEntries = (movingResponse.data as List);
      int movingBoxes = 0;
      int movingUnits = 0;
      for (var entry in movingEntries) {
        movingBoxes += (entry['boxes'] ?? 0) as int;
        movingUnits += (entry['units'] ?? 0) as int;
      }

      // Get pending transfers
      final transfersResponse = await dio.get(ApiEndpoints.warehouseTransfers);
      final transfers = (transfersResponse.data as List)
          .where((t) => t['technicianId'] == userId && t['status'] == 'pending')
          .toList();

      // Get item types
      final itemTypesResponse = await dio.get(ApiEndpoints.activeItemTypes);
      final itemTypes = (itemTypesResponse.data as List);

      return {
        'fixedBoxes': fixedBoxes,
        'fixedUnits': fixedUnits,
        'movingBoxes': movingBoxes,
        'movingUnits': movingUnits,
        'pendingTransfersCount': transfers.length,
        'fixedInventory': fixedEntries,
        'movingInventory': movingEntries,
        'pendingTransfers': transfers,
        'itemTypes': itemTypes,
      };
    } catch (e) {
      throw Exception('فشل جلب بيانات لوحة التحكم: ${e.toString()}');
    }
  }
}
