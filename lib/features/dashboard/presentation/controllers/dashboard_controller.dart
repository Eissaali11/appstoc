import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/use_cases/get_dashboard_data_use_case.dart';
import '../../domain/use_cases/accept_transfer_use_case.dart';
import '../../domain/use_cases/reject_transfer_use_case.dart';
import '../../domain/use_cases/confirm_transfer_receipt_use_case.dart';
import '../../../fixed_inventory/data/models/inventory_entry.dart';
import '../../../moving_inventory/data/models/warehouse_transfer.dart';
import '../../../../shared/models/item_type.dart';
import '../widgets/inventory_filter_bar.dart';
import '../../../../core/storage/offline_queue_manager.dart';

class MergedInventoryItem {
  final ItemType itemType;
  int fixedBoxes;
  int fixedUnits;
  int movingBoxes;
  int movingUnits;

  MergedInventoryItem({
    required this.itemType,
    required this.fixedBoxes,
    required this.fixedUnits,
    required this.movingBoxes,
    required this.movingUnits,
  });

  int get totalQuantity => fixedBoxes + fixedUnits + movingBoxes + movingUnits;
}

class DashboardController extends GetxController {
  final GetDashboardDataUseCase getDashboardDataUseCase;
  final AcceptTransferUseCase acceptTransferUseCase;
  final RejectTransferUseCase rejectTransferUseCase;
  final ConfirmTransferReceiptUseCase confirmTransferReceiptUseCase;
  final AuthController authController;

  DashboardController({
    required this.getDashboardDataUseCase,
    required this.acceptTransferUseCase,
    required this.rejectTransferUseCase,
    required this.confirmTransferReceiptUseCase,
    required this.authController,
  });

  final _isLoading = false.obs;
  final _isInitialLoad = true.obs;
  final _error = Rxn<String>();
  
  // Stats
  final _fixedBoxes = 0.obs;
  final _fixedUnits = 0.obs;
  final _movingBoxes = 0.obs;
  final _movingUnits = 0.obs;
  final _pendingTransfersCount = 0.obs;
  
  // Data
  final _fixedInventory = <InventoryEntry>[].obs;
  final _movingInventory = <InventoryEntry>[].obs;
  final _pendingTransfers = <WarehouseTransfer>[].obs;
  final _itemTypes = <ItemType>[].obs;

  // Search & Filter State
  final searchQuery = ''.obs;
  final selectedFilter = InventoryFilter.all.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  bool get isInitialLoad => _isInitialLoad.value;
  String? get error => _error.value;
  
  int get fixedBoxes => _fixedBoxes.value;
  int get fixedUnits => _fixedUnits.value;
  int get movingBoxes => _movingBoxes.value;
  int get movingUnits => _movingUnits.value;
  int get pendingTransfersCount => _pendingTransfersCount.value;
  
  int get fixedInventoryTotal => _fixedBoxes.value + _fixedUnits.value;
  int get movingInventoryTotal => _movingBoxes.value + _movingUnits.value;
  
  List<InventoryEntry> get fixedInventory => _fixedInventory;
  List<InventoryEntry> get movingInventory => _movingInventory;
  List<WarehouseTransfer> get pendingTransfers => _pendingTransfers;
  List<ItemType> get itemTypes => _itemTypes;
  
  Map<String, ItemType> get itemTypesMap {
    final map = <String, ItemType>{};
    for (var itemType in _itemTypes) {
      map[itemType.id] = itemType;
    }
    return map;
  }
  
  bool get hasInventoryData => 
      _fixedInventory.isNotEmpty || _movingInventory.isNotEmpty;
  
  get user => authController.user;

  // Offline Sync delegate
  int get pendingSyncCount => Get.find<OfflineQueueController>().pendingCount.value;
  void syncOfflineNow() {
    Get.find<OfflineQueueController>().syncNow();
  }

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
    
    // Reactively listen to offline queue sync successes
    if (Get.isRegistered<OfflineQueueController>()) {
      ever(Get.find<OfflineQueueController>().pendingCount, (int count) {
        if (count == 0 && !isLoading) {
          loadDashboardData();
        }
      });
    }
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void updateFilter(InventoryFilter filter) {
    selectedFilter.value = filter;
  }

  void clearFilters() {
    searchQuery.value = '';
    selectedFilter.value = InventoryFilter.all;
  }

