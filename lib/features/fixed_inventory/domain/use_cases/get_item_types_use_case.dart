import '../../../../shared/models/item_type.dart';
import '../repositories/fixed_inventory_repository.dart';

class GetItemTypesUseCase {
  final FixedInventoryRepository repository;

  GetItemTypesUseCase(this.repository);

  Future<List<ItemType>> call() {
    return repository.getItemTypes();
  }
}
