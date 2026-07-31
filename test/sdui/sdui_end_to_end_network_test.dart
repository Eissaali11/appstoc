import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

import 'package:nuolipapp/core/sdui/repositories/sdui_filter_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String publicKeyHex;
  late String officialServerUrl;

  setUpAll(() async {
    HttpOverrides.global = null;

    // 1. Sign initial config for Official Backend
    final signResult = await Process.run('node', [
      'D:/nulip-new.worktrees/server-driven-filters-phase0/test/support/sign_backend_config.cjs',
      '1',
      'جميع العهد (محدث من خادم nulip-inventory الرسمي)'
    ]);
    expect(signResult.exitCode, equals(0));
    final meta = jsonDecode(signResult.stdout.toString().trim());
    publicKeyHex = meta['pubKeyHex'] as String;

    officialServerUrl = 'http://localhost:3005/api/mobile/v1/screens/custody/filters';
  });

  group('Official nulip-inventory Backend to Flutter Integration Tests', () {
    test('1. Connects to OFFICIAL nulip-inventory Express endpoint and verifies live Ed25519 signature', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = const FlutterSecureStorage();
      final dio = Dio();

      final repo = SduiFilterRepository(dio: dio, storage: storage);
      final config = await repo.getFilterConfig(
        endpointUrl: officialServerUrl,
        customPublicKeyHex: publicKeyHex,
      );

      expect(config.configVersion, equals(1));
      expect(config.filters.first.label, contains('جميع العهد (محدث من خادم nulip-inventory الرسمي)'));
    });

    test('2. Backend configuration update changes Flutter UI label dynamically without APK rebuild', () async {
      // Modify backend config label on disk without changing Flutter code or rebuilding
      final updateResult = await Process.run('node', [
        'D:/nulip-new.worktrees/server-driven-filters-phase0/test/support/sign_backend_config.cjs',
        '2',
        'جميع عهد الفني المحدثة مسبقاً من السيرفر الأصلي'
      ]);
      expect(updateResult.exitCode, equals(0));

      final storage = const FlutterSecureStorage();
      final dio = Dio();
      final repo = SduiFilterRepository(dio: dio, storage: storage);

      final updatedConfig = await repo.getFilterConfig(
        endpointUrl: officialServerUrl,
        customPublicKeyHex: publicKeyHex,
      );

      expect(updatedConfig.configVersion, equals(2));
      expect(updatedConfig.filters.first.label, equals('جميع عهد الفني المحدثة مسبقاً من السيرفر الأصلي'));
    });

    test('3. ETag 304 response handled correctly from Official Backend', () async {
      final storage = const FlutterSecureStorage();
      final dio = Dio();
      final repo = SduiFilterRepository(dio: dio, storage: storage);

      final cachedConfig = await repo.getFilterConfig(
        endpointUrl: officialServerUrl,
        customPublicKeyHex: publicKeyHex,
      );

      expect(cachedConfig.filters.first.label, equals('جميع عهد الفني المحدثة مسبقاً من السيرفر الأصلي'));
    });
  });
}
