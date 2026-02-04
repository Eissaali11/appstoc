import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../api/api_endpoints.dart';
import '../api/interceptors/auth_interceptor.dart';
import '../api/interceptors/error_interceptor.dart';
import '../storage/secure_storage.dart';
import '../storage/local_cache.dart';

import '../api/api_config.dart';

class InjectionContainer {
  static Future<void> init() async {
    // Initialize Hive
    await LocalCache.init();

    // جلب عنوان الـ API ديناميكياً (من خادم الإعداد أو الكاش أو الافتراضي)
    final baseUrl = await ApiConfig.getBaseUrl();
    ApiEndpoints.baseUrl = baseUrl;

    // Secure Storage
    Get.put<SecureStorageService>(
      SecureStorageService(),
      permanent: true,
    );

    // Dio Client
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptors
    dio.interceptors.addAll([
      AuthInterceptor(),
      ErrorInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
      ),
    ]);

    Get.put<Dio>(dio, permanent: true);

    // API Client
    Get.put<ApiClient>(
      ApiClient(dio),
      permanent: true,
    );
  }
}
