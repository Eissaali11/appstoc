/// Tracks accepted / form-existing serials and rate-limits the duplicate toast.
///
/// All methods are synchronous — safe from the Dart event loop without locks.
class DuplicateScannerGuard {
  final Set<String> _accepted = {};
  final Set<String> _existing = {};
  DateTime? _lastToastAt;

  static const toastCooldown = Duration(milliseconds: 2000);
  static const duplicateMessage = 'تمت إضافة هذا الرقم مسبقًا.';

  void seedExisting(Iterable<String> values) {
    _existing
      ..clear()
      ..addAll(values.map((v) => v.trim().toUpperCase()).where((v) => v.isNotEmpty));
  }

  /// True if [serial] was already accepted in this session or exists in the form.
  bool isDuplicate(String serial) {
    final key = serial.trim().toUpperCase();
    return _accepted.contains(key) || _existing.contains(key);
  }

  /// Record [serial] as accepted so future frames detect it as a duplicate.
  void markAccepted(String serial) => _accepted.add(serial.trim().toUpperCase());

  /// Returns [true] and records the timestamp if enough time has passed since
  /// the last toast (2-second cooldown). Call before showing SnackBar.
  bool shouldShowToast() {
    final now = DateTime.now();
    if (_lastToastAt == null ||
        now.difference(_lastToastAt!) >= toastCooldown) {
      _lastToastAt = now;
      return true;
    }
    return false;
  }

  int get count => _accepted.length;

  Set<String> get accepted => Set.unmodifiable(_accepted);

  void remove(String serial) => _accepted.remove(serial.trim().toUpperCase());

  void clear() {
    _accepted.clear();
    _lastToastAt = null;
  }
}
