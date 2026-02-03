import 'package:get/get.dart';
import '../../data/repositories/inventory_request_repository_impl.dart';
import '../../domain/repositories/inventory_request_repository.dart';
import '../controllers/inventory_request_controller.dart';

class InventoryRequestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InventoryRequestRepository>(
      () => InventoryRequestRepositoryImpl(),
    );
    Get.lazyPut<InventoryRequestController>(
      () => InventoryRequestController(
        repository: Get.find<InventoryRequestRepository>(),
      ),
    );
  }
}
