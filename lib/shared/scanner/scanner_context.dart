import '../models/item_type.dart';
import 'barcode_rule_registry.dart';

/// Immutable scan context for one camera session.
class ScannerContext {
  final String sessionId;
  final String? itemTypeId;
  final ItemType? itemType;
  final List<String> prefixes;
  final int? expectedLength;
  final RegExp? expectedRegex;
  final Set<String> existingValues;

  /// Primary rule when a single item type is selected.
  final BarcodeRule? trustedRule;

  /// All rules this session may accept (union of selected / allowed types).
  final List<BarcodeRule> trustedRules;

  final bool isMultiScan;

  /// When true and [trustedRules] empty, evaluate against enterprise fallbacks
  /// filtered by [categoryHint]. Prefer false (fail closed).
  final bool allowFallbackRegistry;

  /// Optional category filter for open fallback: `devices` | `sim`.
  final String? categoryHint;

  const ScannerContext({
    required this.sessionId,
    this.itemTypeId,
    this.itemType,
    this.prefixes = const [],
    this.expectedLength,
    this.expectedRegex,
    this.existingValues = const {},
    this.trustedRule,
    this.trustedRules = const [],
    this.isMultiScan = false,
    this.allowFallbackRegistry = false,
    this.categoryHint,
  });

  /// True when scanning is allowed (at least one trusted rule or open fallback).
  bool get hasTrustedRules =>
      trustedRules.isNotEmpty ||
      trustedRule != null ||
      allowFallbackRegistry;

  /// Rules used by the candidate selector (never empty when [hasTrustedRules]).
  List<BarcodeRule> get effectiveRules {
    if (trustedRules.isNotEmpty) return trustedRules;
    if (trustedRule != null) return [trustedRule!];
    if (!allowFallbackRegistry) return const [];
    final all = BarcodeRuleRegistry.fallbackRules;
    final hint = categoryHint?.toLowerCase();
    if (hint == 'devices' || hint == 'device' || hint == 'pos') {
      return all.where((r) => !r.id.startsWith('sim')).toList();
    }
    if (hint == 'sim' || hint == 'sim_card') {
      return all.where((r) => r.id.startsWith('sim')).toList();
    }
    return all;
  }

  factory ScannerContext.create({
    required String sessionId,
    ItemType? itemType,
    String? itemTypeId,
    Iterable<String>? existingValues,
    bool isMultiScan = false,
    /// When set, accept any serial matching rules derived from these types.
    List<ItemType>? allowedItemTypes,
    /// `devices` | `sim` — limits open fallback if no explicit type.
    String? categoryHint,
    /// If true and no type/rules resolve, allow enterprise fallback (filtered).
    /// Default false = fail closed.
    bool allowFallbackRegistry = false,
  }) {
    final id = (itemTypeId ?? itemType?.id)?.trim();
    final hasExplicitType =
        itemType != null || (id != null && id.isNotEmpty);

    final rule = BarcodeRuleRegistry.resolve(
      itemType: itemType,
      itemTypeId: id,
      hintName: itemType?.nameEn ?? itemType?.nameAr,
    );

    final allowedRules = <BarcodeRule>[];
    final seen = <String>{};
    if (rule != null && seen.add(rule.id)) {
      allowedRules.add(rule);
    }
    // Union of allowed types (e.g. all SIMs in category) merges with selected
    // rule so STC auto-select does not block Lebara/Zain 19-digit ICCIDs.
    if (allowedItemTypes != null && allowedItemTypes.isNotEmpty) {
      for (final t in allowedItemTypes) {
        final r = BarcodeRuleRegistry.resolve(
          itemType: t,
          itemTypeId: t.id,
          hintName: t.nameEn.isNotEmpty ? t.nameEn : t.nameAr,
        );
        if (r != null && seen.add(r.id)) allowedRules.add(r);
      }
    }

    // Explicit type that cannot be resolved → fail closed (empty rules).
    // Allowed types list that resolved → use those rules.
    // Otherwise only open if caller opted into fallback.
    final allowFallback = !hasExplicitType &&
        allowedRules.isEmpty &&
        allowFallbackRegistry;

    return ScannerContext(
      sessionId: sessionId,
      itemTypeId: id,
      itemType: itemType,
      prefixes: rule?.prefixes ??
          (allowedRules.isNotEmpty
              ? allowedRules.expand((r) => r.prefixes).toSet().toList()
              : const []),
      expectedLength: rule?.fullLength,
      expectedRegex: rule?.regex,
      existingValues: {
        for (final v in existingValues ?? const <String>[])
          v.trim().toUpperCase(),
      },
      trustedRule: rule,
      trustedRules: allowedRules,
      isMultiScan: isMultiScan,
      allowFallbackRegistry: allowFallback,
      categoryHint: categoryHint ?? itemType?.category,
    );
  }

  ScannerContext copyWith({
    ItemType? itemType,
    String? itemTypeId,
    Set<String>? existingValues,
    bool? isMultiScan,
    List<ItemType>? allowedItemTypes,
    String? categoryHint,
    bool? allowFallbackRegistry,
  }) {
    return ScannerContext.create(
      sessionId: sessionId,
      itemType: itemType ?? this.itemType,
      itemTypeId: itemTypeId ?? this.itemTypeId,
      existingValues: existingValues ?? this.existingValues,
      isMultiScan: isMultiScan ?? this.isMultiScan,
      allowedItemTypes: allowedItemTypes,
      categoryHint: categoryHint ?? this.categoryHint,
      allowFallbackRegistry:
          allowFallbackRegistry ?? this.allowFallbackRegistry,
    );
  }
}
