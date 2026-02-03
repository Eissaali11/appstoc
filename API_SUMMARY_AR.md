# 📡 ملخص طلبات API - تسجيل الدخول

## 🔗 Base URL
```
https://fcf0121e-0593-4710-ad11-105d54ba692e-00-3cyb0wsnu78xa.janeway.replit.dev
```
✅ **تم التحديث في:** `lib/core/api/api_endpoints.dart`

---

## 1️⃣ تسجيل الدخول

### الطلب
```http
POST /api/auth/login
Content-Type: application/json
```

### Body
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

### الاستجابة الناجحة (200)
```json
{
  "success": true,
  "user": {
    "id": "...",
    "username": "Rasco8439",
    "fullName": "...",
    "role": "technician",
    "regionId": "...",
    "city": "..."
  },
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "message": "تم تسجيل الدخول بنجاح"
}
```

---

## 2️⃣ الحصول على المستخدم الحالي

### الطلب
```http
GET /api/auth/me
Authorization: Bearer <token>
```

### الاستجابة الناجحة (200)
```json
{
  "id": "...",
  "username": "Rasco8439",
  "fullName": "...",
  "role": "technician",
  "regionId": "...",
  "city": "..."
}
```

---

## 3️⃣ تسجيل الخروج

### الطلب
```http
POST /api/auth/logout
Authorization: Bearer <token>
```

### الاستجابة الناجحة (200)
```json
{
  "success": true,
  "message": "تم تسجيل الخروج بنجاح"
}
```

---

## 📋 جدول سريع

| الطريقة | Endpoint | Token مطلوب | الوصف |
|---------|----------|-------------|--------|
| `POST` | `/api/auth/login` | ❌ | تسجيل الدخول |
| `GET` | `/api/auth/me` | ✅ | بيانات المستخدم |
| `POST` | `/api/auth/logout` | ✅ | تسجيل الخروج |

---

## 🔐 استخدام Token

بعد تسجيل الدخول، أرسل Token في Header:
```
Authorization: Bearer <token>
```

**ملاحظة:** يتم إضافة Token تلقائياً في تطبيق Flutter عبر `AuthInterceptor`.

---

## ⚠️ رموز الحالة

| الكود | المعنى |
|-------|--------|
| `200` | نجاح |
| `401` | غير مصرح |
| `404` | غير موجود |
| `500` | خطأ في الخادم |

---

## 🧪 اختبار سريع (cURL)

```bash
# تسجيل الدخول
curl -X POST https://fcf0121e-0593-4710-ad11-105d54ba692e-00-3cyb0wsnu78xa.janeway.replit.dev/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"Rasco8273","password":"كلمة_المرور"}'
```

---

## 📝 ملاحظات

1. ✅ يتم حفظ Token تلقائياً في `SecureStorage`
2. ✅ يتم إضافة Headers تلقائياً عبر `AuthInterceptor`
3. ✅ يتم معالجة الأخطاء تلقائياً عبر `ErrorInterceptor`
4. ✅ تم تحديث `baseUrl` في `api_endpoints.dart`

---

## 📚 ملفات التوثيق الكاملة

- `API_REQUESTS.md` - توثيق شامل للطلبات
- `API_DART_EXAMPLES.md` - أمثلة كود Dart
