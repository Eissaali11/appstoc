// PHASE B1.4 — Flutter Test Foundation: single mocking surface (mocktail
// only, no mockito in parallel — one library, one convention).
//
// Each Mock<T> class is a thin `extends Mock implements T` — the real
// interfaces/classes are never modified to make this work (ApiClient is a
// concrete class already designed around a single Dio dependency, so it is
// directly mockable without touching production code).
import 'package:dio/dio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nuolipapp/core/api/api_client.dart';
import 'package:nuolipapp/core/storage/secure_storage.dart';
import 'package:nuolipapp/core/storage/offline_queue_manager.dart';
import 'package:nuolipapp/features/auth/domain/repositories/auth_repository.dart';
import 'package:nuolipapp/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nuolipapp/features/auth/presentation/routes/auth_router.dart';
import 'package:nuolipapp/features/courier_requests/data/repositories/courier_requests_repository.dart';
import 'package:nuolipapp/features/received_devices/domain/repositories/devices_repository.dart';
import 'package:nuolipapp/features/dashboard/domain/repositories/dashboard_repository.dart';

class MockApiClient extends Mock implements ApiClient {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAuthRouter extends Mock implements AuthRouter {}

class MockAuthController extends Mock implements AuthController {}

class MockCourierRequestsRepository extends Mock implements CourierRequestsRepository {}

class MockDevicesRepository extends Mock implements DevicesRepository {}

class MockDashboardRepository extends Mock implements DashboardRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockOfflineQueueRepository extends Mock implements OfflineQueueRepository {}

/// Registers mocktail fallback values for argument types passed to `any()`
/// matchers across this suite. Call once in a top-level `setUpAll`.
void registerFoundationFallbackValues() {
  registerFallbackValue(Options());
  registerFallbackValue(Uri());
}
