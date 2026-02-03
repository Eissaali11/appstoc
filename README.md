# NuolipApp - Flutter Technician Mobile Application

تطبيق Flutter للفنيين لإدارة المخزون والمستودعات

## 📱 نظرة عامة

تطبيق Flutter متكامل للفنيين يتيح إدارة المخزون الثابت والمتحرك، طلبات النقل، الإشعارات، وإدخال بيانات الأجهزة.

## 🏗️ البنية المعمارية

- **Clean Architecture**: فصل واضح بين الطبقات (Presentation, Domain, Data)
- **GetX State Management**: إدارة الحالة بشكل فعال
- **Dependency Injection**: استخدام GetX للـ DI

## 🛠️ التقنيات المستخدمة

### State Management
- `get: ^4.7.3` - GetX للـ state management والـ routing

### Networking
- `dio: ^5.4.0` - HTTP client
- `json_annotation: ^4.9.0` - JSON serialization

### Storage
- `flutter_secure_storage: ^9.0.0` - تخزين آمن للـ tokens
- `hive_flutter: ^1.1.0` - Local caching

### UI Components
- `google_fonts: ^6.1.0` - خط Cairo للعربية
- `shimmer: ^3.0.0` - Loading effects
- `cached_network_image: ^3.3.1` - Image caching

### Utilities
- `intl: ^0.20.2` - Internationalization
- `excel: ^4.0.2` - Excel export
- `share_plus: ^7.2.1` - File sharing
- `mobile_scanner: ^3.5.6` - Barcode scanning

## 📁 هيكل المشروع

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart
│   │   ├── api_endpoints.dart
│   │   └── interceptors/
│   ├── di/
│   │   └── injection_container.dart
│   ├── routing/
│   │   └── app_pages.dart
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_theme.dart
│   │   └── text_styles.dart
│   └── storage/
│       ├── secure_storage.dart
│       └── local_cache.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   ├── dashboard/
│   ├── fixed_inventory/
│   ├── moving_inventory/
│   ├── notifications/
│   ├── profile/
│   ├── received_devices/
│   └── request_inventory/
└── shared/
    ├── models/
    └── widgets/
```

## 🚀 البدء السريع

### المتطلبات
- Flutter 3.x
- Dart 3.x
- Android Studio / VS Code
- Android SDK

### التثبيت

1. **استنساخ المستودع**:
```bash
git clone https://github.com/yourusername/nuolipapp.git
cd nuolipapp
```

2. **تثبيت التبعيات**:
```bash
flutter pub get
```

3. **تشغيل التطبيق**:
```bash
flutter run
```

## 🔐 الإعدادات

### Base URL
قم بتحديث `lib/core/api/api_endpoints.dart` مع Base URL الخاص بك:

```dart
static const String baseUrl = 'https://your-api-url.com';
```

### Authentication
التطبيق يستخدم JWT tokens مخزنة بشكل آمن في `flutter_secure_storage`.

## 📱 الميزات

- ✅ تسجيل الدخول والخروج
- ✅ لوحة تحكم احترافية مع إحصائيات
- ✅ إدارة المخزون الثابت
- ✅ إدارة المخزون المتحرك
- ✅ طلبات النقل والإشعارات
- ✅ إدخال بيانات الأجهزة
- ✅ طلب مخزون جديد
- ✅ دعم RTL للغة العربية
- ✅ تصميم Material 3 مع تأثيرات Glassmorphism

## 🎨 التصميم

- **الألوان**: تركواز (#18B2B0) مع خلفية داكنة
- **الخط**: Cairo من Google Fonts
- **التأثيرات**: Glassmorphism, Shimmer, Animations

## 📡 API Endpoints

### Authentication
- `POST /api/auth/login` - تسجيل الدخول
- `POST /api/auth/logout` - تسجيل الخروج
- `GET /api/auth/me` - بيانات المستخدم الحالي

### Inventory
- `GET /api/technicians/:id/fixed-inventory-entries` - المخزون الثابت
- `GET /api/technicians/:id/moving-inventory-entries` - المخزون المتحرك
- `PUT /api/technicians/:id/fixed-inventory-entries` - تحديث المخزون الثابت
- `PUT /api/technicians/:id/moving-inventory-entries` - تحديث المخزون المتحرك

### Transfers
- `GET /api/warehouse-transfers` - طلبات النقل
- `POST /api/warehouse-transfers/:id/accept` - قبول طلب نقل
- `POST /api/warehouse-transfers/:id/reject` - رفض طلب نقل

## 🧪 الاختبار

```bash
flutter test
```

## 📦 البناء

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 المساهمة

1. Fork المشروع
2. إنشاء branch للميزة (`git checkout -b feature/AmazingFeature`)
3. Commit التغييرات (`git commit -m 'Add some AmazingFeature'`)
4. Push إلى Branch (`git push origin feature/AmazingFeature`)
5. فتح Pull Request

## 📄 الترخيص

هذا المشروع خاص - جميع الحقوق محفوظة

## 👥 الفريق

- Developer: NuolipApp Team

## 📞 التواصل

للدعم والاستفسارات، يرجى فتح Issue في المستودع.

---

**ملاحظة**: تأكد من توفير مساحة كافية (10+ GB) على القرص الصلب للبناء.
