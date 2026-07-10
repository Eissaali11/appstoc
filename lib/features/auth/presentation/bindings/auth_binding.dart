import 'package:get/get.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/use_cases/login_use_case.dart';
import '../../domain/use_cases/logout_use_case.dart';
import '../../domain/use_cases/get_current_user_use_case.dart';
import '../controllers/auth_controller.dart';
import '../routes/auth_router.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Router
    Get.lazyPut<AuthRouter>(() => AuthRouterImpl());

    // Data Sources
    Get.lazyPut<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(Get.find<ApiClient>()),
    );

    // Repositories
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDataSource: Get.find<AuthRemoteDataSource>(),
        storage: Get.find<SecureStorageService>(),
      ),
    );

    // Use Cases
    Get.lazyPut(() => LoginUseCase(Get.find<AuthRepository>()));
    Get.lazyPut(() => LogoutUseCase(Get.find<AuthRepository>()));
    Get.lazyPut(() => GetCurrentUserUseCase(Get.find<AuthRepository>()));

    // Controllers - مسجل كـ permanent لأنه Controller أساسي
    Get.put(
      AuthController(
        loginUseCase: Get.find<LoginUseCase>(),
        logoutUseCase: Get.find<LogoutUseCase>(),
        getCurrentUserUseCase: Get.find<GetCurrentUserUseCase>(),
        router: Get.find<AuthRouter>(),
      ),
      permanent: true,
    );
  }
}
