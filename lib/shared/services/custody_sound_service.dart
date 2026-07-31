import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Sound and Haptic feedback service for Technician Custody Lookup.
class CustodySoundService {
  CustodySoundService._();

  static AudioPlayer? _player;

  /// Plays a success bell + heavy haptic vibration when the item IS in custody.
  static Future<void> playSuccessBell() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}

    try {
      _player ??= AudioPlayer();
      await _player!.stop();
      await _player!.play(AssetSource('sounds/scan_success.wav'), volume: 1.0);
    } catch (_) {
      try {
        await SystemSound.play(SystemSoundType.click);
      } catch (_) {}
    }
  }

  /// Plays a warning alert + double vibration when the item IS NOT in custody.
  static Future<void> playWarningBell() async {
    try {
      await HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.vibrate();
    } catch (_) {}

    try {
      await SystemSound.play(SystemSoundType.alert);
    } catch (_) {}
  }
}
