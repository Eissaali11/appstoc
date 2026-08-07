// PHASE B1.4 — Flutter Test Foundation smoke test: offline state.
// See fakes.dart's FakeConnectivityStatus doc comment: this app has no
// connectivity-plugin stream — its real offline signal is the pending
// count in OfflineQueueRepository, which this test exercises directly.
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:nuolipapp/core/storage/offline_queue_manager.dart';
import '../helpers/mocks.dart';
import '../helpers/test_harness.dart';

void main() {
  setUpAll(registerFoundationFallbackValues);
  tearDown(resetGetXState);

  test("offline state: OfflineQueueController reflects a fake pending queue count", () async {
    final repository = MockOfflineQueueRepository();
    createFakeOfflineState(repository, pendingCount: 3);

    final controller = OfflineQueueController(repository: repository);
    Get.put<OfflineQueueController>(controller);
    await controller.updateQueueCount();

    expect(controller.pendingCount.value, 3);
  });

  test("online state (empty queue): OfflineQueueController reports zero pending", () async {
    final repository = MockOfflineQueueRepository();
    createFakeOfflineState(repository, pendingCount: 0);

    final controller = OfflineQueueController(repository: repository);
    await controller.updateQueueCount();

    expect(controller.pendingCount.value, 0);
  });

  test("queued transactions carry the fake type/timestamp/data shape the real queue produces", () async {
    final repository = MockOfflineQueueRepository();
    createFakeOfflineState(repository, pendingCount: 2);

    final queue = await repository.getQueue();

    expect(queue, hasLength(2));
    expect(queue.first, containsPair('type', 'fake-queued-transaction'));
  });
}
