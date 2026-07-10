import 'package:get/get.dart';
import '../../../../core/api/api_client.dart';
import '../../domain/repositories/devices_repository.dart';
import '../../data/repositories/devices_repository_impl.dart';
import '../../domain/repositories/serialized_items_repository.dart';
import '../../data/repositories/serialized_items_repository_impl.dart';
import '../controllers/devices_controller.dart';
import '../controllers/device_handover_controller.dart';
import '../controllers/serialized_items_controller.dart';

class DevicesBinding extends Bindings {
  @override
  void dependencies() {
    // Repository
    if (!Get.isRegistered<DevicesRepository>()) {
      Get.lazyPut<DevicesRepository>(
        () => DevicesRepositoryImpl(Get.find<ApiClient>()),
      );
    }

    if (!Get.isRegistered<SerializedItemsRepository>()) {
      Get.lazyPut<SerializedItemsRepository>(
        () => SerializedItemsRepositoryImpl(Get.find<ApiClient>()),
      );
    }

    // Controller
    Get.lazyPut(
      () => DevicesController(
        repository: Get.find<DevicesRepository>(),
      ),
    );

    // Handover Controller
    Get.lazyPut(
      () => DeviceHandoverController(),
    );

    // Serialized Items Controller
    Get.lazyPut(
      () => SerializedItemsController(
        repository: Get.find<SerializedItemsRepository>(),
        devicesRepository: Get.find<DevicesRepository>(),
      ),
    );
  }
}
