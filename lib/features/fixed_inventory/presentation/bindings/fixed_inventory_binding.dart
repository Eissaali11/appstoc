import 'package:get/get.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/repositories/fixed_inventory_repository.dart';
import '../../data/repositories/fixed_inventory_repository_impl.dart';
import '../../domain/use_cases/get_fixed_inventory_use_case.dart';
import '../../domain/use_cases/get_item_types_use_case.dart';
import '../../domain/use_cases/update_fixed_inventory_use_case.dart';
import '../controllers/fixed_inventory_controller.dart';

class FixedInventoryBinding extends Bindings {
  @override
  void dependencies() {
    // Repository
    if (!Get.isRegistered<FixedInventoryRepository>()) {
      Get.lazyPut<FixedInventoryRepository>(
        () => FixedInventoryRepositoryImpl(),
      );
    }

    // Use Cases
    Get.lazyPut(
      () => GetFixedInventoryUseCase(Get.find<FixedInventoryRepository>()),
    );
    Get.lazyPut(
      () => GetItemTypesUseCase(Get.find<FixedInventoryRepository>()),
    );
    Get.lazyPut(
      () => UpdateFixedInventoryUseCase(Get.find<FixedInventoryRepository>()),
    );

    // Controller
    Get.lazyPut(
      () => FixedInventoryController(
        getFixedInventoryUseCase: Get.find<GetFixedInventoryUseCase>(),
        getItemTypesUseCase: Get.find<GetItemTypesUseCase>(),
        updateFixedInventoryUseCase: Get.find<UpdateFixedInventoryUseCase>(),
        authController: Get.find<AuthController>(),
      ),
    );
  }
}
