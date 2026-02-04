import 'package:flutter/material.dart';
import 'core/di/injection_container.dart';
import 'core/storage/local_cache.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalCache.init();
  final savedLang = await LocalCache.getAppLanguage();
  await InjectionContainer.init();
  runApp(App(initialLocaleCode: savedLang ?? 'ar'));
}
