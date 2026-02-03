import '../../data/models/received_device.dart';

abstract class DevicesRepository {
  Future<void> submitDevice(ReceivedDevice device);
}
