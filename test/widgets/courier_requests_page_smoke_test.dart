// PHASE B1.4 — Flutter Test Foundation smoke test: Courier Requests screen.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nuolipapp/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nuolipapp/features/auth/domain/use_cases/login_use_case.dart';
import 'package:nuolipapp/features/auth/domain/use_cases/logout_use_case.dart';
import 'package:nuolipapp/features/auth/domain/use_cases/get_current_user_use_case.dart';
import 'package:nuolipapp/features/auth/domain/use_cases/update_fcm_token_use_case.dart';
import 'package:nuolipapp/core/storage/offline_queue_manager.dart';
import 'package:nuolipapp/features/courier_requests/presentation/controllers/courier_requests_controller.dart';
import 'package:nuolipapp/features/courier_requests/presentation/pages/courier_requests_page.dart';
import 'package:nuolipapp/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:nuolipapp/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:nuolipapp/features/dashboard/domain/use_cases/get_dashboard_data_use_case.dart';
import 'package:nuolipapp/features/dashboard/domain/use_cases/accept_transfer_use_case.dart';
import 'package:nuolipapp/features/dashboard/domain/use_cases/reject_transfer_use_case.dart';
import 'package:nuolipapp/features/dashboard/domain/use_cases/confirm_transfer_receipt_use_case.dart';
import '../helpers/mocks.dart';
import '../helpers/fakes.dart';
import '../helpers/test_harness.dart';

void main() {
  late Directory fakeHiveDir;
  late MockAuthRepository authRepository;
  late MockAuthRouter authRouter;
  late MockSecureStorageService secureStorage;
  late MockCourierRequestsRepository courierRepository;
  late MockDashboardRepository dashboardRepository;
  late MockOfflineQueueRepository offlineQueueRepository;

  setUpAll(() {
    registerFoundationFallbackValues();
    fakeHiveDir = initFakeHive();
  });

  tearDownAll(() async {
    await teardownFakeHive(fakeHiveDir);
  });

  setUp(() async {
    if (Hive.isBoxOpen('courier_receiving_sessions')) {
      await Hive.box('courier_receiving_sessions').close();
    }

    authRepository = MockAuthRepository();
    authRouter = MockAuthRouter();
    secureStorage = MockSecureStorageService();
    courierRepository = MockCourierRequestsRepository();
    dashboardRepository = MockDashboardRepository();
    offlineQueueRepository = MockOfflineQueueRepository();

    seedFakeSession(secureStorage, user: createFakeAuthenticatedUser());
    when(() => authRepository.getCurrentUser()).thenAnswer((_) async => createFakeAuthenticatedUser());
    when(() => authRepository.updateFcmToken(any())).thenAnswer((_) async {});
    when(() => secureStorage.saveCachedUserJson(any())).thenAnswer((_) async {});
    when(() => courierRepository.getRequests(status: any(named: 'status')))
        .thenAnswer((_) async => [createFakeCourierRequest()]);
    when(() => offlineQueueRepository.getPendingCount()).thenAnswer((_) async => 0);

    registerTestBindings(secureStorage: secureStorage, offlineQueue: offlineQueueRepository);
    Get.put<OfflineQueueController>(OfflineQueueController(repository: offlineQueueRepository));

    final authController = AuthController(
      loginUseCase: LoginUseCase(authRepository),
      logoutUseCase: LogoutUseCase(authRepository),
      getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
      updateFcmTokenUseCase: UpdateFcmTokenUseCase(authRepository),
      router: authRouter,
    );
    Get.put<AuthController>(authController);
    // See dashboard_page_smoke_test.dart for why this explicit await is
    // required (a real timing race between AuthController's own async
    // onInit and DashboardController's synchronous read of
    // authController.user — the AppDrawer this screen renders puts a
    // DashboardController too).
    await authController.checkAuth();

    // AppDrawer (rendered by CourierRequestsPage) also resolves
    // DashboardController via Get.find — registered with an empty-data
    // dashboard repository, not exercised by this screen's own assertions.
    when(() => dashboardRepository.getDashboardData(any())).thenAnswer((_) async => _emptyDashboardData);
    when(() => dashboardRepository.fetchMySerializedItems(any(), itemTypeId: any(named: 'itemTypeId')))
        .thenAnswer((_) async => []);
    when(() => dashboardRepository.fetchDeliveredItems(any(), itemTypeId: any(named: 'itemTypeId')))
        .thenAnswer((_) async => []);
    Get.put<DashboardController>(DashboardController(
      getDashboardDataUseCase: GetDashboardDataUseCase(dashboardRepository),
      acceptTransferUseCase: AcceptTransferUseCase(dashboardRepository),
      rejectTransferUseCase: RejectTransferUseCase(dashboardRepository),
      confirmTransferReceiptUseCase: ConfirmTransferReceiptUseCase(dashboardRepository),
      authController: authController,
    ));

    Get.put<CourierRequestsController>(CourierRequestsController(repository: courierRepository));
  });

  tearDown(resetGetXState);

  testWidgets("renders with fake courier requests (success state)", (tester) async {
    await tester.pumpWidget(wrapWithGetMaterialApp(const CourierRequestsPage()));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(CourierRequestsPage), findsOneWidget);
  });
}

const _emptyDashboardData = DashboardData(
  fixedBoxes: 0,
  fixedUnits: 0,
  movingBoxes: 0,
  movingUnits: 0,
  pendingTransfersCount: 0,
  fixedInventory: [],
  movingInventory: [],
  pendingTransfers: [],
  itemTypes: [],
);
