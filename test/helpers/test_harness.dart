// PHASE B1.4 — Flutter Test Foundation: shared test harness utilities.
//
// Scope note: LocalCache and NotificationService are intentionally NOT
// wired into this harness. LocalCache is a static Hive-box wrapper with no
// injectable seam, and NotificationService requires Firebase platform
// channels that do not exist in a plain `flutter test` process (no device).
// Smoke tests in this phase are written to avoid exercising those two
// specific code paths rather than faking platform channels that don't
// exist — documented explicitly in the B1.4 report, not hidden.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nuolipapp/features/auth/domain/entities/user_entity.dart';
import 'package:nuolipapp/core/storage/secure_storage.dart';
import 'package:nuolipapp/core/storage/offline_queue_manager.dart';
import 'mocks.dart';
import 'fakes.dart';

/// Wraps [child] in the same MaterialApp/GetMaterialApp shell production
/// screens render inside, without booting real routing/bindings — for
/// widget-level smoke tests that pump a single screen directly.
Widget wrapWithGetMaterialApp(Widget child) {
  return GetMaterialApp(
    home: child,
    // Test-mode: disables GetX's real snackbar/dialog/route transition
    // overlays that can leak state or timers between tests.
    smartManagement: SmartManagement.full,
  );
}

/// Resets GetX's dependency-injection container and route stack. MUST be
/// called in `tearDown` for every test that calls `Get.put`/`Get.find`,
/// otherwise a controller instance (and its Rx state) leaks into the next
/// test — this is the #1 source of cross-test flakiness with GetX.
Future<void> resetGetXState() async {
  Get.reset();
}

/// Some controllers (e.g. CourierRequestsController.onInit) open a Hive box
/// directly on construction — production behavior, not a testability seam
/// this phase is allowed to change. Points Hive at a fresh, disposable
/// temp directory per test so the real Hive plugin runs against real (if
/// throwaway) local disk, never a shared/production location. Call in
/// `setUp`, and delete the returned directory in `tearDown` via
/// [teardownFakeHive].
Directory initFakeHive() {
  final dir = Directory.systemTemp.createTempSync('nuolipapp_test_hive_');
  Hive.init(dir.path);
  return dir;
}

Future<void> teardownFakeHive(Directory dir) async {
  await Hive.deleteFromDisk();
  // Best-effort: on Windows, a just-closed box's file handle can still be
  // mid-release by the OS for a brief window after deleteFromDisk()
  // resolves, making an immediate deleteSync() throw PathAccessException.
  // This is disposable-temp-dir cleanup, not a correctness concern for the
  // test itself (which has already finished asserting by this point) — a
  // leftover empty/near-empty temp dir on failure is an acceptable
  // trade-off over flaking otherwise-passing tests on Windows.
  try {
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  } catch (_) {
    // Ignored — see comment above.
  }
}

/// Registers the given fakes/mocks into GetX's container for tests that
/// rely on `Get.find<T>()` internally (e.g. DeviceHandoverController's
/// default constructor args, or any controller resolved via a real
/// Binding). Always pair with [resetGetXState] in tearDown.
void registerTestBindings({
  MockSecureStorageService? secureStorage,
  MockOfflineQueueRepository? offlineQueue,
}) {
  if (secureStorage != null) {
    Get.put<SecureStorageService>(secureStorage);
  }
  if (offlineQueue != null) {
    Get.put<OfflineQueueRepository>(offlineQueue);
  }
}

/// Explicit alias for symmetry with registerTestBindings — delegates to
/// resetGetXState() (GetX has no narrower "remove just these" primitive
/// that's safe to rely on across versions, so a full reset is the
/// documented-safe choice here).
Future<void> unregisterTestBindings() => resetGetXState();

/// Configures a MockSecureStorageService to behave as if a valid session
/// for [user] already exists (token present, cached user JSON present) —
/// the state AuthController.checkAuth() reads on cold start.
void seedFakeSession(MockSecureStorageService storage, {UserEntity? user}) {
  final fakeUser = user ?? createFakeUser();
  final fakeToken = 'fake-session-token-not-for-production';
  when(() => storage.getToken()).thenAnswer((_) async => fakeToken);
  when(() => storage.getCachedUserJson()).thenAnswer(
    (_) async => '{'
        '"id":"${fakeUser.id}",'
        '"username":"${fakeUser.username}",'
        '"fullName":"${fakeUser.fullName}",'
        '"role":"${fakeUser.role}",'
        '"regionId":${fakeUser.regionId == null ? 'null' : '"${fakeUser.regionId}"'},'
        '"city":${fakeUser.city == null ? 'null' : '"${fakeUser.city}"'},'
        '"profileImage":null'
        '}',
  );
}

/// Configures a MockSecureStorageService to behave as if no session exists
/// at all (cold start, never logged in, or fully logged out).
void seedNoSession(MockSecureStorageService storage) {
  when(() => storage.getToken()).thenAnswer((_) async => null);
  when(() => storage.getCachedUserJson()).thenAnswer((_) async => null);
}

/// Configures a MockSecureStorageService to behave as if a token exists but
/// is expired/rejected server-side — the checkAuth() failure branch.
void seedExpiredSession(MockSecureStorageService storage) {
  when(() => storage.getToken()).thenAnswer((_) async => 'fake-expired-token');
  when(() => storage.getCachedUserJson()).thenAnswer((_) async => null);
}

UserEntity createFakeAuthenticatedUser({String role = 'technician'}) =>
    createFakeUser(role: role);

/// Configures a MockOfflineQueueRepository to report [pendingCount] queued
/// items — the real signal this app's UI uses for "offline/pending sync"
/// state (see fakes.dart's FakeConnectivityStatus doc comment for why there
/// is no connectivity-plugin stream to fake instead).
void createFakeOfflineState(MockOfflineQueueRepository queue, {int pendingCount = 3}) {
  when(() => queue.getPendingCount()).thenAnswer((_) async => pendingCount);
  when(() => queue.getQueue()).thenAnswer((_) async => List.generate(
        pendingCount,
        (i) => {'index': i, 'type': 'fake-queued-transaction', 'timestamp': 0},
      ));
}

/// Pumps until no more frames are scheduled, with a bounded timeout so a
/// genuinely stuck animation/timer fails the test loudly instead of hanging
/// the whole suite.
Future<void> pumpUntilSettled(WidgetTester tester, {Duration timeout = const Duration(seconds: 10)}) async {
  await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, timeout);
}

/// Pumps [tester] at a fixed logical screen size (default: a common mid-size
/// Android phone) — smoke tests should not depend on whatever the default
/// test surface size happens to be.
Future<void> pumpWithScreenSize(
  WidgetTester tester,
  Widget widget, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(widget);
}

/// Asserts the widget tree recorded zero uncaught FlutterErrors during the
/// pump — a stronger "renders without crashing" check than just checking a
/// widget is findable (which can pass even after an error boundary caught
/// something).
void expectNoUnexpectedExceptions() {
  expect(_capturedErrors, isEmpty, reason: "Widget tree threw an uncaught exception during pump");
}

// FlutterError.onError is process-global; this small buffer + hook lets
// expectNoUnexpectedExceptions() assert against it without every test file
// re-implementing the same FlutterError.onError override.
final List<FlutterErrorDetails> _capturedErrors = [];

void installErrorCapture() {
  _capturedErrors.clear();
  FlutterError.onError = (details) {
    _capturedErrors.add(details);
  };
}
