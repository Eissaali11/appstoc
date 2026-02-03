import 'package:get/get.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/repositories/moving_inventory_repository.dart';
import '../../data/repositories/moving_inventory_repository_impl.dart';
import '../controllers/moving_inventory_controller.dart';

class MovingInventoryBinding extends Bindings {
  @override
  void dependencies() {
    // Repository
    if (!Get.isRegistered<MovingInventoryRepository>()) {
      Get.lazyPut<MovingInventoryRepository>(
        () => MovingInventoryRepositoryImpl(),
      );
    }

    // Controller
    Get.lazyPut(
      () => MovingInventoryController(
        repository: Get.find<MovingInventoryRepository>(),
        authController: Get.find<AuthController>(),
      ),
    );
  }
}
