import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/use_cases/get_fixed_inventory_use_case.dart';
import '../../domain/use_cases/get_item_types_use_case.dart';
import '../../domain/use_cases/update_fixed_inventory_use_case.dart';
import '../../data/models/inventory_entry.dart';
import '../../../../shared/models/item_type.dart';

class FixedInventoryController extends GetxController {
  final GetFixedInventoryUseCase getFixedInventoryUseCase;
  final GetItemTypesUseCase getItemTypesUseCase;
  final UpdateFixedInventoryUseCase updateFixedInventoryUseCase;
  final AuthController authController;

  FixedInventoryController({
    required this.getFixedInventoryUseCase,
    required this.getItemTypesUseCase,
    required this.updateFixedInventoryUseCase,
    required this.authController,
  });

  final _isLoading = false.obs;
  final _error = Rxn<String>();
  final _inventory = <InventoryEntry>[].obs;
  final _itemTypes = <ItemType>[].obs;

  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  List<InventoryEntry> get inventory => _inventory;
  List<ItemType> get itemTypes => _itemTypes;

  Map<String, ItemType> get itemTypesMap {
    final map = <String, ItemType>{};
    for (var itemType in _itemTypes) {
      map[itemType.id] = itemType;
    }
    return map;
  }

  int get totalBoxes => _inventory.fold(0, (sum, e) => sum + e.boxes);
  int get totalUnits => _inventory.fold(0, (sum, e) => sum + e.units);
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
        getFixedInventoryUseCase(userId),
        getItemTypesUseCase(),
      ]);

      _inventory.value = results[0] as List<InventoryEntry>;
      _itemTypes.value = results[1] as List<ItemType>;
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refresh() async {
    await loadData();
  }

  Future<void> updateInventory(List<InventoryEntry> entries) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      final userId = authController.user?.id;
      if (userId == null) {
        throw Exception('المستخدم غير مسجل دخول');
      }

      await updateFixedInventoryUseCase(userId, entries);
      _inventory.value = entries;
      
      Get.snackbar(
        'نجح',
        'تم تحديث المخزون بنجاح',
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
