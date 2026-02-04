import 'package:get/get.dart';
import 'ar.dart';
import 'en.dart';

/// تسجيل ترجمات التطبيق (عربي / إنجليزي) لـ GetX
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'ar': ar,
        'en': en,
      };
}
