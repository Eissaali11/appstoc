import 'package:get/get.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/use_cases/get_dashboard_data_use_case.dart';
import '../../../fixed_inventory/data/models/inventory_entry.dart';
import '../../../moving_inventory/data/models/warehouse_transfer.dart';
import '../../../../shared/models/item_type.dart';

class DashboardController extends GetxController {
  final GetDashboardDataUseCase getDashboardDataUseCase;
  final AuthController authController;

  DashboardController({
    required this.getDashboardDataUseCase,
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

  @override
  void onInit() {
    super.onInit();
    loadDashboardData();
  }

  Future<void> loadDashboardData() async {
    try {
      _isLoading.value = true;
      _error.value = null;

      final data = await getDashboardDataUseCase();
      
      // Update stats
      _fixedBoxes.value = data['fixedBoxes'] ?? 0;
      _fixedUnits.value = data['fixedUnits'] ?? 0;
      _movingBoxes.value = data['movingBoxes'] ?? 0;
      _movingUnits.value = data['movingUnits'] ?? 0;
      _pendingTransfersCount.value = data['pendingTransfersCount'] ?? 0;
      
      // Update inventory lists
      if (data['fixedInventory'] is List) {
        _fixedInventory.value = (data['fixedInventory'] as List)
            .map((e) => InventoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      
      if (data['movingInventory'] is List) {
        _movingInventory.value = (data['movingInventory'] as List)
            .map((e) => InventoryEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      
      // Update pending transfers
      if (data['pendingTransfers'] is List) {
        _pendingTransfers.value = (data['pendingTransfers'] as List)
            .map((e) => WarehouseTransfer.fromJson(e as Map<String, dynamic>))
            .where((t) => t.status == 'pending')
            .toList();
        _pendingTransfersCount.value = _pendingTransfers.length;
      }
      
      // Update item types
      if (data['itemTypes'] is List) {
        _itemTypes.value = (data['itemTypes'] as List)
            .map((e) => ItemType.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      
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
}
