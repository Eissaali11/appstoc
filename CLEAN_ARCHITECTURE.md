# Clean Architecture مع GetX

تم إعادة هيكلة المشروع لاستخدام **Clean Architecture** مع **GetX** لإدارة الحالة.

## البنية المعمارية

المشروع يتبع Clean Architecture مع ثلاث طبقات رئيسية:

### 1. Presentation Layer (طبقة العرض)
- **Pages**: صفحات الواجهة
- **Controllers**: Controllers من GetX لإدارة الحالة
- **Bindings**: ربط Controllers والتبعيات
- **Widgets**: مكونات الواجهة القابلة لإعادة الاستخدام

```
features/
  └── auth/
      └── presentation/
          ├── pages/
          ├── controllers/
          ├── bindings/
          └── widgets/
```

### 2. Domain Layer (طبقة الأعمال)
- **Entities**: الكيانات الأساسية
- **Use Cases**: حالات الاستخدام (Business Logic)
- **Repositories**: واجهات المستودعات

```
features/
  └── auth/
      └── domain/
          ├── entities/
          ├── use_cases/
          └── repositories/
```

### 3. Data Layer (طبقة البيانات)
- **Models**: نماذج البيانات (JSON serialization)
- **Data Sources**: مصادر البيانات (Remote/Local)
- **Repositories**: تطبيقات المستودعات

```
features/
  └── auth/
      └── data/
          ├── models/
          ├── datasources/
          └── repositories/
```

## مثال: ميزة Authentication

### Domain Layer

**Entity:**
```dart
class UserEntity {
  final String id;
  final String username;
  // ...
}
```

**Repository Interface:**
```dart
abstract class AuthRepository {
  Future<Map<String, dynamic>> login(String username, String password);
  Future<void> logout();
  Future<UserEntity> getCurrentUser();
}
```

**Use Case:**
```dart
class LoginUseCase {
  final AuthRepository repository;
  
  Future<Map<String, dynamic>> call(String username, String password) {
    return repository.login(username, password);
  }
}
```

### Data Layer

**Model:**
```dart
@JsonSerializable()
class UserModel extends UserEntity {
  // JSON serialization
}
```

**Data Source:**
```dart
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  // API calls using Dio
}
```

**Repository Implementation:**
```dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  
  // Implementation
}
```

### Presentation Layer

**Controller:**
```dart
class AuthController extends GetxController {
  final LoginUseCase loginUseCase;
  
  Future<void> login(String username, String password) async {
    // Use case execution
  }
}
```

**Binding:**
```dart
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Dependency injection
    Get.lazyPut(() => AuthController(...));
  }
}
```

**Page:**
```dart
class LoginPage extends GetView<AuthController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // UI
    );
  }
}
```

## Dependency Injection

يتم استخدام GetX للـ Dependency Injection في `InjectionContainer`:

```dart
class InjectionContainer {
  static Future<void> init() async {
    // Dio, Storage, etc.
    Get.put<Dio>(...);
    Get.put<SecureStorageService>(...);
  }
}
```

وفي Bindings:

```dart
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRemoteDataSource>(...);
    Get.lazyPut<AuthRepository>(...);
    Get.lazyPut(() => LoginUseCase(...));
    Get.lazyPut(() => AuthController(...));
  }
}
```

## Routing

يتم استخدام GetX Routing:

```dart
class AppPages {
  static final routes = [
    GetPage(
      name: Routes.login,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),
  ];
}
```

## المزايا

1. **فصل الاهتمامات**: كل طبقة لها مسؤولية واضحة
2. **سهولة الاختبار**: يمكن اختبار كل طبقة بشكل مستقل
3. **إعادة الاستخدام**: Use Cases يمكن استخدامها في أماكن متعددة
4. **سهولة الصيانة**: الكود منظم وواضح
5. **GetX**: إدارة حالة قوية وسهلة مع Dependency Injection مدمجة

## الخطوات التالية

- إكمال باقي الميزات بنفس النمط
- إضافة Unit Tests لكل طبقة
- إضافة Integration Tests
