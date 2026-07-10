import '../../../../shared/models/item_type.dart';
import '../../data/models/received_device.dart';
import '../../data/models/withdrawn_device.dart';

abstract class DevicesRepository {
  Future<void> submitDevice(ReceivedDevice device);
  Future<List<ReceivedDevice>> getReceivedDevices();
  Future<int> getPendingReceivedDevicesCount();
  Future<List<ItemType>> getItemTypes();
  Future<void> deliverDevice(String barcode);
  
  // Withdrawn Devices
  Future<void> submitWithdrawnDevice(WithdrawnDevice device);
  Future<List<WithdrawnDevice>> getWithdrawnDevices();
}

