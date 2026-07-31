import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';

class Ed25519Verifier {
  // Active Production Key ID (ed25519-prod-key-1 is revoked)
  static const String defaultKeyId = 'ed25519-prod-key-2';

  // Active Production Pinned Ed25519 Public Key (32 bytes Hex)
  static const String productionPublicKeyHex =
      '726b603b12789822a3131cdac6ea3cae7f3fff7232d026799440c24e2818b77b';

  static const Map<String, String> _pinnedPublicKeys = {
    'ed25519-prod-key-2': productionPublicKeyHex,
  };

  /// Verifies an Ed25519 signature over canonical JSON message bytes.
  /// In Release builds (kReleaseMode == true), customPublicKeyHex is disabled
  /// and only active pinned production keyId ("ed25519-prod-key-2") is allowed.
  static Future<bool> verifySignature({
    required String canonicalJsonString,
    required String signatureHexOrBase64,
    required String keyId,
    String? customPublicKeyHex,
  }) async {
    try {
      final String? publicKeyHex;
      if (kReleaseMode) {
        if (keyId != defaultKeyId) {
          return false; // Reject any revoked/unknown keyId in release
        }
        publicKeyHex = _pinnedPublicKeys[keyId];
      } else {
        // Debug / Test mode: allow custom key hex override if provided
        publicKeyHex = customPublicKeyHex ?? _pinnedPublicKeys[keyId];
      }

      if (publicKeyHex == null || publicKeyHex.isEmpty) {
        return false;
      }

      final messageBytes = utf8.encode(canonicalJsonString);
      final publicKeyBytes = _decodeHexOrBase64(publicKeyHex);
      final signatureBytes = _decodeHexOrBase64(signatureHexOrBase64);

      if (publicKeyBytes.length != 32 || signatureBytes.length != 64) {
        return false;
      }

      final algorithm = Ed25519();
      final signature = Signature(
        signatureBytes,
        publicKey: SimplePublicKey(
          publicKeyBytes,
          type: KeyPairType.ed25519,
        ),
      );

      return await algorithm.verify(
        messageBytes,
        signature: signature,
      );
    } catch (_) {
      return false;
    }
  }

  static List<int> _decodeHexOrBase64(String input) {
    final clean = input.trim();
    if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(clean) && clean.length % 2 == 0) {
      final List<int> result = [];
      for (int i = 0; i < clean.length; i += 2) {
        result.add(int.parse(clean.substring(i, i + 2), radix: 16));
      }
      return result;
    }
    return base64Decode(clean);
  }
}
