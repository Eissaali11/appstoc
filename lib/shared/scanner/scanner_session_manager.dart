/// State machine for a single barcode scan session.
///
/// The lock flag is set ATOMICALLY (synchronously) before any async gap so that
/// concurrent [BarcodeCapture] callbacks cannot race through the validation
/// pipeline and produce duplicate accepts / beeps.
///
/// Lifecycle — single-scan:
///   IDLE → SCANNING → VALIDATING → ACCEPTED → CLOSED
///
/// Lifecycle — multi-scan (resets between each serial):
///   IDLE → SCANNING → VALIDATING → ACCEPTED → IDLE (reset) → ...
library;

enum ScannerState { idle, scanning, validating, accepted, closed }

class ScannerSessionManager {
  ScannerState _state = ScannerState.idle;
  bool _locked = false;
  String? _acceptedValue;
  int _successCount = 0;

  ScannerState get state => _state;

  bool get isLocked => _locked;

  String? get acceptedValue => _acceptedValue;

  int get successCount => _successCount;

  /// True while the session can still accept a new barcode.
  bool get isOpen =>
      _state != ScannerState.accepted && _state != ScannerState.closed;

  void markScanning() {
    if (_state == ScannerState.idle) {
      _state = ScannerState.scanning;
    }
  }

  /// Attempt to acquire the processing lock synchronously.
  ///
  /// Returns [true] iff the lock was free and is now held by the caller.
  /// MUST be called BEFORE any [await] after a valid accept decision.
  bool tryLock() {
    if (_locked) return false;
    if (_state == ScannerState.accepted || _state == ScannerState.closed) {
      return false;
    }
    _locked = true;
    _state = ScannerState.validating;
    return true;
  }

  /// Commit a successful accept. Call only after [tryLock] returned true.
  /// Sets ACCEPTED synchronously — safe before any await (beep/haptic/nav).
  void accept(String value) {
    _acceptedValue = value;
    _successCount += 1;
    _state = ScannerState.accepted;
    _locked = true;
  }

  void unlock() {
    if (_state == ScannerState.accepted || _state == ScannerState.closed) {
      return;
    }
    _locked = false;
  }

  void transition(ScannerState next) {
    _state = next;
  }

  /// Full reset for multi-scan: unlock + return to IDLE.
  void resetForNextScan() {
    _state = ScannerState.idle;
    _locked = false;
    _acceptedValue = null;
  }

  /// Terminal close — session cannot accept further barcodes.
  void close() {
    _state = ScannerState.closed;
    _locked = true;
  }
}
