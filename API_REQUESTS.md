# 📡 طلبات API - تسجيل الدخول

هذا الملف يوضح جميع طلبات API المتعلقة بتسجيل الدخول التي يرسلها تطبيق Flutter إلى خادم Replit.

---

## 🔧 الإعدادات الأساسية

### Base URL
```
https://fcf0121e-0593-4710-ad11-105d54ba692e-00-3cyb0wsnu78xa.janeway.replit.dev
```

**✅ تم التحديث:** `baseUrl` في `lib/core/api/api_endpoints.dart` محدث الآن.

### Headers الافتراضية
جميع الطلبات ترسل مع الـ Headers التالية:
```
Content-Type: application/json
Accept: application/json
```

---

## 1️⃣ تسجيل الدخول (Login)

### الطلب
```http
POST /api/auth/login
Content-Type: application/json
Accept: application/json
```

### Request Body
```json
{
  "username": "Rasco8273",
  "password": "كلمة المرور"
}
```

**مستخدم للاختبار:**
- Username: `Rasco8273`
- الاسم: مصعب الفاضل
- الدور: technician

### Response (نجاح - 200)
```json
{
  "success": true,
  "user": {
    "id": "user-id-123",
    "username": "Rasco8439",
    "fullName": "اسم المستخدم الكامل",
    "role": "technician",
    "isActive": true,
    "regionId": "region-id-123",
    "city": "اسم المدينة"
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "message": "تم تسجيل الدخول بنجاح"
}
```

### Response (فشل - 401)
```json
{
  "success": false,
  "message": "اسم المستخدم أو كلمة المرور غير صحيحة"
}
```

### Response (خطأ - 404)
```json
{
  "message": "الخادم غير متاح"
}
```

### Response (خطأ - 500)
```json
{
  "message": "خطأ في الخادم"
}
```

### مثال باستخدام cURL
```bash
curl -X POST https://fcf0121e-0593-4710-ad11-105d54ba692e-00-3cyb0wsnu78xa.janeway.replit.dev/api/auth/login \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "username": "Rasco8439",
    "password": "@Aa12345678"
  }'
```

### مثال باستخدام Postman
1. **Method:** `POST`
2. **URL:** `https://fcf0121e-0593-4710-ad11-105d54ba692e-00-3cyb0wsnu78xa.janeway.replit.dev/api/auth/login`
3. **Headers:**
   - `Content-Type: application/json`
   - `Accept: application/json`
4. **Body (raw JSON):**
   ```json
   {
     "username": "Rasco8439",
     "password": "@Aa12345678"
   }
   ```

---

## 2️⃣ الحصول على بيانات المستخدم الحالي (Get Current User)

### الطلب
```http
GET /api/auth/me
Authorization: Bearer <token>
Content-Type: application/json
Accept: application/json
```

### Headers المطلوبة
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
Accept: application/json
```

### Response (نجاح - 200)
```json
{
  "id": "user-id-123",
  "username": "Rasco8439",
  "fullName": "اسم المستخدم الكامل",
  "role": "technician",
  "isActive": true,
  "regionId": "region-id-123",
  "city": "اسم المدينة"
}
```

### Response (فشل - 401)
```json
{
  "message": "غير مصرح. يرجى تسجيل الدخول مرة أخرى"
}
```

### مثال باستخدام cURL
```bash
curl -X GET https://fcf0121e-0593-4710-ad11-105d54ba692e-00-3cyb0wsnu78xa.janeway.replit.dev/api/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json"
```

### مثال باستخدام Postman
1. **Method:** `GET`
2. **URL:** `https://fcf0121e-0593-4710-ad11-105d54ba692e-00-3cyb0wsnu78xa.janeway.replit.dev/api/auth/me`
3. **Headers:**
   - `Authorization: Bearer YOUR_TOKEN_HERE`
   - `Content-Type: application/json`
   - `Accept: application/json`

---

## 3️⃣ تسجيل الخروج (Logout)

### الطلب
```http
POST /api/auth/logout
Authorization: Bearer <token>
Content-Type: application/json
Accept: application/json
```

### Headers المطلوبة
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json
Accept: application/json
```

### Request Body
لا يحتاج إلى body (يمكن إرسال body فارغ)

### Response (نجاح - 200)
```json
{
  "success": true,
  "message": "تم تسجيل الخروج بنجاح"
}
```

### Response (فشل - 401)
```json
{
  "message": "غير مصرح"
}
```

### مثال باستخدام cURL
```bash
curl -X POST https://fcf0121e-0593-4710-ad11-105d54ba692e-00-3cyb0wsnu78xa.janeway.replit.dev/api/auth/logout \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json"
```

### مثال باستخدام Postman
1. **Method:** `POST`
2. **URL:** `https://fcf0121e-0593-4710-ad11-105d54ba692e-00-3cyb0wsnu78xa.janeway.replit.dev/api/auth/logout`
3. **Headers:**
   - `Authorization: Bearer YOUR_TOKEN_HERE`
   - `Content-Type: application/json`
   - `Accept: application/json`

