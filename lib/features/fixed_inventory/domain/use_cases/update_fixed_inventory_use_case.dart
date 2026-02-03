import '../../data/models/inventory_entry.dart';
import '../repositories/fixed_inventory_repository.dart';

class UpdateFixedInventoryUseCase {
  final FixedInventoryRepository repository;

  UpdateFixedInventoryUseCase(this.repository);

  Future<void> call(String technicianId, List<InventoryEntry> entries) {
    return repository.updateFixedInventory(technicianId, entries);
  }
}
