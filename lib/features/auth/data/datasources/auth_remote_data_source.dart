import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_endpoints.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(String username, String password);
  Future<void> logout();
  Future<UserModel> getCurrentUser();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      // التحقق من أن baseUrl صحيح
      if (ApiEndpoints.baseUrl.isEmpty || 
          ApiEndpoints.baseUrl.contains('your-replit-app') ||
          ApiEndpoints.baseUrl.contains('example.com')) {
        throw Exception(
          '⚠️ يجب تحديث baseUrl في lib/core/api/api_endpoints.dart إلى عنوان الخادم الفعلي',
        );
      }

      final dio = Get.find<Dio>();
      final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.login}';
      
      print('🔐 محاولة تسجيل الدخول...');
      print('📍 URL: $url');
      print('👤 Username: $username');
      print('📤 Request Body: {username: $username, password: ***}');
      
      // إرسال الطلب مع options لتجنب إضافة Authorization header
      final response = await dio.post(
        ApiEndpoints.login,
        data: {'username': username, 'password': password},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      
      print('✅ Status Code: ${response.statusCode}');
      print('📦 Response Data: ${response.data}');
      print('📦 Response Type: ${response.data.runtimeType}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        
        // معالجة الاستجابة بطرق مختلفة
        Map<String, dynamic> responseData;
        
        if (data is Map<String, dynamic>) {
          responseData = data;
        } else if (data is String) {
          // محاولة تحويل String إلى Map
          try {
            responseData = {'message': data};
          } catch (e) {
            throw Exception('تنسيق الاستجابة غير صحيح: $data');
          }
        } else {
          throw Exception('تنسيق الاستجابة غير صحيح: ${data.runtimeType}');
        }
        
        // التحقق من أن الاستجابة تحتوي على البيانات المطلوبة
        if (responseData['success'] == true) {
          if (responseData['user'] != null && responseData['token'] != null) {
            print('✅ تسجيل الدخول ناجح!');
            return responseData;
          } else {
            print('⚠️ الاستجابة لا تحتوي على user أو token');
            print('📦 Response keys: ${responseData.keys}');
            throw Exception(responseData['message'] ?? 'تنسيق الاستجابة غير صحيح: لا يوجد user أو token');
          }
        } else {
          // قد تكون الاستجابة ناجحة لكن بدون success field
          if (responseData['user'] != null && responseData['token'] != null) {
            print('✅ تسجيل الدخول ناجح (بدون success field)');
            return responseData;
          } else {
            throw Exception(responseData['message'] ?? 'فشل تسجيل الدخول');
          }
        }
      } else {
        throw Exception('فشل تسجيل الدخول: ${response.statusCode}');
      }
    } on DioException catch (e) {
      String errorMessage = 'فشل تسجيل الدخول';
      
      print('❌ DioException Type: ${e.type}');
      print('❌ Status Code: ${e.response?.statusCode}');
      print('❌ Response Data: ${e.response?.data}');
      print('❌ Error: ${e.message}');
      
      if (e.response != null) {
        // Server responded with error
        final statusCode = e.response!.statusCode;
        final responseData = e.response!.data;
        
        if (responseData is Map && responseData['message'] != null) {
          errorMessage = responseData['message'] as String;
        } else if (responseData is String) {
          errorMessage = responseData;
        } else if (statusCode == 401) {
          errorMessage = 'اسم المستخدم أو كلمة المرور غير صحيحة';
        } else if (statusCode == 404) {
          errorMessage = 'الخادم غير متاح. يرجى التحقق من URL الخادم في api_endpoints.dart';
        } else if (statusCode == 500) {
          errorMessage = 'خطأ في الخادم. يرجى المحاولة لاحقاً';
        } else {
          errorMessage = 'فشل تسجيل الدخول (كود الخطأ: $statusCode)';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        errorMessage = 'انتهت مهلة الاتصال. يرجى التحقق من الاتصال بالإنترنت';
      } else if (e.type == DioExceptionType.unknown) {
        final errorMsg = e.message ?? '';
        if (errorMsg.contains('Failed host lookup') == true ||
            errorMsg.contains('SocketException') == true ||
            errorMsg.contains('Network is unreachable') == true) {
          errorMessage = '⚠️ لا يمكن الوصول إلى الخادم.\nيرجى التحقق من:\n1. الاتصال بالإنترنت\n2. أن الخادم يعمل\n3. Base URL في api_endpoints.dart';
        } else if (errorMsg.contains('CERTIFICATE_VERIFY_FAILED') == true ||
                   errorMsg.contains('HandshakeException') == true) {
          errorMessage = '⚠️ خطأ في شهادة SSL.\nيرجى التحقق من إعدادات الخادم';
        } else if (errorMsg.contains('Connection refused') == true) {
          errorMessage = '⚠️ تم رفض الاتصال.\nالخادم غير متاح أو معطل';
        } else {
          errorMessage = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الاتصال\n\nتفاصيل الخطأ: ${errorMsg.isNotEmpty ? errorMsg : e.toString()}';
        }
      }
      
      throw Exception(errorMessage);
    } catch (e) {
      print('❌ Exception: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('حدث خطأ غير متوقع: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    try {
      final dio = Get.find<Dio>();
      await dio.post(ApiEndpoints.logout);
    } on DioException {
      // Ignore errors on logout
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final dio = Get.find<Dio>();
      final response = await dio.get(ApiEndpoints.currentUser);
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'فشل جلب بيانات المستخدم');
    }
  }
}
