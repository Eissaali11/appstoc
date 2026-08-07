// PHASE B1.4 — Flutter Test Foundation smoke test: Scanner abstraction.
//
// There is no single "ScannerService" class in this codebase to mock — the
// scanner subsystem (BarcodeCandidateSelector, ScannerSessionManager,
// DuplicateScannerGuard, BarcodeValidationEngine) is already camera-agnostic
// by design, operating purely on barcode STRINGS. See
// test/scanner/scanner_pipeline_test.dart (pre-existing, not modified by
// this phase) for the detailed device-format validation matrix; this file
// only proves the session/dedupe state machine accepts a fake scanned
// barcode end-to-end without any Camera/hardware dependency, as a
// foundation-level smoke, not a re-test of that existing coverage.
import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/shared/scanner/scanner_session_manager.dart';
import 'package:nuolipapp/shared/scanner/duplicate_scanner_guard.dart';
import '../helpers/fakes.dart';

void main() {
  test("scanner session accepts a fake scanned barcode with zero camera/hardware dependency", () {
    final session = ScannerSessionManager();
    final guard = DuplicateScannerGuard();
    final fakeBarcode = createFakeScannedBarcode();

    session.markScanning();
    expect(session.tryLock(), isTrue, reason: "first scan in a fresh session must acquire the lock");
    expect(guard.isDuplicate(fakeBarcode), isFalse);

    session.accept(fakeBarcode);
    guard.markAccepted(fakeBarcode);

    expect(session.state, ScannerState.accepted);
    expect(session.acceptedValue, fakeBarcode);
    expect(guard.isDuplicate(fakeBarcode), isTrue, reason: "same barcode scanned again must now be flagged");
  });

  test("scanner session lock prevents a concurrent duplicate accept within the same session", () {
    final session = ScannerSessionManager();
    session.markScanning();

    expect(session.tryLock(), isTrue);
    // A second concurrent capture callback (e.g. two camera frames racing)
    // must not be able to acquire the lock again before resetForNextScan().
    expect(session.tryLock(), isFalse);
  });
}
