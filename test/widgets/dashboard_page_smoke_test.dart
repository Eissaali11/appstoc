// PHASE B1.4 — Flutter Test Foundation smoke test: Dashboard screen.
// Also covers Loading/Empty/Error state variants (B1.4.4 items 4, 6, 7, 8).
import 'dart:async';
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
import 'package:nuolipapp/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:nuolipapp/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:nuolipapp/features/dashboard/domain/use_cases/get_dashboard_data_use_case.dart';
import 'package:nuolipapp/features/dashboard/domain/use_cases/accept_transfer_use_case.dart';
import 'package:nuolipapp/features/dashboard/domain/use_cases/reject_transfer_use_case.dart';
import 'package:nuolipapp/features/dashboard/domain/use_cases/confirm_transfer_receipt_use_case.dart';
import 'package:nuolipapp/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:nuolipapp/features/courier_requests/presentation/controllers/courier_requests_controller.dart';
import '../helpers/mocks.dart';
import '../helpers/test_harness.dart';

const _emptyDashboard = DashboardData(
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

void main() {
  // CourierRequestsController.onInit() opens a real Hive box (production
  // behavior, not a testability seam this phase touches) — shared for the
  // whole file rather than per-test to avoid a Hive.deleteFromDisk() /
  // Hive.init() race between tests (hit and fixed during this phase: a
  // per-test temp dir caused PathNotFoundException on the 2nd test because
  // Hive's global registry didn't fully release the prior box before the
  // next Hive.init() pointed elsewhere).
  late Directory fakeHiveDir;

  late MockAuthRepository authRepository;
  late MockAuthRouter authRouter;
  late MockSecureStorageService secureStorage;
  late MockDashboardRepository dashboardRepository;
  late MockCourierRequestsRepository courierRepository;
  late MockOfflineQueueRepository offlineQueueRepository;

  setUpAll(() {
    registerFoundationFallbackValues();
    fakeHiveDir = initFakeHive();
  });

  tearDownAll(() async {
    await teardownFakeHive(fakeHiveDir);
  });

  setUp(() async {
    // Hive.deleteFromDisk() is not called between tests in this file (see
    // setUpAll note); if a prior test in the SAME run left the shared box
    // open, close it so the next test's onInit() reopens it cleanly.
    if (Hive.isBoxOpen('courier_receiving_sessions')) {
      await Hive.box('courier_receiving_sessions').close();
    }

    authRepository = MockAuthRepository();
    authRouter = MockAuthRouter();
    secureStorage = MockSecureStorageService();
    dashboardRepository = MockDashboardRepository();
    courierRepository = MockCourierRequestsRepository();
    offlineQueueRepository = MockOfflineQueueRepository();

    seedFakeSession(secureStorage, user: createFakeAuthenticatedUser());
    // Every one of these is a real background call DashboardPage/
    // AuthController make on load; each must be stubbed or mocktail's
    // default `null` return trips a non-nullable Future<T> type cast deep
    // inside production code (caught real bugs in THIS test file during
    // this phase, not in production — but the stub is still required for
    // the mock to behave like a real repository would).
    when(() => authRepository.getCurrentUser()).thenAnswer((_) async => createFakeAuthenticatedUser());
    when(() => authRepository.updateFcmToken(any())).thenAnswer((_) async {});
    when(() => secureStorage.saveCachedUserJson(any())).thenAnswer((_) async {});
    when(() => dashboardRepository.fetchMySerializedItems(any(), itemTypeId: any(named: 'itemTypeId')))
        .thenAnswer((_) async => []);
    when(() => dashboardRepository.fetchDeliveredItems(any(), itemTypeId: any(named: 'itemTypeId')))
        .thenAnswer((_) async => []);
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
    // AuthController.onInit() fires checkAuth() without awaiting it
    // (production behavior, not changed here) — awaiting it explicitly
    // here, before any DashboardController is built, is what makes
    // `authController.user` deterministically non-null for every test
    // below. Without this, DashboardController.loadDashboardData() (which
    // reads authController.user?.id synchronously) races AuthController's
    // own async init, which is exactly what caused an intermittent failure
    // in the full-suite "run twice" regression check for this phase.
    await authController.checkAuth();
    Get.put<CourierRequestsController>(CourierRequestsController(repository: courierRepository));
  });

  tearDown(resetGetXState);

  DashboardController buildDashboardController() {
    return DashboardController(
      getDashboardDataUseCase: GetDashboardDataUseCase(dashboardRepository),
      acceptTransferUseCase: AcceptTransferUseCase(dashboardRepository),
      rejectTransferUseCase: RejectTransferUseCase(dashboardRepository),
      confirmTransferReceiptUseCase: ConfirmTransferReceiptUseCase(dashboardRepository),
      authController: Get.find<AuthController>(),
    );
  }

  testWidgets("renders in success state with fake dashboard data", (tester) async {
    when(() => dashboardRepository.getDashboardData(any())).thenAnswer((_) async => _emptyDashboard);
    Get.put<DashboardController>(buildDashboardController());

    await tester.pumpWidget(wrapWithGetMaterialApp(const DashboardPage()));
    // Bounded discrete pumps, not pumpAndSettle: this screen has a
    // continuous ambient animation that legitimately never reaches a
    // "no frames scheduled" steady state, which is a real (pre-existing,
    // out of this phase's scope to change per the "no UI changes" rule)
    // property of the screen, not a test bug — pumpAndSettle is simply the
    // wrong tool for a screen with an infinite-repeat animation.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testWidgets("renders an empty state (zero inventory, zero transfers) without crashing", (tester) async {
    when(() => dashboardRepository.getDashboardData(any())).thenAnswer((_) async => _emptyDashboard);
    Get.put<DashboardController>(buildDashboardController());

    await tester.pumpWidget(wrapWithGetMaterialApp(const DashboardPage()));
    // Bounded discrete pumps, not pumpAndSettle: this screen has a
    // continuous ambient animation that legitimately never reaches a
    // "no frames scheduled" steady state, which is a real (pre-existing,
    // out of this phase's scope to change per the "no UI changes" rule)
    // property of the screen, not a test bug — pumpAndSettle is simply the
    // wrong tool for a screen with an infinite-repeat animation.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets("renders an error state when the repository throws", (tester) async {
    when(() => dashboardRepository.getDashboardData(any())).thenThrow(Exception("fake network failure"));
    Get.put<DashboardController>(buildDashboardController());

    await tester.pumpWidget(wrapWithGetMaterialApp(const DashboardPage()));
    // Bounded discrete pumps, not pumpAndSettle: this screen has a
    // continuous ambient animation that legitimately never reaches a
    // "no frames scheduled" steady state, which is a real (pre-existing,
    // out of this phase's scope to change per the "no UI changes" rule)
    // property of the screen, not a test bug — pumpAndSettle is simply the
    // wrong tool for a screen with an infinite-repeat animation.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // The controller must have caught the error internally (this is a
    // GetX app with try/catch-driven state, not thrown-into-the-widget-tree
    // errors) — the screen itself must still be standing, not crashed.
    expect(find.byType(DashboardPage), findsOneWidget);
  });

  testWidgets("renders a loading state before the fake data resolves", (tester) async {
    // A Completer, not Future.delayed: the previous version raced real
    // wall-clock time against pump() calls and flaked under a full-suite
    // run (passed reliably in isolation, failed intermittently after ~130
    // preceding tests had already run in the same process) — caught by
    // this phase's required "run twice" regression check. A manually
    // completed Completer makes "still loading" a fact under our direct
    // control, not a timing guess.
    final responseCompleter = Completer<DashboardData>();
    when(() => dashboardRepository.getDashboardData(any())).thenAnswer((_) => responseCompleter.future);
    final controller = buildDashboardController();
    Get.put<DashboardController>(controller);

    await tester.pumpWidget(wrapWithGetMaterialApp(const DashboardPage()));
    await tester.pump();

    expect(controller.isLoading, isTrue);

    // Complete the fake response and drain the resulting frame(s) so no
    // pending work is left when the test ends.
    responseCompleter.complete(_emptyDashboard);
    await tester.pump();
    await tester.pump();
  });
}
