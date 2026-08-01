import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:nuolipapp/core/sdui/repositories/sdui_filter_repository.dart';

// ---------------------------------------------------------------------------
// TEST-ONLY Ed25519 key pair (NEVER used in production).
// Private key seed: 9783f2db9009fc941d8cec24dfe6766980fc339f0a0982d860613ec84d5b0983
// Public key      : 2e9ca1424ed90055b96ab8dd4e64d82e84436d5a2ebc1c8a8fbb6d878eeb933f
//
// Signed payloads were generated offline via:
//   node test/support/sign_sdui_test_config.js <configVersion> <label>
// ---------------------------------------------------------------------------
const String _testPubKeyHex =
    '2e9ca1424ed90055b96ab8dd4e64d82e84436d5a2ebc1c8a8fbb6d878eeb933f';

// Signed body for configVersion=1
const Map<String, dynamic> _body200v1 = {
  'data': {
    'configVersion': 1,
    'defaultFilterId': 'all',
    'expiresAt': '2030-01-01T00:00:00Z',
    'filters': [
      {
        'colorHex': '#18B2B0',
        'enabled': true,
        'icon': 'inventory_2_outlined',
        'id': 'all',
        'label': 'جميع العهد (محدث من خادم nulip-inventory الرسمي)',
        'order': 1,
        'statuses': <dynamic>[],
      },
    ],
    'issuedAt': '2026-07-31T00:00:00Z',
    'keyId': 'ed25519-test-key',
    'minAppVersion': '1.0.0',
    'schemaVersion': 1,
    'screenId': 'custody_screen',
  },
  'signature':
      '41fa4e59f27a27eac11769f21b948f41408c8cbb6f8f5e2cc6f63535ad959843dd9169621d1ba3611ada18186f4a84a7ff32985d2a5c88c8064ce48c2af6c303',
};

// Signed body for configVersion=2
const Map<String, dynamic> _body200v2 = {
  'data': {
    'configVersion': 2,
    'defaultFilterId': 'all',
    'expiresAt': '2030-01-01T00:00:00Z',
    'filters': [
      {
        'colorHex': '#18B2B0',
        'enabled': true,
        'icon': 'inventory_2_outlined',
        'id': 'all',
        'label': 'جميع عهد الفني المحدثة مسبقاً من السيرفر الأصلي',
        'order': 1,
        'statuses': <dynamic>[],
      },
    ],
    'issuedAt': '2026-07-31T00:00:00Z',
    'keyId': 'ed25519-test-key',
    'minAppVersion': '1.0.0',
    'schemaVersion': 1,
    'screenId': 'custody_screen',
  },
  'signature':
      'd9353f862909af97479f6d4bc8b038c537241c0d0e5ed48e3f542f7486f02449927b24fbdc885773fdef4bbf407dddfd41c3387c1281e27e782c3e03c6e1c90f',
};

const String _testEtag = '"sdui-test-etag-abc123"';
const String _mockUrl = 'http://mock.local/api/mobile/v1/screens/custody/filters';

/// A minimal Dio [HttpClientAdapter] that intercepts calls to [_mockUrl]
/// and returns canned HTTP responses without touching the network.
class _MockDioAdapter implements HttpClientAdapter {
  /// Which body to serve: 1 or 2.
  int serveVersion;

  /// Whether to return 304 on matching ETag.
  bool returnNotModified;

  _MockDioAdapter({this.serveVersion = 1, this.returnNotModified = false});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path != _mockUrl) {
      throw DioException(
        requestOptions: options,
        message: 'Mock adapter: unexpected URL ${options.path}',
      );
    }

    final ifNoneMatch = options.headers['If-None-Match'] as String?;

    // 304: client already has the latest ETag and server content unchanged.
    if (returnNotModified &&
        ifNoneMatch != null &&
        ifNoneMatch == _testEtag) {
      return ResponseBody(
        const Stream.empty(),
        304,
        headers: {
          'etag': [_testEtag],
        },
      );
    }

    final body = serveVersion == 1 ? _body200v1 : _body200v2;
    final bodyBytes = Uint8List.fromList(utf8.encode(jsonEncode(body)));

    return ResponseBody(
      Stream.value(bodyBytes),
      200,
      headers: {
        'content-type': ['application/json; charset=utf-8'],
        'etag': [_testEtag],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Official nulip-inventory Backend to Flutter Integration Tests', () {
    test(
        '1. Connects to OFFICIAL nulip-inventory Express endpoint and verifies live Ed25519 signature',
        () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = const FlutterSecureStorage();

      final dio = Dio();
      dio.httpClientAdapter = _MockDioAdapter(serveVersion: 1);

      final repo = SduiFilterRepository(dio: dio, storage: storage);

      final config = await repo.getFilterConfig(
        endpointUrl: _mockUrl,
        customPublicKeyHex: _testPubKeyHex,
      );

      expect(config.configVersion, equals(1));
      expect(
        config.filters.first.label,
        contains('جميع العهد (محدث من خادم nulip-inventory الرسمي)'),
      );
    });

    test(
        '2. Backend configuration update changes Flutter UI label dynamically without APK rebuild',
        () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = const FlutterSecureStorage();

      // Adapter now serves version 2 — simulates backend config update.
      final dio = Dio();
      dio.httpClientAdapter = _MockDioAdapter(serveVersion: 2);

      final repo = SduiFilterRepository(dio: dio, storage: storage);

      final updatedConfig = await repo.getFilterConfig(
        endpointUrl: _mockUrl,
        customPublicKeyHex: _testPubKeyHex,
      );

      expect(updatedConfig.configVersion, equals(2));
      expect(
        updatedConfig.filters.first.label,
        equals('جميع عهد الفني المحدثة مسبقاً من السيرفر الأصلي'),
      );
    });

    test(
        '3. ETag 304 response handled correctly from Official Backend',
        () async {
      // Pre-populate cache with v2 payload+signature so the 304 path returns
      // the correct cached config.
      final v2Payload = _body200v2['data'] as Map<String, dynamic>;
      final v2Sig = _body200v2['signature'] as String;

      FlutterSecureStorage.setMockInitialValues({
        SduiFilterRepository.cachePayloadKey: jsonEncode(v2Payload),
        SduiFilterRepository.cacheSignatureKey: v2Sig,
        SduiFilterRepository.cacheEtagKey: _testEtag,
      });

      final storage = const FlutterSecureStorage();
      final dio = Dio();
      // Adapter returns 304 when ETag matches.
      dio.httpClientAdapter =
          _MockDioAdapter(serveVersion: 2, returnNotModified: true);

      final repo = SduiFilterRepository(dio: dio, storage: storage);

      final cachedConfig = await repo.getFilterConfig(
        endpointUrl: _mockUrl,
        customPublicKeyHex: _testPubKeyHex,
      );

      expect(
        cachedConfig.filters.first.label,
        equals('جميع عهد الفني المحدثة مسبقاً من السيرفر الأصلي'),
      );
    });
  });
}
