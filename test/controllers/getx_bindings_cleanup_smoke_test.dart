// PHASE B1.4 — Flutter Test Foundation smoke test: GetX bindings are
// actually cleaned between tests (B1.4.4 item 13) — the harness's core
// cross-test-isolation guarantee, verified directly rather than assumed.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nuolipapp/core/storage/offline_queue_manager.dart';
import '../helpers/mocks.dart';
import '../helpers/test_harness.dart';

void main() {
  setUpAll(registerFoundationFallbackValues);

  MockOfflineQueueRepository buildRepository() {
    final repository = MockOfflineQueueRepository();
    when(() => repository.getPendingCount()).thenAnswer((_) async => 0);
    return repository;
  }

  test("resetGetXState() removes a previously-registered controller", () async {
    Get.put<OfflineQueueController>(OfflineQueueController(repository: buildRepository()));

    expect(Get.isRegistered<OfflineQueueController>(), isTrue);

    await resetGetXState();

    expect(Get.isRegistered<OfflineQueueController>(), isFalse);
  });

  test("no singleton state leaks across two independent test bodies", () async {
    // Test A's registration.
    Get.put<OfflineQueueController>(OfflineQueueController(repository: buildRepository()));
    await resetGetXState();

    // Test B (simulated within the same test body) must start from a clean
    // slate — Get.find must fail, not silently return test A's instance.
    expect(() => Get.find<OfflineQueueController>(), throwsA(anything));
  });
}
