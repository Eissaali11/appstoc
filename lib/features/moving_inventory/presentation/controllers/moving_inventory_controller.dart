import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/repositories/moving_inventory_repository.dart';
import '../../../fixed_inventory/data/models/inventory_entry.dart';
import '../../data/models/warehouse_transfer.dart';
import '../../../../shared/models/item_type.dart';

class MovingInventoryController extends GetxController {
  final MovingInventoryRepository repository;
  final AuthController authController;

  MovingInventoryController({
    required this.repository,
    required this.authController,
  });

  final _isLoading = false.obs;
  final _error = Rxn<String>();
  final _inventory = <InventoryEntry>[].obs;
  final _pendingTransfers = <WarehouseTransfer>[].obs;
  final _itemTypes = <ItemType>[].obs;

  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  List<InventoryEntry> get inventory => _inventory;
  List<WarehouseTransfer> get pendingTransfers => _pendingTransfers;
  List<ItemType> get itemTypes => _itemTypes;

  Map<String, ItemType> get itemTypesMap {
    final map = <String, ItemType>{};
    for (var itemType in _itemTypes) {
      map[itemType.id] = itemType;
    }
    return map;
  }

  int get totalBoxes => _inventory.fold(0, (sum, e) => sum + (e.boxes));
  int get totalUnits => _inventory.fold(0, (sum, e) => sum + (e.units));
  int get totalItems => totalBoxes + totalUnits;

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

      final results = await Future.wait([
        repository.getMovingInventory(userId),
        repository.getPendingTransfers(userId),
        repository.getItemTypes(),
      ]);

      _inventory.value = results[0] as List<InventoryEntry>;
      _pendingTransfers.value = results[1] as List<WarehouseTransfer>;
      _itemTypes.value = results[2] as List<ItemType>;
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

  Future<void> updateInventory(List<InventoryEntry> entries) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      final userId = authController.user?.id;
      if (userId == null) {
        throw Exception('المستخدم غير مسجل دخول');
      }

      // Update each entry individually using POST (as per new API)
      await repository.updateMovingInventory(userId, entries);
      
      // Reload data to get updated values from server
      await loadData();
      
      Get.snackbar(
        'نجح',
        'تم تحديث المخزون المتحرك بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Colors.white,
      );
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'خطأ',
        _error.value ?? 'فشل تحديث المخزون',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }
}
