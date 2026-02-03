import 'package:dio/dio.dart';
import '../../storage/secure_storage.dart';
import 'package:get/get.dart';

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // لا نضيف Authorization header في طلب تسجيل الدخول
    final isLoginRequest = options.path.contains('/api/auth/login');
    
    if (!isLoginRequest) {
      final storage = Get.find<SecureStorageService>();
      final token = await storage.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    
    // التأكد من وجود Content-Type
    if (!options.headers.containsKey('Content-Type')) {
      options.headers['Content-Type'] = 'application/json';
    }
    
    handler.next(options);
  }
}
