import '../models/item_type.dart';

/// Trusted serial rule for a single item type.
class BarcodeRule {
  final String id;
  final String label;
  final List<String> prefixes;

  /// Exact total length, when the type has exactly one valid length.
  /// Null means "the regex alone is the length contract" — used when the
  /// live catalog's own serial_regex legitimately spans more than one
  /// length (e.g. a shared SIM ICCID pattern across several carriers) and
  /// no single length would be correct to enforce ahead of the regex.
  final int? fullLength;
  final RegExp regex;
  final bool requiresContext;

  const BarcodeRule({
    required this.id,
    required this.label,
    required this.prefixes,
    required this.fullLength,
    required this.regex,
    this.requiresContext = false,
  });

  bool matches(String normalized) {
    if (fullLength != null && normalized.length != fullLength) return false;
    if (prefixes.isNotEmpty && !prefixes.any(normalized.startsWith)) return false;
    return regex.hasMatch(normalized);
  }
}

/// Central rule registry. Prefer API/cache [ItemType] config; fallback must
/// match the enterprise table. Unknown types → fail closed (null rule).
class BarcodeRuleRegistry {
  BarcodeRuleRegistry._();

  /// Built-in enterprise fallbacks (exact table).
  static final List<BarcodeRule> fallbackRules = [
    BarcodeRule(
      id: 'n950',
      label: 'Newland N950',
      prefixes: const ['NCD', 'NCC'],
      fullLength: 12,
      regex: RegExp(r'^(NCD|NCC)[0-9]{9}$'),
    ),
    BarcodeRule(
      id: 'i9100',
      label: 'Urovo i9100',
      prefixes: const ['SAW'],
      fullLength: 11,
      regex: RegExp(r'^SAW[0-9]{8}$'),
    ),
    BarcodeRule(
      id: 'i9000s',
      label: 'Urovo i9000S',
      prefixes: const ['SAS'],
      fullLength: 11,
      regex: RegExp(r'^SAS[0-9]{8}$'),
    ),
    BarcodeRule(
      id: 'a960',
      label: 'PAX A960',
      prefixes: const [],
      fullLength: 10,
      regex: RegExp(r'^[0-9]{10}$'),
      requiresContext: true,
    ),
    BarcodeRule(
      id: 'sim_89966_19',
      label: 'SIM Zain/Mobily/Lebara/Repara',
      prefixes: const ['89966'],
      fullLength: 19,
      regex: RegExp(r'^89966[0-9]{14}$'),
    ),
    BarcodeRule(
      id: 'sim_stc',
      label: 'SIM STC',
      prefixes: const ['89966'],
      fullLength: 18,
      regex: RegExp(r'^89966[0-9]{13}$'),
    ),
  ];

  static final Map<String, BarcodeRule> _cache = {};

  static void cacheFromItemTypes(Iterable<ItemType> types) {
    for (final t in types) {
      final rule = fromItemType(t);
      if (rule != null) _cache[t.id.toLowerCase()] = rule;
    }
  }

  static void clearCache() => _cache.clear();

  /// Resolve a trusted rule for [itemType] / [itemTypeId].
  /// Returns null → fail closed (do not accept any barcode).
  static BarcodeRule? resolve({
    ItemType? itemType,
    String? itemTypeId,
    String? hintName,
  }) {
    if (itemType != null) {
      final fromApi = fromItemType(itemType);
      if (fromApi != null) return fromApi;
    }

    final key = (itemTypeId ?? itemType?.id ?? '').trim().toLowerCase();
    if (key.isNotEmpty) {
      final cached = _cache[key];
      if (cached != null) return cached;
      final byId = _matchFallbackByIdOrName(key);
      if (byId != null) return byId;
    }

    final name = (hintName ?? itemType?.nameEn ?? itemType?.nameAr ?? '')
        .trim()
        .toLowerCase();
    if (name.isNotEmpty) {
      final byName = _matchFallbackByIdOrName(name);
      if (byName != null) return byName;
    }

    return null;
  }

