import 'package:get/get.dart';
import '../../../../core/api/api_client.dart';
import '../../data/repositories/courier_requests_repository.dart';
import '../../data/repositories/courier_requests_repository_impl.dart';
import '../controllers/courier_requests_controller.dart';
import '../../../received_devices/domain/repositories/devices_repository.dart';
import '../../../received_devices/data/repositories/devices_repository_impl.dart';
import '../../../received_devices/presentation/controllers/devices_controller.dart';

class CourierRequestsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CourierRequestsRepository>(
      () => CourierRequestsRepositoryImpl(Get.find<ApiClient>()),
    );
    Get.lazyPut<CourierRequestsController>(
      () => CourierRequestsController(
        repository: Get.find<CourierRequestsRepository>(),
      ),
    );
    if (!Get.isRegistered<DevicesRepository>()) {
      Get.lazyPut<DevicesRepository>(
        () => DevicesRepositoryImpl(Get.find<ApiClient>()),
      );
    }
    if (!Get.isRegistered<DevicesController>()) {
      Get.lazyPut(
        () => DevicesController(
          repository: Get.find<DevicesRepository>(),
        ),
      );
    }
  }
}
