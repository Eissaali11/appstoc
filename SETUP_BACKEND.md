# إعداد Backend URL

## ⚠️ مهم جداً

قبل تشغيل التطبيق، يجب تحديث `baseUrl` في الملف:
**`lib/core/api/api_endpoints.dart`**

## الخطوات:

1. افتح الملف: `lib/core/api/api_endpoints.dart`
2. ابحث عن السطر:
   ```dart
   static const String baseUrl = 'https://your-replit-app.replit.app';
   ```
3. استبدله بـ URL الخادم الفعلي:
   ```dart
   static const String baseUrl = 'https://your-actual-backend-url.com';
   ```

## مثال:

إذا كان خادمك على Replit:
```dart
static const String baseUrl = 'https://your-app-name.your-username.repl.co';
```

إذا كان خادمك على خادم آخر:
```dart
static const String baseUrl = 'https://api.yourdomain.com';
```

## التحقق من الاتصال:

بعد تحديث URL، شغل التطبيق وسترى في Console:
- ✅ Status Code: 200 (نجح)
- ❌ Status Code: 404 (URL غير صحيح)
- ❌ Failed host lookup (URL غير موجود)

## ملاحظات:

- تأكد من أن URL يبدأ بـ `https://` أو `http://`
- تأكد من عدم وجود `/` في نهاية URL
- تأكد من أن الخادم يعمل ومتاح
