import 'dart:math' as math;
import 'dart:ui';

import 'identifier_normalization_service.dart';
import 'scanner_context.dart';
import 'barcode_rule_registry.dart';

/// Outcome of evaluating all barcodes in a single camera frame.
enum CandidateStatus {
  /// Exactly one distinct valid serial found — ready to accept (after stability).
  singleMatch,

  /// Two or more different valid serials appear in the same frame.
  /// Refuse to pick one randomly; wait / ask user to center one serial.
  ambiguous,

  /// No valid serial matched the current item-type rules.
  noMatch,

  /// Valid match found but not yet stable / not preferred in ROI.
  unstable,
}

class BarcodeObservation {
  final String raw;
  final Offset? center;
  final double? confidence;

  const BarcodeObservation({
    required this.raw,
    this.center,
    this.confidence,
  });
}

class CandidateResult {
  final String? selected;
  final CandidateStatus status;
  final double score;
  final String? guidanceMessage;

  const CandidateResult({
    required this.selected,
    required this.status,
    this.score = 0,
    this.guidanceMessage,
  });
}

/// Evaluates EVERY barcode in a frame against [ScannerContext] and scores by:
/// match + ROI-center proximity + confidence. Never picks randomly among
/// multiple valid matches.
class BarcodeCandidateSelector {
  BarcodeCandidateSelector({
    this.roiCenter = const Offset(0.5, 0.5),
    this.roiHalfWidth = 0.40,
    this.roiHalfHeight = 0.18,
    this.highConfidenceThreshold = 0.85,
  });

  /// Normalized image coords (0..1) for ROI center.
  final Offset roiCenter;
  final double roiHalfWidth;
  final double roiHalfHeight;
  final double highConfidenceThreshold;

  String? _lastStableValue;
  int _consecutiveIdentical = 0;

  static const ambiguousGuidance =
      'ضع الرقم التسلسلي داخل الإطار';

  /// Reset stability counters (e.g. after item-type change).
  void resetStability() {
    _lastStableValue = null;
    _consecutiveIdentical = 0;
  }

  CandidateResult select(
    List<BarcodeObservation> observations, {
    required ScannerContext context,
  }) {
    final rules = context.effectiveRules;
    if (rules.isEmpty) {
      resetStability();
      return const CandidateResult(
        selected: null,
        status: CandidateStatus.noMatch,
        guidanceMessage: null,
      );
    }

    final scored = <_Scored>[];

    for (final obs in observations) {
      if (obs.raw.trim().isEmpty) continue;
      final normalized = IdentifierNormalizationService.normalize(obs.raw);
      if (normalized.isEmpty) continue;
      if (!rules.any((r) => r.matches(normalized))) continue;

      final inRoi = _isInsideRoi(obs.center);
      final dist = _distanceToRoiCenter(obs.center);
      final conf = obs.confidence ?? 0.5;
      // Prefer ROI: match base + ROI bonus + center proximity + confidence.
      final score = 1.0 +
          (inRoi ? 2.0 : 0.0) +
          (1.0 - dist.clamp(0.0, 1.0)) +
          conf;

      scored.add(_Scored(
        value: normalized,
        score: score,
        inRoi: inRoi,
        confidence: conf,
      ));
    }

    if (scored.isEmpty) {
      resetStability();
      return const CandidateResult(
        selected: null,
        status: CandidateStatus.noMatch,
      );
    }

    final distinct = <String>{for (final s in scored) s.value};
    if (distinct.length > 1) {
      resetStability();
      return const CandidateResult(
        selected: null,
        status: CandidateStatus.ambiguous,
        guidanceMessage: ambiguousGuidance,
      );
    }

    // Prefer the highest-scoring observation of the single valid serial.
    scored.sort((a, b) => b.score.compareTo(a.score));
    final best = scored.first;

    // Prefer ROI — if we only see the serial outside ROI and confidence is
    // low, ask user to center it (still do not accept randomly).
    final anyInRoi = scored.any((s) => s.inRoi);
    if (!anyInRoi && best.confidence < highConfidenceThreshold) {
      return CandidateResult(
        selected: null,
        status: CandidateStatus.unstable,
        score: best.score,
        guidanceMessage: ambiguousGuidance,
      );
    }

    return _applyStability(best);
  }

  /// Convenience for raw string lists (unit tests / no geometry).
  CandidateResult selectRaw(
    List<String> rawValues, {
    required ScannerContext context,
    double confidence = 1.0,
  }) {
    return select(
      [
        for (final r in rawValues)
          BarcodeObservation(raw: r, center: roiCenter, confidence: confidence),
      ],
      context: context,
    );
  }

  CandidateResult _applyStability(_Scored best) {
    final highConf = best.confidence >= highConfidenceThreshold;
    if (_lastStableValue == best.value) {
      _consecutiveIdentical += 1;
    } else {
      _lastStableValue = best.value;
      _consecutiveIdentical = 1;
    }

    // Accept: high confidence once OR two consecutive identical frames.
    if (highConf || _consecutiveIdentical >= 2) {
      return CandidateResult(
        selected: best.value,
        status: CandidateStatus.singleMatch,
        score: best.score,
      );
    }

    return CandidateResult(
      selected: null,
      status: CandidateStatus.unstable,
      score: best.score,
      guidanceMessage: ambiguousGuidance,
    );
  }

  bool _isInsideRoi(Offset? center) {
    if (center == null) return true; // no geometry → treat as inside for scoring
    final dx = (center.dx - roiCenter.dx).abs();
    final dy = (center.dy - roiCenter.dy).abs();
    return dx <= roiHalfWidth && dy <= roiHalfHeight;
  }

  double _distanceToRoiCenter(Offset? center) {
    if (center == null) return 0;
    final dx = center.dx - roiCenter.dx;
    final dy = center.dy - roiCenter.dy;
    return math.sqrt(dx * dx + dy * dy);
  }
}

class _Scored {
  final String value;
  final double score;
  final bool inRoi;
  final double confidence;

  const _Scored({
    required this.value,
    required this.score,
    required this.inRoi,
    required this.confidence,
  });
}

/// Legacy static helper kept for older call sites.
class BarcodeCandidateSelectorLegacy {
  BarcodeCandidateSelectorLegacy._();

  static CandidateResult select(
    List<String> rawValues, {
    BarcodeRule? rule,
    ScannerContext? context,
  }) {
    final ctx = context ??
        (rule == null
            ? null
            : ScannerContext(
                sessionId: 'legacy',
                trustedRule: rule,
                prefixes: rule.prefixes,
                expectedLength: rule.fullLength,
                expectedRegex: rule.regex,
              ));
    if (ctx == null) {
      return const CandidateResult(
        selected: null,
        status: CandidateStatus.noMatch,
      );
    }
    return BarcodeCandidateSelector().selectRaw(rawValues, context: ctx);
  }
}
