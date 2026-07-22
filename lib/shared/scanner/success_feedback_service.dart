import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Fires EXACTLY ONCE per scan accept: local asset beep + haptic ~80–120 ms.
///
/// Idempotent — subsequent [fire] calls are no-ops until [reset]
/// (multi-scan unlock). Audio failure never blocks accept flow.
class SuccessFeedbackService {
  static const assetPath = 'sounds/scan_success.wav';
  static const hapticMs = 100;

  /// Set false in unit tests to avoid MissingPluginException from audioplayers.
  static bool audioEnabled = true;

  bool _fired = false;
  AudioPlayer? _player;

  bool get hasFired => _fired;

  /// Play beep + haptic. Idempotent — subsequent calls are no-ops.
  Future<void> fire() async {
    if (_fired) return;
    _fired = true;

    // Haptic window ~80–120 ms (spec).
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
    await Future<void>.delayed(const Duration(milliseconds: hapticMs));
    await _playBeep();
  }

  Future<void> _playBeep() async {
    if (!audioEnabled) return;
    try {
      _player ??= AudioPlayer();
      await _player!.play(AssetSource(assetPath), volume: 0.9);
    } catch (_) {
      // Best-effort: missing asset / plugin must never block accept.
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  /// Reset so the service can fire again (multi-scan next serial).
  void reset() {
    _fired = false;
    try {
      _player?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
  }
}
