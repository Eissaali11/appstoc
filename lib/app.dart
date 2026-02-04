import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'core/routing/app_pages.dart';
import 'core/l10n/app_translations.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/bindings/auth_binding.dart';

class App extends StatelessWidget {
  final String initialLocaleCode;

  const App({super.key, this.initialLocaleCode = 'ar'});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Stock',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      translations: AppTranslations(),
      locale: Locale(initialLocaleCode),
      fallbackLocale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      initialBinding: AuthBinding(),
      defaultTransition: Transition.fade,
      getPages: AppPages.routes,
      home: const SplashPage(),
      builder: (context, child) {
        final isRtl = Get.locale?.languageCode == 'ar';
        return Directionality(
          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
    );
  }
}
