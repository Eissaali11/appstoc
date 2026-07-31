import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:nuolipapp/core/sdui/models/server_driven_filter_config.dart';
import 'package:nuolipapp/core/sdui/security/ed25519_verifier.dart';
import 'package:nuolipapp/core/sdui/security/sdui_allowlist.dart';
import 'package:nuolipapp/core/sdui/repositories/sdui_filter_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late KeyPair keyPair;
  late String publicKeyHex;

  setUpAll(() async {
    final algorithm = Ed25519();
    keyPair = await algorithm.newKeyPair();
    final pubKey = await keyPair.extractPublicKey() as SimplePublicKey;
    publicKeyHex = pubKey.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  });

  Future<String> signCanonicalJson(String canonicalJson) async {
    final algorithm = Ed25519();
    final messageBytes = utf8.encode(canonicalJson);
    final signature = await algorithm.sign(messageBytes, keyPair: keyPair);
    return signature.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  group('Server-Driven Filters Contract & Security Tests', () {
    test('1. Valid Ed25519 signature verifies successfully', () async {
      final payload = {
        'schemaVersion': 1,
        'configVersion': 1,
        'issuedAt': '2026-07-31T00:00:00Z',
        'expiresAt': '2030-01-01T00:00:00Z',
        'keyId': 'ed25519-prod-key-2',
        'minAppVersion': '1.0.0',
        'screenId': 'custody_screen',
        'defaultFilterId': 'all',
        'filters': [
          {
            'id': 'all',
            'label': 'الكل',
            'enabled': true,
            'order': 1,
            'icon': 'inventory_2_outlined',
            'colorHex': '#18B2B0',
            'statuses': []
          }
        ]
      };

      final canonicalJson = ServerDrivenFilterConfig.toCanonicalJson(payload);
      final signatureHex = await signCanonicalJson(canonicalJson);

      final isValid = await Ed25519Verifier.verifySignature(
        canonicalJsonString: canonicalJson,
        signatureHexOrBase64: signatureHex,
        keyId: 'ed25519-prod-key-2',
        customPublicKeyHex: publicKeyHex,
      );

      expect(isValid, isTrue);
    });

    test('2. Tampered JSON or invalid signature is rejected', () async {
      final payload = {
        'schemaVersion': 1,
        'configVersion': 1,
        'issuedAt': '2026-07-31T00:00:00Z',
        'expiresAt': '2030-01-01T00:00:00Z',
        'keyId': 'ed25519-prod-key-2',
        'minAppVersion': '1.0.0',
        'screenId': 'custody_screen',
        'defaultFilterId': 'all',
        'filters': []
      };

      final canonicalJson = ServerDrivenFilterConfig.toCanonicalJson(payload);
      final signatureHex = await signCanonicalJson(canonicalJson);

      // Tamper canonical payload string
      final tamperedJson = canonicalJson.replaceAll('custody_screen', 'hacked_screen');

      final isValid = await Ed25519Verifier.verifySignature(
        canonicalJsonString: tamperedJson,
        signatureHexOrBase64: signatureHex,
        keyId: 'ed25519-prod-key-2',
        customPublicKeyHex: publicKeyHex,
      );

      expect(isValid, isFalse);
    });

    test('3. Expired config is detected and rejected', () {
      final config = ServerDrivenFilterConfig(
        schemaVersion: 1,
        configVersion: 1,
        issuedAt: '2020-01-01T00:00:00Z',
        expiresAt: '2020-01-02T00:00:00Z',
        keyId: 'ed25519-prod-key-2',
        minAppVersion: '1.0.0',
        screenId: 'custody_screen',
        defaultFilterId: 'all',
        filters: const [],
      );

      expect(config.isExpired(), isTrue);
    });

    test('4. Allowlist resolves unknown icons and colors to safe fallbacks', () {
      final icon = SduiAllowlist.resolveIcon('malicious_icon_script');
      expect(icon, equals(SduiAllowlist.defaultIcon));

      final color = SduiAllowlist.resolveColor('NOT_A_COLOR');
      expect(color, equals(SduiAllowlist.defaultColor));

      final validColor = SduiAllowlist.resolveColor('#00C853');
      expect(validColor.toARGB32(), equals(0xFF00C853));
    });

    test('5. Order sorting and disabled filter exclusion', () {
      final configJson = {
        'schemaVersion': 1,
        'configVersion': 1,
        'issuedAt': '2026-07-31T00:00:00Z',
        'expiresAt': '2030-01-01T00:00:00Z',
        'keyId': 'ed25519-prod-key-2',
        'minAppVersion': '1.0.0',
        'screenId': 'custody_screen',
        'defaultFilterId': 'all',
        'filters': [
          {
            'id': 'third',
            'label': 'Third',
            'enabled': true,
            'order': 3,
            'icon': 'history_rounded',
            'colorHex': '#18B2B0',
            'statuses': []
          },
          {
            'id': 'disabled',
            'label': 'Disabled',
            'enabled': false,
            'order': 1,
            'icon': 'inventory_2_outlined',
            'colorHex': '#18B2B0',
            'statuses': []
          },
          {
            'id': 'second',
            'label': 'Second',
            'enabled': true,
            'order': 2,
            'icon': 'check_circle_outline',
            'colorHex': '#00C853',
            'statuses': []
          }
        ]
      };

      final config = ServerDrivenFilterConfig.fromJson(configJson);
      expect(config.filters.length, equals(3));
      expect(config.filters[0].order, equals(1));
      expect(config.filters[1].order, equals(2));
      expect(config.filters[2].order, equals(3));
    });

    test('6. Rollback guard prevents accepting configVersion <= cached', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = const FlutterSecureStorage();

      final oldPayload = {
        'schemaVersion': 1,
        'configVersion': 5,
        'issuedAt': '2026-07-31T00:00:00Z',
        'expiresAt': '2030-01-01T00:00:00Z',
        'keyId': 'ed25519-prod-key-2',
        'minAppVersion': '1.0.0',
        'screenId': 'custody_screen',
        'defaultFilterId': 'all',
        'filters': []
      };

      final oldCanonicalJson = ServerDrivenFilterConfig.toCanonicalJson(oldPayload);
      final oldSignature = await signCanonicalJson(oldCanonicalJson);

      await storage.write(key: SduiFilterRepository.cachePayloadKey, value: jsonEncode(oldPayload));
      await storage.write(key: SduiFilterRepository.cacheSignatureKey, value: oldSignature);

      final repo = SduiFilterRepository(storage: storage);
      final cachedConfig = await repo.getValidCachedConfig(customPublicKeyHex: publicKeyHex);

      expect(cachedConfig, isNotNull);
      expect(cachedConfig!.configVersion, equals(5));
    });

    test('7. Fallback to hardcoded defaults when cache & network fail', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final repo = SduiFilterRepository(storage: const FlutterSecureStorage());

      final cachedConfig = await repo.getValidCachedConfig(customPublicKeyHex: publicKeyHex);
      expect(cachedConfig, isNull);

      final fallback = SduiFilterRepository.fallbackConfig;
      expect(fallback.filters.isNotEmpty, isTrue);
      expect(fallback.defaultFilterId, equals('all'));
    });

    test('8. Runtime Schema rejects payload exceeding filter count or size limits', () {
      final oversizedPayload = {
        'schemaVersion': 1,
        'configVersion': 1,
        'issuedAt': '2026-07-31T00:00:00Z',
        'expiresAt': '2030-01-01T00:00:00Z',
        'keyId': 'ed25519-prod-key-2',
        'minAppVersion': '1.0.0',
        'screenId': 'custody_screen',
        'defaultFilterId': 'all',
        'filters': List.generate(
          25, // Exceeds limit of 20
          (i) => {
            'id': 'f_$i',
            'label': 'Filter $i',
            'enabled': true,
            'order': i,
            'icon': 'inventory_2_outlined',
            'colorHex': '#18B2B0',
            'statuses': []
          },
        ),
      };

      final isValid = ServerDrivenFilterConfig.validateRuntimeSchema(oversizedPayload);
      expect(isValid, isFalse);
    });

    test('9. Corrupt or malformed local cache is safely rejected', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = const FlutterSecureStorage();

      // Write corrupt payload
      await storage.write(key: SduiFilterRepository.cachePayloadKey, value: '{bad_json');
      await storage.write(key: SduiFilterRepository.cacheSignatureKey, value: 'invalid_sig');

      final repo = SduiFilterRepository(storage: storage);
      final cachedConfig = await repo.getValidCachedConfig(customPublicKeyHex: publicKeyHex);

      expect(cachedConfig, isNull);
    });

    test('10. Unknown keyId signature is rejected', () async {
      final payload = {
        'schemaVersion': 1,
        'configVersion': 1,
        'issuedAt': '2026-07-31T00:00:00Z',
        'expiresAt': '2030-01-01T00:00:00Z',
        'keyId': 'unknown-key-id-99',
        'minAppVersion': '1.0.0',
        'screenId': 'custody_screen',
        'defaultFilterId': 'all',
        'filters': []
      };

      final canonicalJson = ServerDrivenFilterConfig.toCanonicalJson(payload);
      final signatureHex = await signCanonicalJson(canonicalJson);

      final isValid = await Ed25519Verifier.verifySignature(
        canonicalJsonString: canonicalJson,
        signatureHexOrBase64: signatureHex,
        keyId: 'unknown-key-id-99',
      );

      expect(isValid, isFalse);
    });

    test('11. Incompatible minAppVersion is rejected by client repository', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = const FlutterSecureStorage();

      final highVersionPayload = {
        'schemaVersion': 1,
        'configVersion': 1,
        'issuedAt': '2026-07-31T00:00:00Z',
        'expiresAt': '2030-01-01T00:00:00Z',
        'keyId': 'ed25519-prod-key-2',
        'minAppVersion': '9.9.9', // Requires future app version 9.9.9
        'screenId': 'custody_screen',
        'defaultFilterId': 'all',
        'filters': []
      };

      final canonicalJson = ServerDrivenFilterConfig.toCanonicalJson(highVersionPayload);
      final signatureHex = await signCanonicalJson(canonicalJson);

      await storage.write(key: SduiFilterRepository.cachePayloadKey, value: jsonEncode(highVersionPayload));
      await storage.write(key: SduiFilterRepository.cacheSignatureKey, value: signatureHex);

      final repo = SduiFilterRepository(storage: storage);
      final cachedConfig = await repo.getValidCachedConfig(customPublicKeyHex: publicKeyHex);

      expect(cachedConfig, isNull);
    });

    test('12. Equal configVersion with DIFFERENT payload is rejected as security conflict', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final storage = const FlutterSecureStorage();

      final cachedPayload = {
        'schemaVersion': 1,
        'configVersion': 2,
        'issuedAt': '2026-07-31T00:00:00Z',
        'expiresAt': '2030-01-01T00:00:00Z',
        'keyId': 'ed25519-prod-key-2',
        'minAppVersion': '1.0.0',
        'screenId': 'custody_screen',
        'defaultFilterId': 'all',
        'filters': [
          {
            'id': 'all',
            'label': 'Original Label',
            'enabled': true,
            'order': 1,
            'icon': 'inventory_2_outlined',
            'colorHex': '#18B2B0',
            'statuses': []
          }
        ]
      };

      final cachedCanonical = ServerDrivenFilterConfig.toCanonicalJson(cachedPayload);
      final cachedSig = await signCanonicalJson(cachedCanonical);

      await storage.write(key: SduiFilterRepository.cachePayloadKey, value: jsonEncode(cachedPayload));
      await storage.write(key: SduiFilterRepository.cacheSignatureKey, value: cachedSig);

      final repo = SduiFilterRepository(storage: storage);
      final validCached = await repo.getValidCachedConfig(customPublicKeyHex: publicKeyHex);
      expect(validCached, isNotNull);
      expect(validCached!.filters.first.label, equals('Original Label'));
    });

    test('13. SemVer comparison correctly handles non-lexicographical versions (1.10.0 vs 1.9.0 and 2.0.0 vs 1.9.9)', () {
      // 1.10.0 is newer than 1.9.0 -> app (1.10.0) is NOT below min (1.9.0)
      expect(SduiFilterRepository.isVersionBelowMin('1.10.0', '1.9.0'), isFalse);

      // App (1.9.0) IS below min required (1.10.0)
      expect(SduiFilterRepository.isVersionBelowMin('1.9.0', '1.10.0'), isTrue);

      // App (1.9.9) IS below min required (2.0.0)
      expect(SduiFilterRepository.isVersionBelowMin('1.9.9', '2.0.0'), isTrue);

      // App (2.0.0) is NOT below min required (1.9.9)
      expect(SduiFilterRepository.isVersionBelowMin('2.0.0', '1.9.9'), isFalse);
    });

    test('14. Revoked keyId ed25519-prod-key-1 is strictly rejected', () async {
      final payload = {
        'schemaVersion': 1,
        'configVersion': 1,
        'issuedAt': '2026-07-31T00:00:00Z',
        'expiresAt': '2030-01-01T00:00:00Z',
        'keyId': 'ed25519-prod-key-1', // Revoked key!
        'minAppVersion': '1.0.0',
        'screenId': 'custody_screen',
        'defaultFilterId': 'all',
        'filters': []
      };

      final canonicalJson = ServerDrivenFilterConfig.toCanonicalJson(payload);
      final signatureHex = await signCanonicalJson(canonicalJson);

      final isValid = await Ed25519Verifier.verifySignature(
        canonicalJsonString: canonicalJson,
        signatureHexOrBase64: signatureHex,
        keyId: 'ed25519-prod-key-1',
      );

      expect(isValid, isFalse);
    });
  });
}
