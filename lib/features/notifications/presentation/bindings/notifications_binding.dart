import 'package:get/get.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../data/repositories/notifications_repository_impl.dart';
import '../controllers/notifications_controller.dart';

class NotificationsBinding extends Bindings {
  @override
  void dependencies() {
    // Repository
    if (!Get.isRegistered<NotificationsRepository>()) {
      Get.lazyPut<NotificationsRepository>(
        () => NotificationsRepositoryImpl(),
      );
    }

    // Controller
    Get.lazyPut(
      () => NotificationsController(
        repository: Get.find<NotificationsRepository>(),
        authController: Get.find<AuthController>(),
      ),
    );
  }
}
