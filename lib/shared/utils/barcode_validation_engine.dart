/// Enterprise Barcode Validation Engine V2 — context-aware opaque serial policy.
///
/// Allowed normalize: trim, uppercase, strip newlines; for numeric SIM ICCIDs
/// also strip grouping spaces/dashes (via [IdentifierNormalizationService]).
/// FORBIDDEN: strip alphabetic prefix, digits-only of device serials, auto-prepend NCD/NCC.
///
/// Fail closed when [ScannerContext] has no trusted rule.
library;

import '../scanner/barcode_rule_registry.dart';
import '../scanner/identifier_normalization_service.dart';
import '../scanner/scanner_context.dart';

export '../scanner/barcode_rule_registry.dart' show BarcodeRule;

class BarcodeValidationResult {
  final bool isValid;
  final String normalized;
  final BarcodeRule? matchedRule;
  final String? errorCode;

  const BarcodeValidationResult({
    required this.isValid,
    required this.normalized,
    this.matchedRule,
    this.errorCode,
  });
}

/// Central validation — no validation logic belongs in UI widgets.
class BarcodeValidationEngine {
  BarcodeValidationEngine._();

  /// Light normalize — never strips device identity prefixes.
  static String normalize(String raw) =>
      IdentifierNormalizationService.normalize(raw);

  /// Validate [raw] against [context] trusted rule (preferred) or fallback
  /// registry lookup when no context is supplied.
  static BarcodeValidationResult validate(
    String raw, {
    ScannerContext? context,
    String? hintRuleId,
  }) {
    final normalized = normalize(raw);
    if (normalized.isEmpty) {
      return const BarcodeValidationResult(
        isValid: false,
        normalized: '',
        errorCode: 'empty',
      );
    }

    // Context-aware path — evaluate effective rules only (fail closed if empty).
    if (context != null) {
      final rules = context.effectiveRules;
      if (rules.isEmpty) {
        return BarcodeValidationResult(
          isValid: false,
          normalized: normalized,
          errorCode: 'no_trusted_rule',
        );
      }
      for (final rule in rules) {
        if (rule.matches(normalized)) {
          return BarcodeValidationResult(
            isValid: true,
            normalized: normalized,
            matchedRule: rule,
          );
        }
      }
      return BarcodeValidationResult(
        isValid: false,
        normalized: normalized,
        errorCode: 'no_match',
      );
    }

    // No context: try hint / all fallbacks (manual entry / legacy callers).
    final ordered = <BarcodeRule>[
      if (hintRuleId != null)
        ...BarcodeRuleRegistry.fallbackRules
            .where((r) => r.id == hintRuleId.toLowerCase()),
      ...BarcodeRuleRegistry.fallbackRules.where(
        (r) => hintRuleId == null || r.id != hintRuleId.toLowerCase(),
      ),
    ];

    for (final rule in ordered) {
      if (rule.matches(normalized)) {
        return BarcodeValidationResult(
          isValid: true,
          normalized: normalized,
          matchedRule: rule,
        );
      }
    }

    return BarcodeValidationResult(
      isValid: false,
      normalized: normalized,
      errorCode: 'no_match',
    );
  }

  static bool isValid(
    String raw, {
    ScannerContext? context,
    String? hintRuleId,
  }) =>
      validate(raw, context: context, hintRuleId: hintRuleId).isValid;
}
