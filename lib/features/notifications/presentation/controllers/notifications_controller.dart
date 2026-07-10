import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio;
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../fixed_inventory/presentation/controllers/fixed_inventory_controller.dart';
import '../../../moving_inventory/presentation/controllers/moving_inventory_controller.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../../moving_inventory/data/models/warehouse_transfer.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../core/api/api_endpoints.dart';
import '../../../../core/storage/local_cache.dart';

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
  final _selectedIds = <String>[].obs;
  final _scannedSerials = <String, List<String>>{}.obs;

  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  List<WarehouseTransfer> get transfers => _transfers;
  List<ItemType> get itemTypes => _itemTypes;
  List<String> get selectedIds => List.unmodifiable(_selectedIds);
  bool get hasSelection => _selectedIds.isNotEmpty;
  bool get isAllSelected =>
      _transfers.isNotEmpty && _selectedIds.length == _transfers.length;
  bool isSelected(String id) => _selectedIds.contains(id);

  List<String> getScannedSerials(String transferId) {
    return _scannedSerials[transferId] ?? [];
  }

  bool isSerialScannedAnywhere(String serial) {
    for (var list in _scannedSerials.values) {
      if (list.contains(serial)) return true;
    }
    return false;
  }

  void addScannedSerial(String transferId, String serial) {
    final list = _scannedSerials[transferId] ?? [];
    if (!list.contains(serial)) {
      list.add(serial);
      _scannedSerials[transferId] = List.from(list);
    }
  }

  void removeScannedSerial(String transferId, String serial) {
    final list = _scannedSerials[transferId] ?? [];
    list.remove(serial);
    _scannedSerials[transferId] = List.from(list);
  }

  void clearScannedSerials(String transferId) {
    _scannedSerials[transferId] = [];
  }

  void toggleSelection(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
  }

  void selectAll() {
    _selectedIds
      ..clear()
      ..addAll(_transfers.map((t) => t.id));
  }

  void clearSelection() {
    _selectedIds.clear();
  }

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
      clearSelection();

      final userId = authController.user?.id;
      if (userId == null) {
        throw Exception('المستخدم غير مسجل دخول');
      }

      // 1. Fetch transfers (managed by repository caching)
      List<WarehouseTransfer> transfersList = [];
      try {
        transfersList = await repository.getPendingTransfers(userId);
      } catch (e) {
        debugPrint('Failed to fetch transfers from network/cache: $e');
        _error.value = e.toString().replaceAll('Exception: ', '');
      }

      // 2. Fetch active item types with fallback caching
      List<ItemType> typesList = [];
      try {
        final dioInstance = Get.find<dio.Dio>();
        final response = await dioInstance.get(ApiEndpoints.activeItemTypes);
        if (response.data is List) {
          final typesJson = response.data as List;
          try {
            final box = await LocalCache.getInventoryBox();
            await box.put('active_item_types', typesJson);
          } catch (_) {}

          typesList = typesJson
              .map((e) => ItemType.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } catch (e) {
        debugPrint('Failed to fetch item types from network: $e');
        try {
          final box = await LocalCache.getInventoryBox();
          final cachedData = box.get('active_item_types');
          if (cachedData is List) {
            typesList = cachedData
                .map((e) => ItemType.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList();
          }
        } catch (_) {}
      }

      _transfers.value = transfersList;
      if (typesList.isNotEmpty) {
        _itemTypes.value = typesList;
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

  /// تحديث بيانات لوحة التحكم والمخزون بعد قبول أو رفض الطلبات
  Future<void> _refreshInventoryData() async {
    if (Get.isRegistered<DashboardController>()) {
      await Get.find<DashboardController>().refresh();
    }
    if (Get.isRegistered<FixedInventoryController>()) {
      await Get.find<FixedInventoryController>().loadData();
    }
    if (Get.isRegistered<MovingInventoryController>()) {
      await Get.find<MovingInventoryController>().loadData();
    }
  }

  Future<void> acceptTransfer(String transferId) async {
    try {
      _isLoading.value = true;
      await repository.acceptTransfer(transferId);
      await loadData();
      await _refreshInventoryData();
      
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

  Future<bool> acceptSerializedTransfer({
    required String transferId,
    required List<String> serials,
    required ItemType itemType,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      final dioInstance = Get.find<dio.Dio>();
      
      // 1. Submit batch scan in
      final body = {
        'items': serials.map((serial) => {
          'serialNumber': serial,
          'itemTypeId': itemType.id,
          if (itemType.category == 'sim') 'carrierName': 'STC',
        }).toList(),
      };
      
      await dioInstance.post('/api/serialized-items/batch-scan-in', data: body);
      
      // 2. Accept transfer
      await repository.acceptTransfer(transferId);
      
      await loadData();
      await _refreshInventoryData();
      
      Get.snackbar(
        'نجح',
        'تم تسجيل الأرقام وقبول طلب النقل بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Colors.white,
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'خطأ في التسجيل',
        e is dio.DioException 
            ? (e.response?.data?['message'] ?? 'فشل تسجيل الأرقام التسلسلية') 
            : e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> rejectTransfer(String transferId, {String? reason}) async {
    try {
      _isLoading.value = true;
      await repository.rejectTransfer(transferId, reason: reason);
      await loadData();
      await _refreshInventoryData();
      
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

  Future<void> acceptMultipleTransfers(List<String> transferIds) async {
    try {
      _isLoading.value = true;
      final dioInstance = Get.find<dio.Dio>();
      await dioInstance.post(
        ApiEndpoints.acceptMultipleTransfers,
        data: {'transferIds': transferIds},
      );
      await loadData();
      await _refreshInventoryData();
      
      Get.snackbar(
        'نجح',
        'تم قبول ${transferIds.length} طلب نقل',
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

  Future<void> rejectMultipleTransfers(List<String> transferIds, {String? reason}) async {
    try {
      _isLoading.value = true;
      final dioInstance = Get.find<dio.Dio>();
      await dioInstance.post(
        ApiEndpoints.rejectMultipleTransfers,
        data: {
          'transferIds': transferIds,
          if (reason != null) 'reason': reason,
        },
      );
      await loadData();
      await _refreshInventoryData();
      
      Get.snackbar(
        'نجح',
        'تم رفض ${transferIds.length} طلب نقل',
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
