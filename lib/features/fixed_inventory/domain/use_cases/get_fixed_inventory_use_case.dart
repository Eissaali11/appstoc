import '../../data/models/inventory_entry.dart';
import '../repositories/fixed_inventory_repository.dart';

class GetFixedInventoryUseCase {
  final FixedInventoryRepository repository;

  GetFixedInventoryUseCase(this.repository);

  Future<List<InventoryEntry>> call(String technicianId) {
    return repository.getFixedInventory(technicianId);
  }
}
