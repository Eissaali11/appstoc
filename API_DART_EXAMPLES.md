# 💻 أمثلة كود Dart - طلبات API

هذا الملف يحتوي على أمثلة كود Dart توضح كيفية إرسال طلبات API في تطبيق Flutter.

---

## 📦 الملفات المتعلقة

### 1. `lib/core/api/api_endpoints.dart`
```dart
class ApiEndpoints {
  static const String baseUrl = 'https://your-replit-app.replit.app';
  
  // Authentication
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String currentUser = '/api/auth/me';
}
```

### 2. `lib/core/di/injection_container.dart`
```dart
// إعداد Dio Client مع Headers افتراضية
final dio = Dio(
  BaseOptions(
    baseUrl: ApiEndpoints.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ),
);
```

---

## 1️⃣ تسجيل الدخول (Login)

### الملف: `lib/features/auth/data/datasources/auth_remote_data_source.dart`

```dart
@override
Future<Map<String, dynamic>> login(String username, String password) async {
  try {
    final dio = Get.find<Dio>();
    
    // إرسال الطلب
    final response = await dio.post(
      ApiEndpoints.login,
      data: {
        'username': username,
        'password': password,
      },
    );
    
    // التحقق من الاستجابة
    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        // التحقق من أن الاستجابة تحتوي على البيانات المطلوبة
        if (data['success'] == true && 
            data['user'] != null && 
            data['token'] != null) {
          return data;
        } else {
          throw Exception(data['message'] ?? 'تنسيق الاستجابة غير صحيح');
        }
      } else {
        throw Exception('تنسيق الاستجابة غير صحيح');
      }
    } else {
      throw Exception('فشل تسجيل الدخول: ${response.statusCode}');
    }
  } on DioException catch (e) {
    // معالجة الأخطاء
    String errorMessage = 'فشل تسجيل الدخول';
    
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final responseData = e.response!.data;
      
      if (responseData is Map && responseData['message'] != null) {
        errorMessage = responseData['message'] as String;
      } else if (statusCode == 401) {
        errorMessage = 'اسم المستخدم أو كلمة المرور غير صحيحة';
      } else if (statusCode == 404) {
        errorMessage = 'الخادم غير متاح';
      }
    }
    
    throw Exception(errorMessage);
  }
}
```

### استخدام في Controller: `lib/features/auth/presentation/controllers/auth_controller.dart`

```dart
Future<void> login(String username, String password) async {
  try {
    _isLoading.value = true;
    _error.value = null;

    // استدعاء Use Case
    final result = await loginUseCase(username, password);

    // التحقق من أن الاستجابة ناجحة
    if (result['success'] == true && result['user'] != null) {
      final userJson = result['user'] as Map<String, dynamic>;
      
      // حفظ Token
      final token = result['token'] as String;
      await Get.find<SecureStorageService>().saveToken(token);
      
      // تحديث حالة المستخدم
      _user.value = UserEntity(
        id: userJson['id'] as String,
        username: userJson['username'] as String,
        fullName: userJson['fullName'] as String,
        role: userJson['role'] as String,
        regionId: userJson['regionId'] as String?,
        city: userJson['city'] as String?,
      );
      
      // الانتقال إلى Dashboard
      Get.offAllNamed('/dashboard');
    } else {
      throw Exception(result['message'] ?? 'فشل تسجيل الدخول');
    }
  } catch (e) {
    String errorMessage = 'فشل تسجيل الدخول';
    if (e is Exception) {
      errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    
    _error.value = errorMessage;
    Get.snackbar(
      'خطأ',
      errorMessage,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Colors.white,
    );
  } finally {
    _isLoading.value = false;
  }
}
```

---

## 2️⃣ الحصول على بيانات المستخدم الحالي (Get Current User)

### الملف: `lib/features/auth/data/datasources/auth_remote_data_source.dart`

```dart
@override
Future<UserModel> getCurrentUser() async {
  try {
    final dio = Get.find<Dio>();
    
    // إرسال الطلب (الـ Token يتم إضافته تلقائياً عبر AuthInterceptor)
    final response = await dio.get(ApiEndpoints.currentUser);
    
    // تحويل الاستجابة إلى UserModel
    return UserModel.fromJson(response.data);
  } on DioException catch (e) {
    throw Exception(
      e.response?.data?['message'] ?? 'فشل جلب بيانات المستخدم'
    );
  }
}
```

### استخدام في Controller

```dart
Future<void> checkAuth() async {
  try {
    _isLoading.value = true;
    
    // التحقق من وجود Token
    final token = await Get.find<SecureStorageService>().getToken();
    if (token == null) {
      _user.value = null;
      return;
    }

    // جلب بيانات المستخدم الحالي
    final currentUser = await getCurrentUserUseCase();
    _user.value = currentUser;
    
    // الانتقال إلى Dashboard إذا كان المستخدم موجود
    Get.offAllNamed('/dashboard');
  } catch (e) {
    _user.value = null;
    // البقاء في صفحة تسجيل الدخول إذا فشل التحقق
  } finally {
    _isLoading.value = false;
  }
}
```

---

## 3️⃣ تسجيل الخروج (Logout)

### الملف: `lib/features/auth/data/datasources/auth_remote_data_source.dart`

