import 'package:hive_flutter/hive_flutter.dart';

class LocalCache {
  static const String _inventoryBox = 'inventory_cache';
  static const String _userBox = 'user_cache';

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

  static Future<void> clearCache() async {
    final inventoryBox = await getInventoryBox();
    final userBox = await getUserBox();
    await inventoryBox.clear();
    await userBox.clear();
  }
}
