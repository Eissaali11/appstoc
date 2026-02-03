import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/use_cases/login_use_case.dart';
import '../../domain/use_cases/logout_use_case.dart';
import '../../domain/use_cases/get_current_user_use_case.dart';
import '../../../../core/storage/secure_storage.dart';

class AuthController extends GetxController {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthController({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
  });

  final _user = Rxn<UserEntity>();
  final _isLoading = false.obs;
  final _error = Rxn<String>();

  UserEntity? get user => _user.value;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    checkAuth();
  }

  Future<void> checkAuth() async {
    try {
      _isLoading.value = true;
      final token = await Get.find<SecureStorageService>().getToken();
      if (token == null) {
        _user.value = null;
        return;
      }

      final currentUser = await getCurrentUserUseCase();
      _user.value = currentUser;
      // Navigate to dashboard if user exists
      Get.offAllNamed('/dashboard');
    } catch (e) {
      _user.value = null;
      // Stay on login page if auth fails
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> login(String username, String password) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      final result = await loginUseCase(username, password);

      // التحقق من أن الاستجابة ناجحة
      // قد تكون الاستجابة بدون success field أو مع success = true
      if (result['user'] != null) {
        final userJson = result['user'] as Map<String, dynamic>;

        _user.value = UserEntity(
          id: userJson['id'] as String,
          username: userJson['username'] as String,
          fullName: userJson['fullName'] as String,
          role: userJson['role'] as String,
          regionId: userJson['regionId'] as String?,
          city: userJson['city'] as String?,
        );

        // الانتقال إلى Dashboard بعد تسجيل الدخول الناجح
        Get.offAllNamed('/dashboard');
      } else {
        throw Exception(
          result['message'] ?? 'فشل تسجيل الدخول: لا توجد بيانات المستخدم',
        );
      }
    } catch (e) {
      String errorMessage = 'فشل تسجيل الدخول';
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else {
        errorMessage = e.toString();
      }

      _error.value = errorMessage;
      Get.snackbar(
        'خطأ',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      await logoutUseCase();
      _user.value = null;
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'فشل تسجيل الخروج',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
