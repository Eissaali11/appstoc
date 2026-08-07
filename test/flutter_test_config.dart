// PHASE B1.4 — process-wide test config, auto-loaded by `flutter test` for
// every file in this `test/` tree (special file name recognized by the
// Flutter test runner — no explicit import needed anywhere else).
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // login_page.dart (and others) use GoogleFonts, which otherwise attempts a
  // real network fetch for font assets — forbidden in this offline test
  // suite and a source of test-runner hangs/flakiness in CI.
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