```dart
@override
Future<void> logout() async {
  try {
    final dio = Get.find<Dio>();
    
    // إرسال طلب تسجيل الخروج (الـ Token يتم إضافته تلقائياً)
    await dio.post(ApiEndpoints.logout);
  } on DioException {
    // تجاهل الأخطاء في تسجيل الخروج
  }
}
```

### استخدام في Controller

```dart
Future<void> logout() async {
  try {
    // استدعاء Use Case
    await logoutUseCase();
    
    // حذف بيانات المستخدم
    _user.value = null;
    
    // حذف Token من SecureStorage
    await Get.find<SecureStorageService>().deleteToken();
    
    // الانتقال إلى صفحة تسجيل الدخول
    Get.offAllNamed('/login');
  } catch (e) {
    Get.snackbar(
      'خطأ',
      'فشل تسجيل الخروج',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
```

---

## 🔐 AuthInterceptor - إضافة Token تلقائياً

### الملف: `lib/core/api/interceptors/auth_interceptor.dart`

```dart
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final storage = Get.find<SecureStorageService>();
    final token = await storage.getToken();
    
    // إضافة Token إلى Header إذا كان موجود
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    // إضافة Content-Type
    options.headers['Content-Type'] = 'application/json';
    
    handler.next(options);
  }
}
```

---

## 📝 مثال كامل - Use Case

### الملف: `lib/features/auth/domain/use_cases/login_use_case.dart`

```dart
class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<Map<String, dynamic>> call(String username, String password) async {
    // استدعاء Repository
    final result = await repository.login(username, password);
    
    // حفظ Token في SecureStorage
    if (result['token'] != null) {
      await Get.find<SecureStorageService>().saveToken(
        result['token'] as String
      );
    }
    
    // حفظ User ID في SecureStorage (اختياري)
    if (result['user'] != null) {
      final user = result['user'] as Map<String, dynamic>;
      await Get.find<SecureStorageService>().saveUserId(
        user['id'] as String
      );
    }
    
    return result;
  }
}
```

---

## 🧪 مثال على الاختبار

### اختبار Login Request

```dart
void testLogin() async {
  // إعداد
  final dio = Dio(BaseOptions(baseUrl: 'https://test-api.com'));
  final dataSource = AuthRemoteDataSourceImpl(ApiClient(dio));
  
  // التنفيذ
  try {
    final result = await dataSource.login('testuser', 'testpass');
    print('✅ Login successful: ${result['success']}');
    print('👤 User: ${result['user']}');
    print('🔑 Token: ${result['token']}');
  } catch (e) {
    print('❌ Login failed: $e');
  }
}
```

---

## 🔍 Debugging - Logging

### إضافة Logging للطلبات

```dart
// في auth_remote_data_source.dart
@override
Future<Map<String, dynamic>> login(String username, String password) async {
  try {
    final dio = Get.find<Dio>();
    final url = '${ApiEndpoints.baseUrl}${ApiEndpoints.login}';
    
    // Logging قبل الطلب
    print('🔐 محاولة تسجيل الدخول...');
    print('📍 URL: $url');
    print('👤 Username: $username');
    print('📤 Request Body: {username: $username, password: ***}');
    
    final response = await dio.post(
      ApiEndpoints.login,
      data: {'username': username, 'password': password},
    );
    
    // Logging بعد الاستجابة
    print('✅ Status Code: ${response.statusCode}');
    print('📦 Response Data: ${response.data}');
    
    // ... باقي الكود
  } catch (e) {
    // Logging للأخطاء
    print('❌ Error: $e');
    rethrow;
  }
}
```

---

## 📋 ملخص التدفق (Flow)

```
1. User enters credentials
   ↓
2. LoginForm calls AuthController.login()
   ↓
3. AuthController calls LoginUseCase
   ↓
4. LoginUseCase calls AuthRepository.login()
   ↓
5. AuthRepository calls AuthRemoteDataSource.login()
   ↓
6. AuthRemoteDataSource sends HTTP POST request
   ↓
7. AuthInterceptor adds headers (Content-Type, Authorization if token exists)
   ↓
8. Server responds with user data and token
   ↓
9. AuthRemoteDataSource returns response
   ↓
10. AuthRepository saves token to SecureStorage
   ↓
11. LoginUseCase returns result
   ↓
12. AuthController updates user state and navigates to Dashboard
```

---

## ⚠️ ملاحظات مهمة

1. **الـ Token:** يتم حفظه تلقائياً في `SecureStorage` بعد تسجيل الدخول الناجح
2. **الـ Headers:** يتم إضافتها تلقائياً عبر `AuthInterceptor`
3. **معالجة الأخطاء:** جميع الأخطاء يتم معالجتها في `ErrorInterceptor`
4. **الـ Logging:** يتم تسجيل جميع الطلبات والاستجابات في الـ console
5. **الـ Base URL:** يجب تحديثه في `lib/core/api/api_endpoints.dart`

---

## 🔗 روابط الملفات

- `lib/core/api/api_endpoints.dart` - تعريف الـ Endpoints
- `lib/core/api/interceptors/auth_interceptor.dart` - إضافة Token تلقائياً
- `lib/core/api/interceptors/error_interceptor.dart` - معالجة الأخطاء
- `lib/features/auth/data/datasources/auth_remote_data_source.dart` - طلبات API
- `lib/features/auth/presentation/controllers/auth_controller.dart` - Controller
- `lib/core/storage/secure_storage.dart` - حفظ Token
