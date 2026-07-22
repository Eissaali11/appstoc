import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/use_cases/login_use_case.dart';
import '../../domain/use_cases/logout_use_case.dart';
import '../../domain/use_cases/get_current_user_use_case.dart';
import '../../domain/use_cases/update_fcm_token_use_case.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/storage/local_cache.dart';
import '../../../../core/storage/offline_queue_manager.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/api/api_config.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../../courier_requests/presentation/controllers/courier_requests_controller.dart';
import '../../../received_devices/domain/repositories/serialized_items_repository.dart';
import '../routes/auth_router.dart';

class AuthController extends GetxController {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final UpdateFcmTokenUseCase updateFcmTokenUseCase;
  final AuthRouter router;

  AuthController({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.updateFcmTokenUseCase,
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
            profileImage: userMap['profileImage'] as String?,
          );
        } catch (e) {
          debugPrint('Error parsing cached user: $e');
        }
      }

      // Attempt background refresh of user data from server
      _refreshUserInBackground();

      // Send FCM Token to server asynchronously
      sendFcmTokenToServer();

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

      await _persistUserCache(currentUser);
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

  Future<void> sendFcmTokenToServer() async {
    try {
      final notificationService = Get.find<NotificationService>();
      final token = await notificationService.getFCMToken();
      if (token != null) {
        await updateFcmTokenUseCase(token);
        debugPrint('[AuthController] FCM Token sent to server successfully');
      }
    } catch (e) {
      debugPrint('[AuthController] Error sending FCM Token to server: $e');
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
          profileImage: userJson['profileImage'] as String?,
        );
        _user.value = userEntity;
        await _persistUserCache(userEntity);

        // Send FCM Token to server asynchronously after login
        sendFcmTokenToServer();

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
      await _clearCrossAccountState();
      _user.value = null;
      _isLoading.value = false;
      router.navigateToLogin();
    }
  }

  /// Prevents previous account custody/inventory from leaking into the next login.
  Future<void> _clearCrossAccountState() async {
    try {
      if (Get.isRegistered<DashboardController>()) {
        Get.find<DashboardController>().clearScopedState();
      }
      if (Get.isRegistered<CourierRequestsController>()) {
        Get.find<CourierRequestsController>().clearScopedState();
      }
      if (Get.isRegistered<OfflineQueueController>()) {
        await Get.find<OfflineQueueController>().clearQueue();
      }
      if (Get.isRegistered<SerializedItemsRepository>()) {
        await Get.find<SerializedItemsRepository>().clearAllDrafts();
      }
      await LocalCache.clearCache();
      await ApiConfig.clearCache();

      for (final boxName in const [
        'serialized_items_drafts',
        'draft_devices',
        'courier_receiving_sessions',
        'offline_sync_queue',
      ]) {
        try {
          if (Hive.isBoxOpen(boxName)) {
            await Hive.box(boxName).clear();
          } else {
            final box = await Hive.openBox(boxName);
            await box.clear();
          }
        } catch (e) {
          debugPrint('Failed clearing Hive box $boxName: $e');
        }
      }
    } catch (e) {
      debugPrint('Cross-account state clear failed: $e');
    }
  }

  Future<void> _persistUserCache(UserEntity user) async {
    final userMap = {
      'id': user.id,
      'username': user.username,
      'fullName': user.fullName,
      'role': user.role,
      'regionId': user.regionId,
      'city': user.city,
      'profileImage': user.profileImage,
    };
    await Get.find<SecureStorageService>().saveCachedUserJson(jsonEncode(userMap));
  }

  /// Updates local auth user after profile save (avatar/city sync for drawer).
  Future<void> applyLocalUserPatch({
    String? city,
    String? profileImage,
  }) async {
    final current = _user.value;
    if (current == null) return;
    final next = current.copyWith(
      city: city ?? current.city,
      profileImage: profileImage ?? current.profileImage,
    );
    _user.value = next;
    await _persistUserCache(next);
  }
}
