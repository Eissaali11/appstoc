import 'package:hive_flutter/hive_flutter.dart';

class LocalCache {
  static const String _inventoryBox = 'inventory_cache';
  static const String _userBox = 'user_cache';
  static const String _keyAppLanguage = 'app_language';

  static Future<void> init() async {
    await Hive.initFlutter();
  }

  static Future<Box> getInventoryBox() async {
    if (!Hive.isBoxOpen(_inventoryBox)) {
      return await Hive.openBox(_inventoryBox);
    }
    return Hive.box(_inventoryBox);
  }

  static Future<Box> getUserBox() async {
    if (!Hive.isBoxOpen(_userBox)) {
      return await Hive.openBox(_userBox);
    }
    return Hive.box(_userBox);
  }

  /// لغة التطبيق: 'ar' أو 'en'
  static Future<String?> getAppLanguage() async {
    final box = await getUserBox();
    return box.get(_keyAppLanguage) as String?;
  }

  static Future<void> setAppLanguage(String languageCode) async {
    final box = await getUserBox();
    await box.put(_keyAppLanguage, languageCode);
  }

  static Future<void> clearCache() async {
    final inventoryBox = await getInventoryBox();
    final userBox = await getUserBox();
    await inventoryBox.clear();
    await userBox.clear();
  }
}
