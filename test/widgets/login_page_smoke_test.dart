// PHASE B1.4 — Flutter Test Foundation smoke tests: App shell + Login screen.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nuolipapp/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nuolipapp/features/auth/presentation/pages/login_page.dart';
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
    seedNoSession(secureStorage); // cold start: no session to restore
    registerTestBindings(secureStorage: secureStorage);
  });

  tearDown(resetGetXState);

  AuthController buildAuthController() {
    return AuthController(
      loginUseCase: LoginUseCase(authRepository),
      logoutUseCase: LogoutUseCase(authRepository),
      getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
      updateFcmTokenUseCase: UpdateFcmTokenUseCase(authRepository),
      router: authRouter,
    );
  }

  testWidgets("app shell renders (GetMaterialApp boots)", (tester) async {
    await pumpWithScreenSize(tester, wrapWithGetMaterialApp(const Scaffold(body: Text("shell"))));
    await pumpUntilSettled(tester);
    expect(find.text("shell"), findsOneWidget);
  });

  testWidgets("login screen renders with a real AuthController (fake repository/router/storage)", (tester) async {
    Get.put<AuthController>(buildAuthController());

    await pumpWithScreenSize(tester, wrapWithGetMaterialApp(const LoginPage()));
    await pumpUntilSettled(tester);

    // LoginForm renders username/password fields — proves the screen built
    // successfully against a controller wired entirely to fakes/mocks, no
    // real network/storage/router touched.
    expect(find.byType(TextFormField), findsWidgets);
  });

  testWidgets("login controller receives the fake repository (no real network call on construction)", (tester) async {
    final controller = buildAuthController();
    Get.put<AuthController>(controller);

    await pumpWithScreenSize(tester, wrapWithGetMaterialApp(const LoginPage()));
    await pumpUntilSettled(tester);

    verifyNever(() => authRepository.login(any(), any()));
    expect(controller.user, isNull, reason: "no session was seeded, so no user should be loaded");
  });
}
