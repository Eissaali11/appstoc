import 'dart:convert';
import 'package:dio/dio.dart';
import '../storage/local_cache.dart';

/// إعداد عنوان الـ API ديناميكياً دون تعديل الكود.
///
/// يعمل التطبيق كالتالي:
/// 1. يحاول جلب العنوان من عنوان ثابت (Config URL) يُرجع JSON: {"baseUrl": "https://..."}
/// 2. إن نجح، يحفظ العنوان محلياً ويستخدمه
/// 3. إن فشل (لا إنترنت أو الخادم معطل)، يستخدم آخر عنوان محفوظ
/// 4. إن لم يوجد محفوظ، يستخدم القيمة الافتراضية أدناه
///
/// **لتغيير الدومين بعد تغيير الاستضافة:**
/// - ضع ملف config على عنوان ثابت (نفس الخادم أو دومين آخر) يُرجع: {"baseUrl": "https://الدومين-الجديد"}
/// - أو أضف في الخادم مسار GET /api/config يُرجع نفس الـ JSON
/// - التطبيق عند التشغيل التالي سيجلبه تلقائياً ولن تحتاج لتعديل الكود
class ApiConfig {
  /// القيمة الافتراضية عند أول تشغيل أو عند فشل جلب الإعداد
  static const String defaultBaseUrl =
      'https://fcf0121e-0593-4710-ad11-105d54ba692e-00-3cyb0wsnu78xa.janeway.replit.dev';

  /// إن وُضع هنا عنوان ثابت (مثل https://config.example.com/app.json) فالتطبيق سيجلب منه عنوان الـ API،
  /// وعند تغيير الاستضافة تكفي تحديث محتوى ذلك الملف دون أي تعديل في التطبيق.
  /// null = استخدام نفس الخادم الافتراضي: defaultBaseUrl + '/api/config'
  static const String? stableConfigUrl = null;

  /// عنوان جلب الإعداد
  static String get configUrl =>
      stableConfigUrl ?? '$defaultBaseUrl/api/config';

  static const String _cacheKeyBaseUrl = 'api_base_url';
  static const String _cacheKeyFetchedAt = 'api_config_fetched_at';
  /// مدة صلاحية الكاش (ساعة) قبل إعادة الجلب
  static const Duration _cacheValidDuration = Duration(hours: 1);

  /// يُرجع عنوان الـ API الحالي (من الكاش أو من الخادم أو الافتراضي)
  static Future<String> getBaseUrl() async {
    try {
      final box = await LocalCache.getUserBox();
      final cached = box.get(_cacheKeyBaseUrl) as String?;
      final fetchedAt = box.get(_cacheKeyFetchedAt) as int?;

      final now = DateTime.now().millisecondsSinceEpoch;
      final cacheValid = fetchedAt != null &&
          (now - fetchedAt) < _cacheValidDuration.inMilliseconds;

      if (cached != null && cached.isNotEmpty && cacheValid) {
        return _normalizeBaseUrl(cached);
      }

      final fetched = await _fetchBaseUrlFromConfig();
      if (fetched != null && fetched.isNotEmpty) {
        await box.put(_cacheKeyBaseUrl, fetched);
        await box.put(_cacheKeyFetchedAt, now);
        return _normalizeBaseUrl(fetched);
      }

      if (cached != null && cached.isNotEmpty) {
        return _normalizeBaseUrl(cached);
      }
    } catch (_) {
      try {
        final box = await LocalCache.getUserBox();
        final cached = box.get(_cacheKeyBaseUrl) as String?;
        if (cached != null && cached.isNotEmpty) {
          return _normalizeBaseUrl(cached);
        }
      } catch (_) {}
    }

    return _normalizeBaseUrl(defaultBaseUrl);
  }

  static String _normalizeBaseUrl(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static Future<String?> _fetchBaseUrlFromConfig() async {
    try {
      final dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8)));
      final response = await dio.get(configUrl);
      if (response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final url = data['baseUrl'] as String?;
        return url?.trim();
      }
      if (response.data is String) {
        final decoded = jsonDecode(response.data as String) as Map<String, dynamic>?;
        final url = decoded?['baseUrl'] as String?;
        return url?.trim();
      }
    } catch (_) {}
    return null;
  }

  /// مسح الكاش لإجبار التطبيق على جلب الإعداد من الخادم عند التشغيل التالي
  static Future<void> clearCache() async {
    try {
      final box = await LocalCache.getUserBox();
      await box.delete(_cacheKeyBaseUrl);
      await box.delete(_cacheKeyFetchedAt);
    } catch (_) {}
  }
}
