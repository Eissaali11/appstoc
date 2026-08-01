/// Identifier normalization — trim / uppercase / newlines, plus SIM separators.
///
/// FORBIDDEN: strip alphabetic prefixes (NCD/NCC/SAW/SAS), digits-only collapse
/// of device serials, auto-prepend, GS1 header stripping that could alter
/// device identity. Prefixes are part of the opaque serial.
///
/// ALLOWED for numeric SIM ICCIDs only: strip spaces / dashes used in print
/// grouping (e.g. "8996 6060 9902 0514 950" → "8996606099020514950").
library;

class IdentifierNormalizationService {
  IdentifierNormalizationService._();

  /// Light normalize that never removes device-identity letter prefixes.
  /// Digit-only payloads (ICCID) also lose grouping spaces/dashes.
  static String normalize(String raw) {
    var s = raw
        .replaceAll('\r', '')
        .replaceAll('\n', '')
        .trim()
        .toUpperCase();

    // Extract serial number if embedded after S/N: or SN: or S/N
    // E.g., "A960-2AW-RL6-C0EE S/N:1180234360" → "1180234360"
    // "SN: SAS30810004647" → "SAS30810004647"
    final snMatch =
        RegExp(r'(?:S\/N|SN)[:\s]*([A-Z0-9]+)', caseSensitive: false)
            .firstMatch(s);
    if (snMatch != null && snMatch.group(1) != null) {
      final extracted = snMatch.group(1)!.trim();
      if (extracted.isNotEmpty) {
        s = extracted;
      }
    } else {
      // Strip common label prefixes like S/N: or SN: if at start
      if (s.startsWith('S/N:')) {
        s = s.substring(4).trim();
      } else if (s.startsWith('SN:')) {
        s = s.substring(3).trim();
      } else if (s.startsWith('S/N')) {
        s = s.substring(3).trim();
      }
    }

    // Numeric identity (ICCID/Serials): strip grouping spaces/dashes only.
    // Device serials with letter prefixes (NCD/NCC/SAW/SAS) stay intact.
    if (_isNumericIdentity(s)) {
      s = s.replaceAll(RegExp(r'[\s\u00A0\u2007\u202F\-]+'), '');
    }
    return s;
  }

  /// True when the payload is digits with optional spaces/dashes — no letters.
  static bool _isNumericIdentity(String s) {
    if (s.isEmpty) return false;
    return RegExp(r'^[0-9][0-9\s\u00A0\u2007\u202F\-]*$').hasMatch(s);
  }
}
