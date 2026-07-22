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

    // Numeric identity (ICCID): strip grouping spaces/dashes only.
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
