import 'package:get/get.dart';
import '../../domain/repositories/inventory_request_repository.dart';
import '../../../../shared/models/inventory_request.dart';
import '../../../fixed_inventory/data/models/inventory_entry.dart';
import '../../../../shared/models/item_type.dart';
import '../../../../core/api/api_endpoints.dart';
import 'package:dio/dio.dart';

class InventoryRequestController extends GetxController {
  final InventoryRequestRepository repository;

  InventoryRequestController({required this.repository});

  final _isLoading = false.obs;
  final _error = Rxn<String>();
  final _myRequests = <InventoryRequest>[].obs;
  final _itemTypes = <ItemType>[].obs;

  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  List<InventoryRequest> get myRequests => _myRequests;
  List<ItemType> get itemTypes => _itemTypes;

  List<InventoryRequest> get pendingRequests =>
      _myRequests.where((r) => r.status == 'pending').toList();
  List<InventoryRequest> get approvedRequests =>
      _myRequests.where((r) => r.status == 'approved').toList();
  List<InventoryRequest> get rejectedRequests =>
      _myRequests.where((r) => r.status == 'rejected').toList();

  @override
  void onInit() {
    super.onInit();
    loadItemTypes();
    loadMyRequests();
  }

  Future<void> loadItemTypes() async {
    try {
      final dio = Get.find<Dio>();
      final response = await dio.get(ApiEndpoints.activeItemTypes);
      if (response.data is List) {
        _itemTypes.value = (response.data as List)
            .map((e) => ItemType.fromJson(e as Map<String, dynamic>))
            .where((item) => item.isActive && item.isVisible)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }
    } catch (e) {
      // Silently fail - item types are not critical for basic functionality
    }
  }

  Future<void> loadMyRequests() async {
    try {
      _isLoading.value = true;
      _error.value = null;
      final requests = await repository.getMyInventoryRequests();
      _myRequests.value = requests;
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  /// Create request using dynamic entries (preferred method)
  Future<bool> createRequestWithEntries({
    required List<InventoryEntry> entries,
    String? notes,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      final request = await repository.createInventoryRequestWithEntries(
        entries: entries,
        notes: notes,
      );
      _myRequests.insert(0, request);
      return true;
    } catch (e) {
      _error.value = e.toString();
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  /// Legacy method (for backward compatibility)
  Future<bool> createRequest({
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
      _isLoading.value = true;
      _error.value = null;
      final request = await repository.createInventoryRequest(
        n950Boxes: n950Boxes,
        n950Units: n950Units,
        i9000sBoxes: i9000sBoxes,
        i9000sUnits: i9000sUnits,
        i9100Boxes: i9100Boxes,
        i9100Units: i9100Units,
        rollPaperBoxes: rollPaperBoxes,
        rollPaperUnits: rollPaperUnits,
        stickersBoxes: stickersBoxes,
        stickersUnits: stickersUnits,
        newBatteriesBoxes: newBatteriesBoxes,
        newBatteriesUnits: newBatteriesUnits,
        mobilySimBoxes: mobilySimBoxes,
        mobilySimUnits: mobilySimUnits,
        stcSimBoxes: stcSimBoxes,
        stcSimUnits: stcSimUnits,
        zainSimBoxes: zainSimBoxes,
        zainSimUnits: zainSimUnits,
        notes: notes,
      );
      _myRequests.insert(0, request);
      return true;
    } catch (e) {
      _error.value = e.toString();
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
}
