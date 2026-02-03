import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../../moving_inventory/data/models/warehouse_transfer.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../core/api/api_endpoints.dart';

class NotificationsController extends GetxController {
  final NotificationsRepository repository;
  final AuthController authController;

  NotificationsController({
    required this.repository,
    required this.authController,
  });

  final _isLoading = false.obs;
  final _error = Rxn<String>();
  final _transfers = <WarehouseTransfer>[].obs;
  final _itemTypes = <ItemType>[].obs;

  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  List<WarehouseTransfer> get transfers => _transfers;
  List<ItemType> get itemTypes => _itemTypes;

  Map<String, ItemType> get itemTypesMap {
    final map = <String, ItemType>{};
    for (var itemType in _itemTypes) {
      map[itemType.id] = itemType;
    }
    return map;
  }

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    try {
      _isLoading.value = true;
      _error.value = null;

      final userId = authController.user?.id;
      if (userId == null) {
        throw Exception('المستخدم غير مسجل دخول');
      }

      final dioInstance = Get.find<dio.Dio>();
      final results = await Future.wait([
        repository.getPendingTransfers(userId),
        dioInstance.get(ApiEndpoints.activeItemTypes),
      ]);

      _transfers.value = results[0] as List<WarehouseTransfer>;
      
      final response = results[1] as dio.Response;
      if (response.data is List) {
        _itemTypes.value = (response.data as List)
            .map((e) => ItemType.fromJson(e as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refresh() async {
    await loadData();
  }

  Future<void> acceptTransfer(String transferId) async {
    try {
      _isLoading.value = true;
      await repository.acceptTransfer(transferId);
      await loadData();
      
      Get.snackbar(
        'نجح',
        'تم قبول طلب النقل بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> rejectTransfer(String transferId, {String? reason}) async {
    try {
      _isLoading.value = true;
      await repository.rejectTransfer(transferId, reason: reason);
      await loadData();
      
      Get.snackbar(
        'نجح',
        'تم رفض طلب النقل',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'خطأ',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }
}
