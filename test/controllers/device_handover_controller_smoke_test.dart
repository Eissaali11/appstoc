// PHASE B1.4 — Flutter Test Foundation smoke test: DeviceHandoverController.
// Proves the B1.4.3 DI seam actually works — this controller previously had
// no constructor at all (Get.find<T>() called inline at every use site).
import 'package:flutter_test/flutter_test.dart';
import 'package:nuolipapp/features/received_devices/presentation/controllers/device_handover_controller.dart';
import '../helpers/mocks.dart';
import '../helpers/fakes.dart';

void main() {
  setUpAll(registerFoundationFallbackValues);

  test("can be instantiated directly with fake dependencies (no Get.put/Get.find needed)", () {
    final controller = DeviceHandoverController(apiClient: MockApiClient(), authController: MockAuthController());

    expect(controller, isNotNull);
    expect(controller.isLoading, isFalse);
    expect(controller.selectedDevices, isEmpty);
  });

  test("toggling device selection works without touching any real dependency", () {
    final controller = DeviceHandoverController(apiClient: MockApiClient(), authController: MockAuthController());
    final fakeDevice = createFakeDevice();

    expect(controller.isDeviceSelected(fakeDevice), isFalse);
    controller.toggleDeviceSelection(fakeDevice);
    expect(controller.isDeviceSelected(fakeDevice), isTrue);
    controller.clearSelection();
    expect(controller.selectedDevices, isEmpty);
  });
}