---

## 📋 ملخص الـ Endpoints

| الطريقة | Endpoint | يتطلب Token | الوصف |
|---------|----------|-------------|--------|
| `POST` | `/api/auth/login` | ❌ لا | تسجيل الدخول |
| `GET` | `/api/auth/me` | ✅ نعم | الحصول على بيانات المستخدم الحالي |
| `POST` | `/api/auth/logout` | ✅ نعم | تسجيل الخروج |

---

## 🔐 استخدام الـ Token

بعد تسجيل الدخول الناجح:
1. احفظ الـ `token` من الاستجابة
2. أرسل الـ token في جميع الطلبات اللاحقة في header:
   ```
   Authorization: Bearer <token>
   ```

### في تطبيق Flutter
يتم حفظ الـ token تلقائياً في `SecureStorage` بعد تسجيل الدخول الناجح، ويتم إضافته تلقائياً إلى جميع الطلبات عبر `AuthInterceptor`.

---

## ⚠️ رموز الحالة (Status Codes)

| الكود | المعنى | الوصف |
|-------|--------|-------|
| `200` | OK | الطلب نجح |
| `201` | Created | تم إنشاء الموارد بنجاح |
| `400` | Bad Request | الطلب غير صحيح |
| `401` | Unauthorized | غير مصرح - تحقق من الـ token |
| `403` | Forbidden | غير مسموح |
| `404` | Not Found | الـ endpoint غير موجود |
| `500` | Internal Server Error | خطأ في الخادم |

---

## 🧪 اختبار الطلبات

### استخدام Postman
1. أنشئ Collection جديد باسم "Inventory App API"
2. أضف Environment variables:
   - `baseUrl`: `https://fcf0121e-0593-4710-ad11-105d54ba692e-00-3cyb0wsnu78xa.janeway.replit.dev`
   - `token`: (سيتم ملؤه بعد تسجيل الدخول)
3. أضف الطلبات الثلاثة أعلاه
4. استخدم Pre-request Script لإضافة الـ token تلقائياً:
   ```javascript
   if (pm.environment.get("token")) {
       pm.request.headers.add({
           key: "Authorization",
           value: "Bearer " + pm.environment.get("token")
       });
   }
   ```

### استخدام cURL (Terminal)
```bash
# 1. تسجيل الدخول
TOKEN=$(curl -s -X POST https://fcf0121e-0593-4710-ad11-105d54ba692e-00-3cyb0wsnu78xa.janeway.replit.dev/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"Rasco8273","password":"كلمة_المرور"}' \
  | jq -r '.token')

# 2. الحصول على بيانات المستخدم
curl -X GET https://fcf0121e-0593-4710-ad11-105d54ba692e-00-3cyb0wsnu78xa.janeway.replit.dev/api/auth/me \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"

# 3. تسجيل الخروج
curl -X POST https://fcf0121e-0593-4710-ad11-105d54ba692e-00-3cyb0wsnu78xa.janeway.replit.dev/api/auth/logout \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
```

---

## 📝 ملاحظات مهمة

1. **الـ Base URL:** يجب تحديثه في `lib/core/api/api_endpoints.dart`
2. **الـ Token:** يتم حفظه تلقائياً في `SecureStorage` بعد تسجيل الدخول
3. **الـ Headers:** يتم إضافتها تلقائياً عبر `AuthInterceptor`
4. **معالجة الأخطاء:** جميع الأخطاء يتم معالجتها في `ErrorInterceptor`
5. **الـ Logging:** يتم تسجيل جميع الطلبات والاستجابات في الـ console

---

## 🔍 Debugging

إذا واجهت مشاكل في تسجيل الدخول:

1. **تحقق من الـ Base URL:**
   - افتح `lib/core/api/api_endpoints.dart`
   - تأكد من أن `baseUrl` محدث إلى عنوان الخادم الفعلي

2. **تحقق من الـ Console Logs:**
   - ابحث عن رسائل تبدأ بـ `🔐` و `📍` و `✅` أو `❌`
   - هذه الرسائل توضح URL الطلب، Status Code، والاستجابة

3. **اختبر الطلب مباشرة:**
   - استخدم Postman أو cURL لاختبار الطلب مباشرة
   - تأكد من أن الخادم يعمل وأن الـ endpoint متاح

4. **تحقق من الـ Network:**
   - تأكد من وجود اتصال بالإنترنت
   - تحقق من أن الخادم متاح وليس معطل

---

## 📞 الدعم

إذا استمرت المشاكل:
1. تحقق من سجلات الخادم (Server Logs)
2. تحقق من أن الـ API endpoints تعمل بشكل صحيح
3. تأكد من أن البيانات المرسلة صحيحة (username, password)
4. تحقق من أن الاستجابة تحتوي على `success: true`, `user`, و `token`
