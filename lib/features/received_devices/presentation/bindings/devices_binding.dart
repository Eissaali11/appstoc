import 'package:get/get.dart';
import '../../domain/repositories/devices_repository.dart';
import '../../data/repositories/devices_repository_impl.dart';
import '../controllers/devices_controller.dart';

class DevicesBinding extends Bindings {
  @override
  void dependencies() {
    // Repository
    if (!Get.isRegistered<DevicesRepository>()) {
      Get.lazyPut<DevicesRepository>(
        () => DevicesRepositoryImpl(),
      );
    }

    // Controller
    Get.lazyPut(
      () => DevicesController(
        repository: Get.find<DevicesRepository>(),
      ),
    );
  }
}
