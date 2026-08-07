// PHASE B1.4 — Flutter Test Foundation smoke tests: session restoration
// (fresh session, no session, expired session) — AuthController.checkAuth().
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nuolipapp/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nuolipapp/features/auth/domain/use_cases/login_use_case.dart';
import 'package:nuolipapp/features/auth/domain/use_cases/logout_use_case.dart';
import 'package:nuolipapp/features/auth/domain/use_cases/get_current_user_use_case.dart';
import 'package:nuolipapp/features/auth/domain/use_cases/update_fcm_token_use_case.dart';
import '../helpers/mocks.dart';
import '../helpers/test_harness.dart';

void main() {
  late MockAuthRepository authRepository;
  late MockAuthRouter authRouter;
  late MockSecureStorageService secureStorage;

  setUpAll(registerFoundationFallbackValues);

  setUp(() {
    authRepository = MockAuthRepository();
    authRouter = MockAuthRouter();
    secureStorage = MockSecureStorageService();
    when(() => authRepository.getCurrentUser()).thenAnswer((_) async => createFakeAuthenticatedUser());
    when(() => secureStorage.saveCachedUserJson(any())).thenAnswer((_) async {});
    // checkAuth() resolves SecureStorageService via Get.find internally
    // (not constructor-injected) — must be registered for every test.
    registerTestBindings(secureStorage: secureStorage);
  });

  tearDown(resetGetXState);

  AuthController buildController() {
    return AuthController(
      loginUseCase: LoginUseCase(authRepository),
      logoutUseCase: LogoutUseCase(authRepository),
      getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
      updateFcmTokenUseCase: UpdateFcmTokenUseCase(authRepository),
      router: authRouter,
    );
  }

  test("session restoration: a fake cached session restores the user immediately", () async {
    seedFakeSession(secureStorage, user: createFakeAuthenticatedUser(role: "supervisor"));

    final controller = buildController();
    final restored = await controller.checkAuth();

    expect(restored, isTrue);
    expect(controller.user, isNotNull);
    expect(controller.user!.role, "supervisor");
  });

  test("no session (cold start, never logged in): checkAuth reports not authenticated", () async {
    seedNoSession(secureStorage);

    final controller = buildController();
    final restored = await controller.checkAuth();

    expect(restored, isFalse);
    expect(controller.user, isNull);
  });

  test("expired session: a token with no cached user still produces a defined (non-crashing) result", () async {
    seedExpiredSession(secureStorage);

    final controller = buildController();
    // checkAuth() must resolve to a boolean either way — the important
    // foundation-level guarantee is that an expired/rejected token never
    // throws uncaught out of checkAuth(), which would crash the splash
    // screen that calls it.
    final result = await controller.checkAuth();

    expect(result, isA<bool>());
  });
}
