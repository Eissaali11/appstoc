import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/use_cases/login_use_case.dart';
import '../../domain/use_cases/logout_use_case.dart';
import '../../domain/use_cases/get_current_user_use_case.dart';
import '../../../../core/storage/secure_storage.dart';
import '../routes/auth_router.dart';

class AuthController extends GetxController {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final AuthRouter router;

  AuthController({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.router,
  });

  final _user = Rxn<UserEntity>();
  final _isLoading = false.obs;
  final _error = Rxn<String>();

  UserEntity? get user => _user.value;
  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  Rxn<String> get errorRx => _error;

  @override
  void onInit() {
    super.onInit();
    checkAuth();
  }

  /// Returns true if the user is authenticated (valid token + user loaded).
  Future<bool> checkAuth() async {
    try {
      _isLoading.value = true;
      final storage = Get.find<SecureStorageService>();
      final token = await storage.getToken();
      if (token == null) {
        _user.value = null;
        return false;
      }

      // Try loading user from local cache first to ensure app opens instantly
      // even if offline or server is slow
      final cachedJson = await storage.getCachedUserJson();
      if (cachedJson != null) {
        try {
          final userMap = jsonDecode(cachedJson) as Map<String, dynamic>;
          _user.value = UserEntity(
            id: userMap['id'] as String,
            username: userMap['username'] as String,
            fullName: userMap['fullName'] as String,
            role: userMap['role'] as String,
            regionId: userMap['regionId'] as String?,
            city: userMap['city'] as String?,
          );
        } catch (e) {
          debugPrint('Error parsing cached user: $e');
        }
      }

      // Attempt background refresh of user data from server
      _refreshUserInBackground();

      return true;
    } catch (e) {
      if (_user.value == null) {
        _user.value = null;
        return false;
      }
      return true;
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> _refreshUserInBackground() async {
    try {
      final currentUser = await getCurrentUserUseCase();
      _user.value = currentUser;

      final userMap = {
        'id': currentUser.id,
        'username': currentUser.username,
        'fullName': currentUser.fullName,
        'role': currentUser.role,
        'regionId': currentUser.regionId,
        'city': currentUser.city,
      };
      await Get.find<SecureStorageService>().saveCachedUserJson(jsonEncode(userMap));
    } catch (e) {
      debugPrint('Background user refresh failed: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('401') || 
          errStr.contains('unauthorized') || 
          errStr.contains('unauthenticated') || 
          errStr.contains('expired')) {
        // Token is invalid/expired - log out the user
        logout();
      }
    }
  }

  Future<void> login(String username, String password) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      final result = await loginUseCase(username, password);

      // Check if response is successful and contains user info
      if (result['user'] != null) {
        final userJson = result['user'] as Map<String, dynamic>;

        final userEntity = UserEntity(
          id: userJson['id'] as String,
          username: userJson['username'] as String,
          fullName: userJson['fullName'] as String,
          role: userJson['role'] as String,
          regionId: userJson['regionId'] as String?,
          city: userJson['city'] as String?,
        );
        _user.value = userEntity;

        final userMap = {
          'id': userEntity.id,
          'username': userEntity.username,
          'fullName': userEntity.fullName,
          'role': userEntity.role,
          'regionId': userEntity.regionId,
          'city': userEntity.city,
        };
        await Get.find<SecureStorageService>().saveCachedUserJson(jsonEncode(userMap));

        // Transition to Dashboard via Router
        router.navigateToDashboard();
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
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      _isLoading.value = true;
      _error.value = null;
      await logoutUseCase();
    } catch (e) {
      debugPrint('Logout background call failed: $e');
    } finally {
      _user.value = null;
      _isLoading.value = false;
      router.navigateToLogin();
    }
  }
}