  /// Build a rule from API/cache ItemType when config is trustworthy.
  ///
  /// Known enterprise types (N950 / i9100 / i9000S / SIMs) ALWAYS use the
  /// trusted table — same digit-only quality as N950 — even when API sends a
  /// looser regex. Custom/unknown types use API fields; incomplete API rows
  /// fail closed (null) rather than inventing a loose rule.
  static BarcodeRule? fromItemType(ItemType itemType) {
    // Prefer enterprise table for known types (exact prefix+length+regex).
    final enterprise = _matchFallbackByIdOrName(itemType.id) ??
        _matchFallbackByIdOrName(itemType.nameEn) ??
        _matchFallbackByIdOrName(itemType.nameAr);
    if (enterprise != null) {
      // Preserve caller itemType.id so UUID-backed API rows still key correctly
      // while enforcing enterprise constraints.
      return BarcodeRule(
        id: itemType.id,
        label: itemType.nameEn.isNotEmpty
            ? itemType.nameEn
            : (itemType.nameAr.isNotEmpty ? itemType.nameAr : enterprise.label),
        prefixes: enterprise.prefixes,
        fullLength: enterprise.fullLength,
        regex: enterprise.regex,
        requiresContext: enterprise.requiresContext,
      );
    }

    final prefixes = (itemType.serialPrefix ?? '')
        .split(',')
        .map((p) => p.trim().toUpperCase())
        .where((p) => p.isNotEmpty)
        .toList();
    final length = itemType.serialLength;
    final regexRaw = itemType.serialRegex?.trim();

    if (prefixes.isEmpty || regexRaw == null || regexRaw.isEmpty) {
      return null;
    }

    RegExp regex;
    try {
      regex = RegExp(regexRaw);
    } catch (_) {
      return null;
    }

    // No single catalog length (e.g. a SIM ICCID regex spanning more than
    // one real length, shared verbatim across several carrier item types —
    // STC/Mobily/Zain currently all store `^89966[0-9]{13,14}$`). Trust the
    // regex alone rather than inventing a length split the catalog itself
    // doesn't encode: if that leaves the same code validating against more
    // than one candidate type, that is a real, correctly-surfaced ambiguity
    // for the caller (SimCarrierResolver) to ask the user about — not
    // something this layer should silently resolve or silently refuse.
    if (length == null || length <= 0) {
      return BarcodeRule(
        id: itemType.id,
        label: itemType.nameEn.isNotEmpty ? itemType.nameEn : itemType.nameAr,
        prefixes: prefixes,
        fullLength: null,
        regex: regex,
      );
    }

    // Normalize body-length configs (legacy serial_length=9 + alpha prefix)
    // to full opaque length when regex requires the full string.
    var fullLength = length;
    final alphaPrefixes =
        prefixes.where((p) => RegExp(r'^[A-Z]+$').hasMatch(p)).toList();
    if (alphaPrefixes.isNotEmpty) {
      final sample = alphaPrefixes.first;
      if (length <= 9 && !regex.hasMatch('${sample}${'0' * length}')) {
        final candidate = sample.length + length;
        final probe = '$sample${'0' * length}';
        if (probe.length == candidate && regex.hasMatch(probe)) {
          fullLength = candidate;
        }
      }
    }

    return BarcodeRule(
      id: itemType.id,
      label: itemType.nameEn.isNotEmpty ? itemType.nameEn : itemType.nameAr,
      prefixes: prefixes,
      fullLength: fullLength,
      regex: regex,
    );
  }

  static BarcodeRule? _matchFallbackByIdOrName(String raw) {
    final key = raw.trim().toLowerCase().replaceAll(' ', '');
    if (key.isEmpty) return null;

    for (final rule in fallbackRules) {
      if (rule.id == key) return rule;
    }

    if (key.contains('n950') || key == 'newland') {
      return fallbackRules.firstWhere((r) => r.id == 'n950');
    }
    // i9100 before i9000 — avoid accidental 9000 substring hits on 9100 ids.
    if (key.contains('i9100') ||
        key.contains('urovoi9100') ||
        (key.contains('9100') && !key.contains('9000'))) {
      return fallbackRules.firstWhere((r) => r.id == 'i9100');
    }
    if (key.contains('i9000') ||
        key.contains('9000s') ||
        key.contains('urovoi9000') ||
        (key.contains('9000') && !key.contains('9100'))) {
      return fallbackRules.firstWhere((r) => r.id == 'i9000s');
    }
    if (key.contains('a960') || key.contains('pax') || key.contains('paxa960')) {
      return fallbackRules.firstWhere((r) => r.id == 'a960');
    }
    // STC/Zain/Mobily/Lebara/Repara are deliberately NOT keyword-matched to
    // the enterprise table here. That used to force a hardcoded 18-vs-19-
    // digit length split onto these names regardless of what the live
    // catalog's own serial_regex actually says — a guess this app has no
    // real ground truth for, since production currently stores the SAME
    // regex (`^89966[0-9]{13,14}$`) for stc/mobily/zain(old) alike. Letting
    // `fromItemType()` fall through to each type's own live regex/prefix is
    // the only data-honest option: a single reliable catalog match still
    // auto-resolves normally, and a genuine multi-type match is correctly
    // surfaced as ambiguous by SimCarrierResolver, never silently guessed
    // here. See item_type_classification_batch_test.dart for the proof.
    return null;
  }
}
