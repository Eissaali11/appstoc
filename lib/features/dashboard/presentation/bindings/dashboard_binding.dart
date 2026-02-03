import 'package:get/get.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/domain/use_cases/login_use_case.dart';
import '../../../auth/domain/use_cases/logout_use_case.dart';
import '../../../auth/domain/use_cases/get_current_user_use_case.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../domain/use_cases/get_dashboard_data_use_case.dart';
import '../controllers/dashboard_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // تأكد من تسجيل AuthController أولاً
    // إذا لم يكن مسجل، قم بتسجيله مع جميع dependencies
    if (!Get.isRegistered<AuthController>()) {
      // تسجيل جميع dependencies المطلوبة لـ AuthController
      if (!Get.isRegistered<AuthRemoteDataSource>()) {
        Get.lazyPut<AuthRemoteDataSource>(
          () => AuthRemoteDataSourceImpl(Get.find<ApiClient>()),
        );
      }

      if (!Get.isRegistered<AuthRepository>()) {
        Get.lazyPut<AuthRepository>(
          () => AuthRepositoryImpl(
            remoteDataSource: Get.find<AuthRemoteDataSource>(),
            storage: Get.find<SecureStorageService>(),
          ),
        );
      }

      if (!Get.isRegistered<LoginUseCase>()) {
        Get.lazyPut(() => LoginUseCase(Get.find<AuthRepository>()));
      }

      if (!Get.isRegistered<LogoutUseCase>()) {
        Get.lazyPut(() => LogoutUseCase(Get.find<AuthRepository>()));
      }

      if (!Get.isRegistered<GetCurrentUserUseCase>()) {
        Get.lazyPut(() => GetCurrentUserUseCase(Get.find<AuthRepository>()));
      }

      // تسجيل AuthController كـ permanent
      Get.put(
        AuthController(
          loginUseCase: Get.find<LoginUseCase>(),
          logoutUseCase: Get.find<LogoutUseCase>(),
          getCurrentUserUseCase: Get.find<GetCurrentUserUseCase>(),
        ),
        permanent: true,
      );
    }

    // Repository
    if (!Get.isRegistered<DashboardRepository>()) {
      Get.lazyPut<DashboardRepository>(
        () => DashboardRepositoryImpl(Get.find<ApiClient>()),
      );
    }

    // Use Case
    if (!Get.isRegistered<GetDashboardDataUseCase>()) {
      Get.lazyPut(
        () => GetDashboardDataUseCase(Get.find<DashboardRepository>()),
      );
    }

    // Controller
    Get.lazyPut(
      () => DashboardController(
        getDashboardDataUseCase: Get.find<GetDashboardDataUseCase>(),
        authController: Get.find<AuthController>(),
      ),
    );
  }
}