  // Computed property to return the filtered and sorted list of inventory items
  List<MergedInventoryItem> get filteredItems {
    final Map<String, MergedInventoryItem> itemsMap = {};
    final query = searchQuery.value.toLowerCase().trim();
    final filter = selectedFilter.value;

    // Initialize map with all known active item types
    for (var itemType in _itemTypes) {
      itemsMap[itemType.id] = MergedInventoryItem(
        itemType: itemType,
        fixedBoxes: 0,
        fixedUnits: 0,
        movingBoxes: 0,
        movingUnits: 0,
      );
    }

    // Merge fixed inventory
    for (var entry in _fixedInventory) {
      if (itemsMap.containsKey(entry.itemTypeId)) {
        itemsMap[entry.itemTypeId]!.fixedBoxes = entry.boxes;
        itemsMap[entry.itemTypeId]!.fixedUnits = entry.units;
      } else {
        final itemType = itemTypesMap[entry.itemTypeId];
        if (itemType != null) {
          itemsMap[entry.itemTypeId] = MergedInventoryItem(
            itemType: itemType,
            fixedBoxes: entry.boxes,
            fixedUnits: entry.units,
            movingBoxes: 0,
            movingUnits: 0,
          );
        }
      }
    }

    // Merge moving inventory
    for (var entry in _movingInventory) {
      if (itemsMap.containsKey(entry.itemTypeId)) {
        itemsMap[entry.itemTypeId]!.movingBoxes = entry.boxes;
        itemsMap[entry.itemTypeId]!.movingUnits = entry.units;
      } else {
        final itemType = itemTypesMap[entry.itemTypeId];
        if (itemType != null) {
          itemsMap[entry.itemTypeId] = MergedInventoryItem(
            itemType: itemType,
            fixedBoxes: 0,
            fixedUnits: 0,
            movingBoxes: entry.boxes,
            movingUnits: entry.units,
          );
        }
      }
    }

    var items = itemsMap.values.toList();

    // Apply search query
    if (query.isNotEmpty) {
      items = items.where((item) {
        return item.itemType.nameAr.toLowerCase().contains(query) ||
            item.itemType.nameEn.toLowerCase().contains(query);
      }).toList();
    }

    // Apply selected Filter
    switch (filter) {
      case InventoryFilter.fixed:
        items = items.where((item) => (item.fixedBoxes + item.fixedUnits) > 0).toList();
        break;
      case InventoryFilter.moving:
        items = items.where((item) => (item.movingBoxes + item.movingUnits) > 0).toList();
        break;
      case InventoryFilter.hasStock:
        items = items.where((item) => item.totalQuantity > 0).toList();
        break;
      case InventoryFilter.lowStock:
        items = items.where((item) => item.totalQuantity > 0 && item.totalQuantity < 10).toList();
        break;
      case InventoryFilter.all:
        break;
    }

    // Sort items by sortOrder
    items.sort((a, b) => a.itemType.sortOrder.compareTo(b.itemType.sortOrder));

    return items;
  }

  Future<void> loadDashboardData() async {
    try {
      _isLoading.value = true;
      _error.value = null;

      final userId = authController.user?.id;
      if (userId == null) {
        throw Exception('المستخدم غير مسجل دخول');
      }

      final data = await getDashboardDataUseCase(userId);
      
      // Update stats
      _fixedBoxes.value = data.fixedBoxes;
      _fixedUnits.value = data.fixedUnits;
      _movingBoxes.value = data.movingBoxes;
      _movingUnits.value = data.movingUnits;
      _pendingTransfersCount.value = data.pendingTransfersCount;
      
      // Update inventory lists
      _fixedInventory.value = data.fixedInventory;
      _movingInventory.value = data.movingInventory;
      _pendingTransfers.value = data.pendingTransfers;
      _itemTypes.value = data.itemTypes;
      
      _isInitialLoad.value = false;
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
      _isInitialLoad.value = false;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> refresh() async {
    _isInitialLoad.value = false;
    await loadDashboardData();
  }

  Future<void> acceptTransfer(String transferId) async {
    try {
      _isLoading.value = true;
      await acceptTransferUseCase(transferId);
      await loadDashboardData();
      
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
      await rejectTransferUseCase(transferId, reason: reason);
      await loadDashboardData();
      
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

  Future<void> confirmTransferReceipt(String transferId, List<String> serials) async {
    try {
      _isLoading.value = true;
      // v3.0: serials are already registered one-by-one via scanSingleSerial
      // This call just marks the transfer as approved and updates moving inventory
      await confirmTransferReceiptUseCase(transferId, []);
      await loadDashboardData();

      Get.snackbar(
        '✓ تم الاستلام',
        'تم تأكيد استلام العهدة وتحديث مخزونك بنجاح',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF22C55E),
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
      rethrow;
    } finally {
      _isLoading.value = false;
    }
  }

  // v3.0: Real-time single serial scan — called per barcode scan event
  Future<void> scanSingleSerial(String transferId, String serialNumber) async {
    // Direct repository access — no UseCase needed for a single lightweight call
    final repo = getDashboardDataUseCase.repository;
    await repo.scanSingleSerial(transferId, serialNumber);
    // No full dashboard reload — we just let the page track scanned count locally
  }
}

