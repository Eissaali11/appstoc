import 'package:get/get.dart';
import '../../domain/repositories/stock_transfer_repository.dart';
import '../../../../shared/models/stock_movement.dart';
import '../../../../shared/models/technician_inventory.dart';

class StockTransferController extends GetxController {
  final StockTransferRepository repository;

  StockTransferController({required this.repository});

  final _isLoading = false.obs;
  final _error = Rxn<String>();
  final _fixedInventory = Rxn<TechnicianInventory>();
  final _movingInventory = Rxn<TechnicianInventory>();
  final _stockMovements = <StockMovement>[].obs;

  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  TechnicianInventory? get fixedInventory => _fixedInventory.value;
  TechnicianInventory? get movingInventory => _movingInventory.value;
  List<StockMovement> get stockMovements => _stockMovements;

  Future<void> loadInventories() async {
    try {
      _isLoading.value = true;
      _error.value = null;
      final results = await Future.wait([
        repository.getMyFixedInventory(),
        repository.getMyMovingInventory(),
      ]);
      _fixedInventory.value = results[0];
      _movingInventory.value = results[1];
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> loadStockMovements() async {
    try {
      _isLoading.value = true;
      _error.value = null;
      final movements = await repository.getStockMovements();
      _stockMovements.value = movements;
    } catch (e) {
      _error.value = e.toString();
    } finally {
      _isLoading.value = false;
    }
  }

  Future<bool> transferStock({
    required String technicianId,
    required String itemType,
    required String packagingType,
    required int quantity,
    required String fromInventory,
    required String toInventory,
    String? reason,
    String? notes,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = null;
      await repository.transferStock(
        technicianId: technicianId,
        itemType: itemType,
        packagingType: packagingType,
        quantity: quantity,
        fromInventory: fromInventory,
        toInventory: toInventory,
        reason: reason,
        notes: notes,
      );
      // Reload inventories after transfer
      await loadInventories();
      return true;
    } catch (e) {
      _error.value = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading.value = false;
    }
  }
}
