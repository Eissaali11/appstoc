import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/server_driven_filter_config.dart';
import '../security/ed25519_verifier.dart';

class SduiFilterRepository {
  final Dio dio;
  final FlutterSecureStorage storage;

  static const String cachePayloadKey = 'sdui_filter_config_payload';
  static const String cacheSignatureKey = 'sdui_filter_config_signature';
  static const String cacheEtagKey = 'sdui_filter_config_etag';
  static const String currentAppVersion = '1.0.0';

  SduiFilterRepository({
    Dio? dio,
    FlutterSecureStorage? storage,
  })  : dio = dio ?? Dio(),
        storage = storage ?? const FlutterSecureStorage();

  /// Hardcoded fallback configuration if network and cache fail.
  static final ServerDrivenFilterConfig fallbackConfig = ServerDrivenFilterConfig(
    schemaVersion: 1,
    configVersion: 1,
    issuedAt: '2026-07-31T00:00:00Z',
    expiresAt: '2030-01-01T00:00:00Z',
    keyId: 'ed25519-prod-key-1',
    minAppVersion: '1.0.0',
    screenId: 'custody_screen',
    defaultFilterId: 'all',
    filters: const [
      FilterItemDefinition(
        id: 'all',
        label: 'الكل',
        enabled: true,
        order: 1,
        icon: 'inventory_2_outlined',
        colorHex: '#18B2B0',
        statuses: [],
      ),
      FilterItemDefinition(
        id: 'under_action',
        label: 'تحت الإجراء',
        enabled: true,
        order: 2,
        icon: 'pending_actions_rounded',
        colorHex: '#FFB300',
        statuses: ['UNDER_ACTION', 'PROCESSING'],
      ),
      FilterItemDefinition(
        id: 'delivered',
        label: 'المسلمة',
        enabled: true,
        order: 3,
        icon: 'check_circle_outline',
        colorHex: '#00C853',
        statuses: ['DELIVERED'],
      ),
    ],
  );

  /// Main method: Fetches config from API or fallback cache.
  Future<ServerDrivenFilterConfig> getFilterConfig({
    required String endpointUrl,
    String? customPublicKeyHex,
  }) async {
    final cachedEtag = await storage.read(key: cacheEtagKey);
    final cachedConfig = await getValidCachedConfig(customPublicKeyHex: customPublicKeyHex);

    try {
      final headers = <String, String>{};
      if (cachedEtag != null) {
        headers['If-None-Match'] = cachedEtag;
      }

      final response = await dio.get(
        endpointUrl,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 304) {
        if (cachedConfig != null) {
          return cachedConfig;
        }
      } else if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;

        final payload = body['data'] as Map<String, dynamic>?;
        final signatureHex = body['signature'] as String?;

        if (payload != null && signatureHex != null) {
          if (!ServerDrivenFilterConfig.validateRuntimeSchema(payload)) {
            return cachedConfig ?? fallbackConfig;
          }

          final canonicalJson = ServerDrivenFilterConfig.toCanonicalJson(payload);
          final keyId = payload['keyId'] as String? ?? '';

          final isSignatureValid = await Ed25519Verifier.verifySignature(
            canonicalJsonString: canonicalJson,
            signatureHexOrBase64: signatureHex,
            keyId: keyId,
            customPublicKeyHex: customPublicKeyHex,
          );

          if (isSignatureValid) {
            final newConfig = ServerDrivenFilterConfig.fromJson(payload);

            // Version & Content Guard (4 Cases):
            if (cachedConfig != null) {
              if (newConfig.configVersion < cachedConfig.configVersion) {
                // Case A: Rollback attempt (lower version) -> reject
                return cachedConfig;
              } else if (newConfig.configVersion == cachedConfig.configVersion) {
                final cachedPayloadJson = await storage.read(key: cachePayloadKey);
                if (cachedPayloadJson != null) {
                  final cachedPayloadMap = jsonDecode(cachedPayloadJson) as Map<String, dynamic>;
                  final cachedCanonical = ServerDrivenFilterConfig.toCanonicalJson(cachedPayloadMap);
                  if (canonicalJson != cachedCanonical) {
                    // Case C: Same version BUT different payload -> Conflict / Tamper reject!
                    return cachedConfig;
                  }
                }
                // Case B: Same version AND same payload -> Accept (cached/unchanged)
              }
              // Case D: newConfig.configVersion > cachedConfig.configVersion -> Accept
            }

            // Expiry Guard
            if (newConfig.isExpired()) {
              return cachedConfig ?? fallbackConfig;
            }

            // Min App Version Guard
            if (isVersionBelowMin(currentAppVersion, newConfig.minAppVersion)) {
              return cachedConfig ?? fallbackConfig;
            }

            // Save payload + signature + etag atomically in cache
            final newEtag = response.headers.value('etag');
            await _saveToCache(
              payloadJson: jsonEncode(payload),
              signatureHex: signatureHex,
              etag: newEtag,
            );

            return newConfig;
          }
        }
      }
    } catch (_) {
      // Network error or unexpected exception: Fallback to cache / hardcoded
    }

    return cachedConfig ?? fallbackConfig;
  }

  /// Reads from local storage and re-verifies Ed25519 signature.
  Future<ServerDrivenFilterConfig?> getValidCachedConfig({
    String? customPublicKeyHex,
  }) async {
    try {
      final cachedPayloadJson = await storage.read(key: cachePayloadKey);
      final cachedSignature = await storage.read(key: cacheSignatureKey);

      if (cachedPayloadJson == null || cachedSignature == null) {
        return null;
      }

      final Map<String, dynamic> payload = jsonDecode(cachedPayloadJson);
      if (!ServerDrivenFilterConfig.validateRuntimeSchema(payload)) {
        return null;
      }

      final canonicalJson = ServerDrivenFilterConfig.toCanonicalJson(payload);
      final keyId = payload['keyId'] as String? ?? 'ed25519-prod-key-1';

      final isSignatureValid = await Ed25519Verifier.verifySignature(
        canonicalJsonString: canonicalJson,
        signatureHexOrBase64: cachedSignature,
        keyId: keyId,
        customPublicKeyHex: customPublicKeyHex,
      );

      if (!isSignatureValid) {
        return null;
      }

      final config = ServerDrivenFilterConfig.fromJson(payload);

      if (config.isExpired()) {
        return null;
      }

      if (isVersionBelowMin(currentAppVersion, config.minAppVersion)) {
        return null;
      }

      return config;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveToCache({
    required String payloadJson,
    required String signatureHex,
    String? etag,
  }) async {
    await storage.write(key: cachePayloadKey, value: payloadJson);
    await storage.write(key: cacheSignatureKey, value: signatureHex);
    if (etag != null) {
      await storage.write(key: cacheEtagKey, value: etag);
    }
  }

  static bool isVersionBelowMin(String current, String minRequired) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final minParts = minRequired.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final c = i < currentParts.length ? currentParts[i] : 0;
        final m = i < minParts.length ? minParts[i] : 0;
        if (c < m) return true;
        if (c > m) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
