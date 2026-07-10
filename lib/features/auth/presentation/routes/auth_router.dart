import 'package:get/get.dart';
import '../../../../core/routing/app_pages.dart';

abstract class AuthRouter {
  void navigateToDashboard();
  void navigateToLogin();
}

class AuthRouterImpl implements AuthRouter {
  @override
  void navigateToDashboard() {
    Get.offAllNamed(Routes.dashboard);
  }

  @override
  void navigateToLogin() {
    Get.offAllNamed(Routes.login);
  }
}
